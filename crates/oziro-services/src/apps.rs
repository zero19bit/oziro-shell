//! Application catalog: scan installed .desktop entries, search, and launch.
//!
//! Scanning uses the `freedesktop-desktop-entry` parser (pure Rust, no GUI
//! stack). Launching builds an argv from the Exec field codes and spawns it
//! directly with `std::process::Command` — no shell is ever involved, and no
//! frontend-provided string reaches a command line.

use crate::error::{OziroError, OziroResult};
use crate::icons::IconRegistry;
use freedesktop_desktop_entry::{DesktopEntry, Iter, get_languages_from_env};
use oziro_protocol::{AppEntry, AppsResult};
use std::path::PathBuf;
use std::sync::{Arc, RwLock};

#[derive(Debug, Clone)]
struct CatalogEntry {
    desktop_id: String,
    entry: AppEntry,
    /// Lowercase haystack used by the search scorer.
    terms: String,
    exec: Option<String>,
    work_dir: Option<String>,
    desktop_path: Option<String>,
}

impl CatalogEntry {
    /// Expands a .desktop Exec string into argv per the Desktop Entry spec:
    /// quote-aware tokenization and field-code substitution. No shell is
    /// involved; the result is a plain argv.
    fn parse_exec(&self, exec: &str) -> OziroResult<Vec<String>> {
        let tokens = tokenize_exec(exec)
            .map_err(|_| OziroError::launch_failed("Exec field could not be tokenized"))?;

        let mut argv = Vec::with_capacity(tokens.len());

        for token in tokens {
            let mut expanded = String::with_capacity(token.len());
            let mut chars = token.chars().peekable();

            while let Some(char) = chars.next() {
                if char != '%' {
                    expanded.push(char);
                    continue;
                }

                match chars.next() {
                    Some('%') => expanded.push('%'),
                    // File/URL field codes: we launch without files, so the
                    // position is simply omitted.
                    Some('f' | 'F' | 'u' | 'U') => {}
                    // Deprecated icon field: omitted.
                    Some('i') => {}
                    // Translated application name.
                    Some('c') => expanded.push_str(&self.entry.name),
                    // Desktop file path (if known).
                    Some('k') => {
                        if let Some(path) = &self.desktop_path {
                            expanded.push_str(path);
                        }
                    }
                    // Unknown field code: drop it rather than guessing.
                    Some(_) | None => {}
                }
            }

            if !expanded.is_empty() {
                argv.push(expanded);
            }
        }

        Ok(argv)
    }
}

/// Quote-aware tokenizer for Exec fields. Returns an error on unterminated
/// quotes rather than guessing intent.
fn tokenize_exec(exec: &str) -> Result<Vec<String>, ()> {
    let mut tokens = Vec::new();
    let mut current = String::new();
    let mut has_token = false;
    let mut chars = exec.chars().peekable();

    while let Some(char) = chars.next() {
        match char {
            ' ' | '\t' | '\n' => {
                if has_token {
                    tokens.push(std::mem::take(&mut current));
                    has_token = false;
                }
            }
            '"' => {
                has_token = true;

                loop {
                    match chars.next() {
                        Some('"') => break,
                        Some('\\') => match chars.next() {
                            Some(escaped @ ('"' | '\\' | '$' | '`')) => current.push(escaped),
                            Some(other) => {
                                current.push('\\');
                                current.push(other);
                            }
                            None => return Err(()),
                        },
                        Some(other) => current.push(other),
                        None => return Err(()),
                    }
                }
            }
            '\'' => {
                has_token = true;

                loop {
                    match chars.next() {
                        Some('\'') => break,
                        Some(other) => current.push(other),
                        None => return Err(()),
                    }
                }
            }
            '\\' => {
                has_token = true;

                match chars.next() {
                    Some(escaped) => current.push(escaped),
                    None => return Err(()),
                }
            }
            other => {
                has_token = true;
                current.push(other);
            }
        }
    }

    if has_token {
        tokens.push(current);
    }

    Ok(tokens)
}

#[derive(Debug)]
pub struct AppCatalog {
    icons: Arc<IconRegistry>,
    cache: RwLock<Vec<CatalogEntry>>,
}

impl AppCatalog {
    pub fn new(icons: Arc<IconRegistry>) -> Self {
        Self { icons, cache: RwLock::new(Vec::new()) }
    }

    /// Rescans installed applications. Safe to call again later.
    pub fn refresh(&self) -> OziroResult<usize> {
        let entries = scan_apps(&self.icons);
        let count = entries.len();

        *self.cache.write().expect("app catalog lock") = entries;
        Ok(count)
    }

