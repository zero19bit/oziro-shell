interface TopPanelProps {
  bridgeLabel: string;
}

export function TopPanel({ bridgeLabel }: TopPanelProps) {
  return (
    <header className="top-panel">
      <div className="brand-lockup" aria-label="Oziro Desktop">
        <span className="brand-mark" aria-hidden="true">
          o
        </span>
        <span className="brand-name">oziro</span>
        <span className="brand-divider" />
        <span className="brand-context">desktop foundation</span>
      </div>

      <div className="panel-center">
        <span className="workspace-indicator">
          <span className="workspace-dot" />
          Workspace preview
        </span>
      </div>

      <div className="panel-status">
        <span className="status-led" />
        <span>{bridgeLabel}</span>
      </div>
    </header>
  );
}
