use gtk::prelude::*;
use gtk::{Application, ApplicationWindow};
use std::path::PathBuf;
use webkit6::WebView;
use webkit6::prelude::*;

const APPLICATION_ID: &str = "io.oziro.Desktop.ShellHost";

const FALLBACK_HTML: &str = r#"
<!doctype html>
<html>
<head><meta charset="utf-8"><title>Oziro Error</title></head>
<body style="background:#101714;color:#edf5ef;font-family:sans-serif;padding:40px">
<h1>Oziro frontend bundle not found</h1>
<p>Run npm run build from the repository root.</p>
</body>
</html>
"#;

fn frontend_entrypoint() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../frontend/shell-ui/dist/index.html")
}

fn frontend_uri() -> Result<String, String> {
    let path = frontend_entrypoint();

    let canonical = path
        .canonicalize()
        .map_err(|e| format!("Frontend not found at {}: {e}", path.display()))?;

    Ok(webkit6::gio::File::for_path(canonical).uri().to_string())
}

fn build_window(application: &Application) {
    let web_view = WebView::new();

    // Diagnostics only. No browser security restrictions are disabled.
    let settings = webkit6::Settings::default();
    settings.set_enable_write_console_messages_to_stdout(true);
    settings.set_enable_developer_extras(true);
    web_view.set_settings(&settings);

    web_view.connect_load_changed(|view, event| {
        let uri = view.uri().map(|value| value.to_string()).unwrap_or_else(|| "<none>".to_owned());

        eprintln!("[WEBKIT LOAD] event={event:?} uri={uri}");
    });

    web_view.connect_load_failed(|_, event, uri, error| {
        eprintln!("[WEBKIT LOAD FAILED] event={event:?} uri={uri} error={error}");
        false
    });

    web_view.connect_web_process_terminated(|_, reason| {
        eprintln!("[WEBKIT PROCESS TERMINATED] reason={reason:?}");
    });

    web_view.set_hexpand(true);
    web_view.set_vexpand(true);

    let window = ApplicationWindow::builder()
        .application(application)
        .title("Oziro Desktop")
        .default_width(1280)
        .default_height(800)
        .build();

    window.set_child(Some(&web_view));

    match frontend_uri() {
        Ok(uri) => {
            eprintln!("[OZIRO] Loading frontend: {uri}");
            web_view.load_uri(&uri);
        }
        Err(error) => {
            eprintln!("[OZIRO ERROR] {error}");
            web_view.load_html(FALLBACK_HTML, None);
        }
    }

    window.present();
}

fn main() {
    let application = Application::builder().application_id(APPLICATION_ID).build();

    application.connect_activate(build_window);
    let _exit_code = application.run();
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn frontend_entrypoint_targets_the_shell_ui_dist() {
        assert!(frontend_entrypoint().ends_with("frontend/shell-ui/dist/index.html"));
    }

    #[test]
    fn application_id_uses_the_oziro_namespace() {
        assert!(APPLICATION_ID.starts_with("io.oziro."));
    }
}