    pub fn list(&self) -> AppsResult {
        let entries = self.cache.read().expect("app catalog lock");
        AppsResult { apps: entries.iter().map(|item| item.entry.clone()).collect() }
    }

    pub fn search(&self, query: &str) -> AppsResult {
        let query = query.trim().to_lowercase();

        if query.is_empty() {
            return self.list();
        }

        let entries = self.cache.read().expect("app catalog lock");

        let mut scored: Vec<(f64, &CatalogEntry)> = entries
            .iter()
            .filter_map(|item| {
                score_search(&query, &item.terms, &item.entry.name.to_lowercase())
                    .map(|score| (score, item))
            })
            .collect();

        scored.sort_by(|a, b| {
            b.0.partial_cmp(&a.0)
                .unwrap_or(std::cmp::Ordering::Equal)
                .then_with(|| a.1.entry.name.to_lowercase().cmp(&b.1.entry.name.to_lowercase()))
        });

        AppsResult { apps: scored.into_iter().map(|(_, item)| item.entry.clone()).collect() }
    }

    /// Returns entries for the given desktop ids (favorite resolution).
    pub fn resolve(&self, desktop_ids: &[String]) -> Vec<AppEntry> {
        let entries = self.cache.read().expect("app catalog lock");

        desktop_ids
            .iter()
            .filter_map(|wanted| {
                entries
                    .iter()
                    .find(|item| item.desktop_id.eq_ignore_ascii_case(wanted))
                    .map(|item| item.entry.clone())
            })
            .collect()
    }

    pub fn launch(&self, desktop_id: &str) -> OziroResult<()> {
        let id = desktop_id.trim();

        let valid = !id.is_empty()
            && id.len() <= 255
            && id.chars().all(|c| c.is_ascii_alphanumeric() || matches!(c, '.' | '-' | '_' | '+'));

        if !valid {
            return Err(OziroError::invalid_params("desktopId is not valid"));
        }

        let item = {
            let entries = self.cache.read().expect("app catalog lock");

            entries
                .iter()
                .find(|item| item.desktop_id.eq_ignore_ascii_case(id))
                .cloned()
                .ok_or_else(|| OziroError::launch_failed(format!("application not found: {id}")))?
        };

        let exec = item
            .exec
            .as_deref()
            .ok_or_else(|| OziroError::launch_failed("application has no Exec field"))?;

        let argv = item
            .parse_exec(exec)
            .map_err(|error| OziroError::launch_failed(format!("Exec field invalid: {error}")))?;

        if argv.is_empty() {
            return Err(OziroError::launch_failed("Exec field is empty"));
        }

        let mut command = std::process::Command::new(&argv[0]);
        command.args(&argv[1..]);

        if let Some(dir) = item.work_dir.as_deref() {
            let dir = PathBuf::from(dir);
            if dir.is_dir() {
                command.current_dir(dir);
            }
        }

        // Detach: the shell must not keep a child process handle.
        command
            .stdin(std::process::Stdio::null())
            .stdout(std::process::Stdio::null())
            .stderr(std::process::Stdio::null());

        command
            .spawn()
            .map_err(|error| OziroError::launch_failed(format!("could not start: {error}")))?;

        Ok(())
    }
}

/// Visible entries: not NoDisplay, not Hidden, not excluded by the current
/// desktop environment, and TryExec (when set) resolvable.
fn entry_should_show(entry: &DesktopEntry) -> bool {
    if entry.no_display() || entry.hidden() {
        return false;
    }

    let current_desktop = std::env::var("XDG_CURRENT_DESKTOP").unwrap_or_default().to_lowercase();

    if let Some(only_in) = entry.only_show_in() {
        let matches = only_in.iter().any(|env| env.to_lowercase() == current_desktop);
        if !matches {
            return false;
        }
    }

    if let Some(not_in) = entry.not_show_in() {
        let excluded = not_in.iter().any(|env| env.to_lowercase() == current_desktop);
        if excluded {
            return false;
        }
    }

    if let Some(try_exec) = entry.try_exec() {
        let executable = PathBuf::from(try_exec);
        if !executable.is_absolute() {
            // Relative names must resolve through PATH to count as present.
            match resolve_in_path(try_exec) {
                Some(_) => {}
                None => return false,
            }
        } else if !executable.is_file() {
            return false;
        }
    }

    true
}

fn resolve_in_path(name: &str) -> Option<PathBuf> {
    if name.is_empty() {
        return None;
    }

    let path_var = std::env::var_os("PATH")?;

    std::env::split_paths(&path_var).map(|dir| dir.join(name)).find(|candidate| candidate.is_file())
}

