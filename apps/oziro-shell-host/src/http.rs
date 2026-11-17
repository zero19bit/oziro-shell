//! Local HTTP server for the built frontend bundle and opaque icon tokens.
//!
//! The server binds to loopback only, serves files strictly below the build
//! directory, and resolves only tokens minted by the icon registry. Packaged
//! builds may set OZIRO_FRONTEND_DIR to the installed frontend asset directory.

use oziro_services::icons::IconRegistry;
use std::fs;
use std::path::{Component, Path, PathBuf};
use std::sync::Arc;
use std::thread;
use tiny_http::{Header, Method, Response, Server, StatusCode};

fn frontend_entrypoint_from(override_dir: Option<PathBuf>) -> PathBuf {
    let root = override_dir.unwrap_or_else(|| {
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../frontend/shell-ui/dist")
    });

    root.join("index.html")
}

pub fn frontend_entrypoint() -> PathBuf {
    let override_dir = std::env::var_os("OZIRO_FRONTEND_DIR").map(PathBuf::from);
    frontend_entrypoint_from(override_dir)
}

fn frontend_root() -> Result<PathBuf, String> {
    let root = frontend_entrypoint()
        .parent()
        .ok_or_else(|| "Frontend directory is invalid".to_owned())?
        .canonicalize()
        .map_err(|error| format!("Frontend build directory unavailable: {error}"))?;

    if !root.is_dir() {
        return Err("Frontend build path is not a directory".to_owned());
    }

    Ok(root)
}

fn resolve_frontend_file(root: &Path, request_url: &str) -> Option<PathBuf> {
    let request_path = request_url.split('?').next()?;

    if request_path.contains('%') || request_path.contains('\\') {
        return None;
    }

    let relative = request_path.strip_prefix('/')?;
    let relative = if relative.is_empty() { "index.html" } else { relative };
    let relative_path = Path::new(relative);

    if relative_path.components().any(|component| !matches!(component, Component::Normal(_))) {
        return None;
    }

    let canonical = root.join(relative_path).canonicalize().ok()?;

    if !canonical.starts_with(root) || !canonical.is_file() {
        return None;
    }

    Some(canonical)
}

/// Extracts an icon token from \`/oziro-icon/<token>\`. Tokens are minted by
/// Rust and restricted to an opaque, path-free alphabet.
fn icon_token_from_url(request_url: &str) -> Option<&str> {
    let path = request_url.split('?').next()?;
    let token = path.strip_prefix("/oziro-icon/")?;

    if token.is_empty()
        || token.len() > 32
        || !token.chars().all(|character| character.is_ascii_alphanumeric() || character == '-')
    {
        return None;
    }

    Some(token)
}

pub fn content_type(path: &Path) -> &'static str {
    match path.extension().and_then(|extension| extension.to_str()) {
        Some("html") => "text/html; charset=utf-8",
        Some("js" | "mjs") => "text/javascript; charset=utf-8",
        Some("css") => "text/css; charset=utf-8",
        Some("svg") => "image/svg+xml",
        Some("png") => "image/png",
        Some("jpg" | "jpeg") => "image/jpeg",
        Some("webp") => "image/webp",
        Some("woff2") => "font/woff2",
        Some("woff") => "font/woff",
        Some("ttf") => "font/ttf",
        Some("ico") => "image/x-icon",
        Some("json") => "application/json",
        _ => "application/octet-stream",
    }
}

fn with_security_headers<R: std::io::Read>(response: Response<R>) -> Response<R> {
    response
        .with_header(
            Header::from_bytes(&b"X-Content-Type-Options"[..], &b"nosniff"[..])
                .expect("valid security header"),
        )
        .with_header(
            Header::from_bytes(&b"Cache-Control"[..], &b"no-store"[..])
                .expect("valid cache header"),
        )
}

fn error_response(status: u16, message: &str) -> Response<std::io::Cursor<Vec<u8>>> {
    with_security_headers(
        Response::from_string(message.to_owned()).with_status_code(StatusCode(status)),
    )
}

