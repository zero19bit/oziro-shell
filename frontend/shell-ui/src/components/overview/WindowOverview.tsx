import { useState } from 'react';
import { useAdapter } from '../../lib/adapter-context';
import { useDesktopState } from '../../hooks/useDesktopState';
import { usePopupEscape } from '../../hooks/usePopupEscape';
import { isWindowsResult, isWorkspacesResult } from '../../lib/frontend-types';
import { AppIcon } from '../shared/AppIcon';
import type { WindowInfo } from '@oziro/protocol';

export function WindowOverview() {
  const adapter = useAdapter();
  usePopupEscape('overview');

  const [filter, setFilter] = useState<string | null>(null);

  const workspaces = useDesktopState({
    fetcher: () => adapter.getWorkspaces(),
    eventName: 'compositor.workspaces',
    applyEvent: isWorkspacesResult,
  });
  const windows = useDesktopState({
    fetcher: () => adapter.getWindows(),
    eventName: 'compositor.windows',
    applyEvent: isWindowsResult,
  });

  const shown = filterWindows(windows.data?.windows ?? [], filter);

  const open = (id: string) => {
    adapter
      .activateWindow(id)
      .then(() => adapter.closePopup('overview'))
      .catch((cause: unknown) => {
        console.warn('[oziro] activateWindow failed:', cause);
      });
  };

  return (
    <div className="popup-root overview-root" data-testid="overview-root">
      <section className="oz-glass popup-card overview-card">
        <header className="popup-header">
          <h1 className="popup-title">Windows</h1>
        </header>

        {windows.error !== null ? (
          <p className="oz-error-note" role="alert">
            {windows.error}
          </p>
        ) : null}

        {windows.data?.supported === false ? (
          <p className="oz-status-line overview-empty" data-testid="overview-unavailable">
            Window overview is unavailable —{' '}
            {windows.data.unavailableReason ?? 'the compositor does not provide windows.'}
          </p>
        ) : (
          <>
            {workspaces.data?.supported === true &&
            workspaces.data.workspaces.length > 0 ? (
              <div className="overview-chips" role="tablist" aria-label="Workspaces">
                <button
                  type="button"
                  role="tab"
                  aria-selected={filter === null}
                  className={`overview-chip${filter === null ? ' is-active' : ''}`}
                  onClick={() => setFilter(null)}
                >
                  All
                </button>
                {workspaces.data.workspaces.map((workspace) => (
                  <button
                    type="button"
                    key={workspace.id}
                    role="tab"
                    aria-selected={filter === workspace.id}
                    className={`overview-chip${filter === workspace.id ? ' is-active' : ''}`}
                    onClick={() => setFilter(workspace.id)}
                  >
                    {workspace.name}
                  </button>
                ))}
              </div>
            ) : null}

            {shown.length === 0 ? (
              <p className="oz-status-line overview-empty">
                {windows.data === null
                  ? 'Waiting for window state…'
                  : 'No windows on this workspace.'}
              </p>
            ) : (
              <div className="overview-grid">
                {shown.map((window) => (
                  <WindowCard key={window.id} window={window} onOpen={() => open(window.id)} />
                ))}
              </div>
            )}
          </>
        )}
      </section>
    </div>
  );
}

function WindowCard({
  window: item,
  onOpen,
}: {
  window: WindowInfo;
  onOpen: () => void;
}) {
  return (
    <button
      type="button"
      className={`overview-window${item.active ? ' is-active' : ''}`}
      onClick={onOpen}
    >
      <AppIcon iconToken={item.iconToken} label={item.title} size={28} />
      <span className="overview-window-copy">
        <span className="overview-window-title">{item.title}</span>
        <span className="overview-window-app oz-label">
          {item.appId ?? 'unknown app'}
        </span>
      </span>
    </button>
  );
}

function filterWindows(windows: WindowInfo[], filter: string | null): WindowInfo[] {
  if (filter === null) {
    return windows;
  }
  return windows.filter((window) => window.workspaceId === filter);
}