fn desktop_paths() -> Vec<PathBuf> {
    let mut paths = Vec::new();

    let mut data_dirs: Vec<PathBuf> = Vec::new();

    if let Ok(home) = std::env::var("XDG_DATA_HOME") {
        if !home.trim().is_empty() {
            data_dirs.push(PathBuf::from(home));
        }
    }

    if let Ok(dirs) = std::env::var("XDG_DATA_DIRS") {
        for dir in dirs.split(':') {
            if !dir.trim().is_empty() {
                data_dirs.push(PathBuf::from(dir));
            }
        }
    }

    // Spec fallbacks when the variables are unset.
    data_dirs.push(PathBuf::from("/usr/local/share"));
    data_dirs.push(PathBuf::from("/usr/share"));

    if let Ok(home) = std::env::var("HOME") {
        let home = PathBuf::from(home);
        data_dirs.push(home.join(".local/share"));
        data_dirs.push(home.join(".local/share/flatpak/exports/share"));
    }

    data_dirs.push(PathBuf::from("/var/lib/flatpak/exports/share"));

    for dir in data_dirs {
        let applications = dir.join("applications");
        if !paths.contains(&applications) {
            paths.push(applications);
        }
    }

    paths
}

fn scan_apps(icons: &IconRegistry) -> Vec<CatalogEntry> {
    let locales = get_languages_from_env();

    let mut entries: Vec<CatalogEntry> = Iter::new(desktop_paths().into_iter())
        .entries(Some(&locales))
        .filter(entry_should_show)
        .filter_map(|entry| {
            let name = entry.name(&locales)?.trim().to_owned();
            if name.is_empty() {
                return None;
            }

            let appid = entry.id().to_owned();
            if appid.is_empty() {
                return None;
            }

            let desktop_id = format!("{appid}.desktop");

            let generic_name = entry
                .generic_name(&locales)
                .map(|value| value.trim().to_owned())
                .filter(|value| !value.is_empty());

            let comment = entry
                .comment(&locales)
                .map(|value| value.trim().to_owned())
                .filter(|value| !value.is_empty());

            let categories = entry
                .categories()
                .unwrap_or_default()
                .into_iter()
                .map(ToOwned::to_owned)
                .collect::<Vec<_>>();

            let icon_token = entry.icon().and_then(|icon| icons.register_icon_name(icon));

            let app_entry = AppEntry {
                desktop_id: desktop_id.clone(),
                name,
                generic_name,
                comment,
                categories,
                icon_token,
            };

            let mut terms = String::with_capacity(96);
            terms.push_str(&app_entry.name.to_lowercase());
            if let Some(generic) = &app_entry.generic_name {
                terms.push(' ');
                terms.push_str(&generic.to_lowercase());
            }
            if let Some(comment_text) = &app_entry.comment {
                terms.push(' ');
                terms.push_str(&comment_text.to_lowercase());
            }
            if let Some(exec) = entry.exec() {
                terms.push(' ');
                terms.push_str(&exec.to_lowercase());
            }
            for category in &app_entry.categories {
                terms.push(' ');
                terms.push_str(&category.to_lowercase());
            }
            if let Some(keywords) = entry.keywords(&locales) {
                for keyword in keywords {
                    terms.push(' ');
                    terms.push_str(&keyword.to_lowercase());
                }
            }

            Some(CatalogEntry {
                desktop_id,
                entry: app_entry,
                terms,
                exec: entry.exec().map(ToOwned::to_owned),
                work_dir: entry.path().map(ToOwned::to_owned),
                desktop_path: Some(entry.path).map(|path| path.to_string_lossy().to_string()),
            })
        })
        .collect();

    entries.sort_by_key(|entry| entry.entry.name.to_lowercase());
    entries.dedup_by(|a, b| a.desktop_id == b.desktop_id);

    entries
}

/// Search scoring: high for name matches, lower for metadata matches.
/// Pure function so it is unit-testable without a real catalog.
pub fn score_search(query: &str, terms: &str, name_lower: &str) -> Option<f64> {
    if query.is_empty() {
        return None;
    }

    if name_lower == query {
        return Some(1.0);
    }

    if name_lower.starts_with(query) {
        return Some(0.9);
    }

    if name_lower.contains(query) {
        return Some(0.7);
    }

    if terms.contains(query) {
        return Some(0.4);
    }

    // Every query word must appear somewhere.
    let words: Vec<&str> = query.split_whitespace().collect();
    if words.len() > 1 && words.iter().all(|word| terms.contains(word)) {
        return Some(0.3);
    }

    None
}

