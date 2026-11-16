use oziro_protocol::{IntegrationState, PROTOCOL_VERSION, RuntimeInfo};
use std::env;
use std::process::ExitCode;

fn print_help() {
    println!("Oziro Core {}", env!("CARGO_PKG_VERSION"));
    println!();
    println!("Usage:");
    println!("  oziro-core info       Show build and integration status");
    println!("  oziro-core doctor     Show basic runtime diagnostics");
    println!("  oziro-core --version  Show version");
    println!("  oziro-core --help     Show this help");
}

fn runtime_info() -> RuntimeInfo {
    RuntimeInfo {
        protocol_version: PROTOCOL_VERSION,
        app_name: "Oziro Core".to_owned(),
        app_version: env!("CARGO_PKG_VERSION").to_owned(),
        integration: IntegrationState::NotConnected {
            reason: "native host and Linux adapters are not implemented yet".to_owned(),
        },
    }
}

fn run(command: Option<&str>) -> ExitCode {
    match command.unwrap_or("--help") {
        "info" => {
            let info = runtime_info();
            println!("{} {}", info.app_name, info.app_version);
            println!("Protocol version: {}", info.protocol_version);
            match info.integration {
                IntegrationState::NotConnected { reason } => {
                    println!("System integration: NOT CONNECTED");
                    println!("Reason: {reason}");
                }
                IntegrationState::Connected { adapter } => {
                    println!("System integration: connected ({adapter})");
                }
            }
            ExitCode::SUCCESS
        }
        "doctor" => {
            println!("Oziro Core diagnostics");
            println!("Build target OS: {}", env::consts::OS);
            println!("Build target architecture: {}", env::consts::ARCH);
            println!("Native host: not initialized");
            println!("Compositor adapter: not initialized");
            println!("Hardware adapters: not initialized");
            ExitCode::SUCCESS
        }
        "--version" | "-V" => {
            println!("oziro-core {}", env!("CARGO_PKG_VERSION"));
            ExitCode::SUCCESS
        }
        "--help" | "-h" | "help" => {
            print_help();
            ExitCode::SUCCESS
        }
        other => {
            eprintln!("Unknown command: {other}");
            print_help();
            ExitCode::from(2)
        }
    }
}

fn main() -> ExitCode {
    let mut args = env::args().skip(1);
    let command = args.next();
    run(command.as_deref())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn info_command_succeeds() {
        assert_eq!(run(Some("info")), ExitCode::SUCCESS);
    }

    #[test]
    fn doctor_command_succeeds() {
        assert_eq!(run(Some("doctor")), ExitCode::SUCCESS);
    }

    #[test]
    fn unknown_command_fails() {
        assert_eq!(run(Some("not-a-command")), ExitCode::from(2));
    }
}
