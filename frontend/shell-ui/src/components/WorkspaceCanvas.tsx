import type { RuntimeInfo } from '@oziro/protocol';

interface WorkspaceCanvasProps {
  runtimeInfo: RuntimeInfo | null;
  runtimeError: string | null;
}

export function WorkspaceCanvas({
  runtimeInfo,
  runtimeError,
}: WorkspaceCanvasProps) {
  const connected = runtimeInfo?.integration.state === 'connected';

  return (
    <main className="workspace">
      <div className="workspace-kicker">
        <span className="kicker-line" />
        THE BEGINNING OF SOMETHING DIFFERENT
      </div>

      <section className="hero">
        <p className="hero-eyebrow">OZIRO / 0.1.0</p>
        <h1>
          Your desktop.
          <br />
          <span>On your terms.</span>
        </h1>
        <p className="hero-copy">
          A new Linux desktop environment, built from the ground up.
          Thoughtful by design. Open to change.
        </p>
      </section>

      <section className="runtime-card" aria-live="polite">
        <div className="runtime-icon" aria-hidden="true">
          <span />
        </div>
        <div className="runtime-copy">
          <p className="runtime-label">NATIVE RUNTIME</p>
          <h2>
            {runtimeError
              ? 'Bridge unavailable'
              : connected
                ? 'Native bridge connected'
                : 'Preview environment'}
          </h2>
          <p>
            {runtimeError ??
              (runtimeInfo === null
                ? 'Checking the local bridge…'
                : runtimeInfo.integration.state === 'not-connected'
                  ? runtimeInfo.integration.reason
                  : `Connected through ${runtimeInfo.integration.adapter}.`)}
          </p>
        </div>
        <span className={`runtime-state ${connected ? 'is-connected' : ''}`}>
          {runtimeError ? 'ERROR' : connected ? 'CONNECTED' : 'PREVIEW'}
        </span>
      </section>

      <div className="workspace-footer">
        <span>FOUNDATION BUILD</span>
        <span>NO SYSTEM SETTINGS HAVE BEEN CHANGED</span>
      </div>
    </main>
  );
}