#[cfg(test)]
mod tests {
    use super::*;
    use oziro_protocol::AppEntry;

    fn make_catalog(entries: Vec<(String, AppEntry, &str, Option<&str>)>) -> AppCatalog {
        let icons = Arc::new(IconRegistry::new());
        let catalog = AppCatalog::new(icons);

        let mut cached = Vec::new();

        for (desktop_id, entry, terms, exec) in entries {
            cached.push(CatalogEntry {
                desktop_id,
                entry,
                terms: terms.to_owned(),
                exec: exec.map(ToOwned::to_owned),
                work_dir: None,
                desktop_path: None,
            });
        }

        *catalog.cache.write().unwrap() = cached;
        catalog
    }

    fn entry(name: &str) -> AppEntry {
        AppEntry {
            desktop_id: format!("{name}.desktop"),
            name: name.to_owned(),
            generic_name: None,
            comment: None,
            categories: Vec::new(),
            icon_token: None,
        }
    }

    #[test]
    fn search_ranks_name_matches_above_metadata() {
        assert_eq!(score_search("fire", "firefox firefox web", "firefox"), Some(0.9));
        assert_eq!(score_search("firefox", "firefox firefox web", "firefox"), Some(1.0));
        assert_eq!(score_search("web", "firefox firefox web", "firefox"), Some(0.4));
        assert_eq!(score_search("zzz", "firefox firefox web", "firefox"), None);
    }

    #[test]
    fn multi_word_queries_can_match_terms() {
        assert_eq!(score_search("text editor", "editor text utility", "editor"), Some(0.3));
        assert_eq!(score_search("text video", "editor text utility", "editor"), None);
    }

    #[test]
    fn search_falls_back_to_list_on_empty_query() {
        let icons = Arc::new(IconRegistry::new());
        let catalog = AppCatalog::new(icons);

        assert_eq!(catalog.search("").apps.len(), 0);
        assert_eq!(catalog.list().apps.len(), 0);
    }

    #[test]
    fn launch_rejects_malformed_desktop_ids() {
        let icons = Arc::new(IconRegistry::new());
        let catalog = AppCatalog::new(icons);

        for bad in ["", " ", "/bin/sh", "no-dots", "x\0y", &"a".repeat(300)] {
            assert!(catalog.launch(bad).is_err(), "must reject: {bad}");
        }
    }

    #[test]
    fn resolve_returns_entries_in_requested_order() {
        let catalog = make_catalog(vec![
            ("alpha.desktop".to_owned(), entry("Alpha"), "alpha", None),
            ("beta.desktop".to_owned(), entry("Beta"), "beta", None),
        ]);

        let resolved = catalog.resolve(&["beta.desktop".to_owned(), "missing.desktop".to_owned()]);

        assert_eq!(resolved.len(), 1);
        assert_eq!(resolved[0].name, "Beta");
    }

    #[test]
    fn entry_serializes_like_frontend() {
        let app = entry("Demo");
        let json = serde_json::to_value(&app).unwrap();

        assert_eq!(json["desktopId"], "Demo.desktop");
        assert_eq!(json["iconToken"], serde_json::Value::Null);
    }

    #[test]
    fn desktop_path_includes_xdg_and_flatpak_dirs() {
        let paths = desktop_paths();

        assert!(paths.iter().any(|p| p.ends_with("applications")));
        assert!(paths.iter().any(|p| p.ends_with("flatpak/exports/share/applications")));
    }

    #[test]
    fn path_resolution_handles_missing_programs() {
        assert!(resolve_in_path("definitely-not-a-real-binary-oziro").is_none());
        assert!(resolve_in_path("ls").is_some());
    }

    /// Exercises the quote-aware Exec tokenizer and field-code expansion.
    #[test]
    fn exec_parsing_handles_quotes_and_field_codes() {
        let catalog = make_catalog(vec![(
            "demo.desktop".to_owned(),
            entry("Demo"),
            "demo",
            Some("demo %u --flag 'quoted arg' %i"),
        )]);

        let raw = "demo %u --flag 'quoted arg' %i";
        let argv = catalog.cache.read().unwrap().first().unwrap().parse_exec(raw).expect("exec");

        assert_eq!(argv, vec!["demo".to_owned(), "--flag".to_owned(), "quoted arg".to_owned()]);

        let percent =
            catalog.cache.read().unwrap().first().unwrap().parse_exec("demo 100%%").expect("exec");

        assert_eq!(percent, vec!["demo".to_owned(), "100%".to_owned()]);

        let unterminated = tokenize_exec("demo 'open");
        assert!(unterminated.is_err());
    }
}