fn file_response(path: &Path) -> Response<std::io::Cursor<Vec<u8>>> {
    match fs::read(path) {
        Ok(data) => {
            let mime = content_type(path);
            let header = Header::from_bytes(&b"Content-Type"[..], mime.as_bytes())
                .expect("valid content type");

            with_security_headers(Response::from_data(data).with_header(header))
        }
        Err(error) => {
            eprintln!("[OZIRO HTTP] Read error: {error}");
            error_response(404, "Not Found")
        }
    }
}

/// Starts the loopback server and returns the base URL, including the trailing
/// slash. \`?surface=\` is appended by the window builder.
pub fn start_frontend_server(icons: Arc<IconRegistry>) -> Result<String, String> {
    let root = frontend_root()?;

    let server = Server::http("127.0.0.1:0")
        .map_err(|error| format!("Cannot start local frontend server: {error}"))?;

    let address = server
        .server_addr()
        .to_ip()
        .ok_or_else(|| "Local server did not create an IP listener".to_owned())?;
    let port = address.port();

    thread::Builder::new()
        .name("oziro-frontend-http".to_owned())
        .spawn(move || {
            eprintln!("[OZIRO HTTP] Serving frontend on 127.0.0.1:{port}");

            for request in server.incoming_requests() {
                let method = request.method().clone();
                let url = request.url().to_owned();

                let response = if method != Method::Get && method != Method::Head {
                    error_response(405, "Method Not Allowed")
                } else if let Some(token) = icon_token_from_url(&url) {
                    match icons.resolve(token) {
                        Some(path) => file_response(&path),
                        None => error_response(404, "Not Found"),
                    }
                } else {
                    match resolve_frontend_file(&root, &url) {
                        Some(path) => file_response(&path),
                        None => error_response(404, "Not Found"),
                    }
                };

                if let Err(error) = request.respond(response) {
                    eprintln!("[OZIRO HTTP] Response error: {error}");
                }
            }

            eprintln!("[OZIRO HTTP] Server stopped");
        })
        .map_err(|error| format!("Cannot spawn frontend server: {error}"))?;

    Ok(format!("http://127.0.0.1:{port}/"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn frontend_entrypoint_targets_the_shell_ui_dist() {
        assert!(frontend_entrypoint_from(None).ends_with("frontend/shell-ui/dist/index.html"));
    }

    #[test]
    fn packaged_frontend_directory_can_be_overridden() {
        assert_eq!(
            frontend_entrypoint_from(Some(PathBuf::from("/usr/share/oziro/shell-ui"))),
            PathBuf::from("/usr/share/oziro/shell-ui/index.html")
        );
    }

    #[test]
    fn content_types_are_correct() {
        assert_eq!(content_type(Path::new("index.js")), "text/javascript; charset=utf-8");
        assert_eq!(content_type(Path::new("style.css")), "text/css; charset=utf-8");
        assert_eq!(content_type(Path::new("icon.svg")), "image/svg+xml");
    }

    #[test]
    fn frontend_path_rejects_traversal() {
        let root = PathBuf::from("/tmp/oziro-test-root");

        assert!(resolve_frontend_file(&root, "/../Cargo.toml").is_none());
        assert!(resolve_frontend_file(&root, "/%2e%2e/Cargo.toml").is_none());
        assert!(resolve_frontend_file(&root, "/..%2fCargo.toml").is_none());
    }

    #[test]
    fn icon_tokens_are_strictly_validated() {
        assert_eq!(icon_token_from_url("/oziro-icon/icn-000001"), Some("icn-000001"));
        assert_eq!(icon_token_from_url("/oziro-icon/icn-000001?v=1"), Some("icn-000001"));
        assert_eq!(icon_token_from_url("/oziro-icon/"), None);
        assert_eq!(icon_token_from_url("/oziro-icon/../../etc/passwd"), None);
        assert_eq!(icon_token_from_url("/oziro-icon/a%2fb"), None);
        assert_eq!(icon_token_from_url("/other/icn-000001"), None);
    }
}
