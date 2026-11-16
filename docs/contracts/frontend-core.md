# Frontend ↔ Rust Core Contract

**Protocol version:** `1`

## Boundary

React communicates only through the `DesktopAdapter` interface. Components must not access D-Bus, Hyprland sockets, filesystem configuration, or shell commands directly.

The browser preview uses `PreviewDesktopAdapter`. The native host will inject a narrow `window.oziroBridge` API after the host is implemented.

## Runtime info

```ts
interface RuntimeInfo {
  protocolVersion: 1;
  appName: string;
  appVersion: string;
  integration:
    | { state: "not-connected"; reason: string }
    | { state: "connected"; adapter: string };
}
```

## Request envelope

```json
{
  "protocolVersion": 1,
  "requestId": "opaque-request-id",
  "method": "runtime.getInfo"
}
```

## Success response

```json
{
  "protocolVersion": 1,
  "requestId": "opaque-request-id",
  "ok": true,
  "result": {
    "protocolVersion": 1,
    "appName": "Oziro Core",
    "appVersion": "0.1.0",
    "integration": {
      "state": "not-connected",
      "reason": "adapter not initialized"
    }
  }
}
```

## Error response

```json
{
  "protocolVersion": 1,
  "requestId": "opaque-request-id",
  "ok": false,
  "error": {
    "code": "SERVICE_UNAVAILABLE",
    "message": "The requested service is unavailable.",
    "retryable": true
  }
}
```

## Rules

- Reject unsupported protocol versions.
- Validate method names and payloads in Rust.
- Use allow-listed methods; never expose arbitrary command execution.
- Return structured errors.
- Do not send secrets or unnecessary hardware identifiers to the UI.
- The transport (WebKit message handler, local socket, or another mechanism) remains undecided until the native host proof-of-concept.
