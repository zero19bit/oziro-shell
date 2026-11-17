import { useEffect, useLayoutEffect, useRef, useState } from 'react';
import type { CSSProperties } from 'react';
import { useAdapter } from '../../lib/adapter-context';
import { useDesktopState } from '../../hooks/useDesktopState';
import { useSettings } from '../../hooks/useSettings';
import { matchesAppId } from '../../lib/appid';
import { describeError, isWindowsResult } from '../../lib/frontend-types';
import { AppIcon } from '../shared/AppIcon';
import { GridGlyph } from '../shared/Glyphs';
import type { AppEntry, WindowInfo } from '@oziro/protocol';

const RESIZE_DEBOUNCE_MS = 150;

export interface DockEntry {
  key: string;
  kind: 'favorite' | 'running';
  label: string;
  iconToken: string | null;
  desktopId: string | null;
  windows: WindowInfo[];
}

export function Dock() {
  const adapter = useAdapter();
  const { settings } = useSettings();

  const windows = useDesktopState({
    fetcher: () => adapter.getWindows(),
    eventName: 'compositor.windows',
    applyEvent: isWindowsResult,
  });

  const [apps, setApps] = useState<AppEntry[]>([]);
  const [appsError, setAppsError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    adapter
      .listApps()
      .then((result) => {
        if (!cancelled) {
          setApps(result.apps);
          setAppsError(null);
        }
      })
      .catch((cause: unknown) => {
        if (!cancelled) {
          setAppsError(describeError(cause));
        }
      });

    return () => {
      cancelled = true;
    };
  }, [adapter]);

  const dockPosition = settings?.dockPosition ?? 'bottom';
  const dockSize = settings?.dockSize ?? 56;
  const favorites = settings?.favorites ?? [];
  const entries = buildEntries(favorites, apps, windows.data?.windows ?? []);
  const iconSize = Math.round(dockSize * 0.56);

  return (
    <div
      className={`dock-root is-${dockPosition}`}
      data-testid="dock-root"
      style={{ '--oz-dock-size': `${dockSize}px` } as CSSProperties}
    >
      <DockContent
        entries={entries}
        appsError={appsError}
        vertical={dockPosition !== 'bottom'}
        iconSize={iconSize}
      />
    </div>
  );
}

/* ------------------------------------------------------------------ */
/* Content with self-measurement + resizeSurface                       */
/* ------------------------------------------------------------------ */

interface DockContentProps {
  entries: DockEntry[];
  appsError: string | null;
  vertical: boolean;
  iconSize: number;
}

function DockContent({ entries, appsError, vertical, iconSize }: DockContentProps) {
  const adapter = useAdapter();
  const contentRef = useRef<HTMLDivElement>(null);

  useLayoutEffect(() => {
    let timer = 0;

    const scheduleResize = () => {
      const element = contentRef.current;
      if (element === null) {
        return;
      }

      window.clearTimeout(timer);
      timer = window.setTimeout(() => {
        void adapter.resizeSurface(element.offsetWidth, element.offsetHeight);
      }, RESIZE_DEBOUNCE_MS);
    };

    scheduleResize();

    if (typeof ResizeObserver !== 'undefined' && contentRef.current !== null) {
      const observer = new ResizeObserver(scheduleResize);
      observer.observe(contentRef.current);
      return () => {
        window.clearTimeout(timer);
        observer.disconnect();
      };
    }

    return () => {
      window.clearTimeout(timer);
    };
  }, [adapter, vertical, entries.length]);

  const activateOrLaunch = (entry: DockEntry) => {
    const running = entry.windows[0];

    if (running !== undefined) {
      void adapter.activateWindow(running.id).catch(() => {
        /* Window activation failures keep the dock state honest. */
      });
      return;
    }

    if (entry.desktopId !== null) {
      void adapter.launchApp(entry.desktopId).catch(() => {
        /* Launch failures surface through the host; no fake feedback here. */
      });
    }
  };

  return (
    <div
      ref={contentRef}
      className={`oz-glass dock-card${vertical ? ' is-vertical' : ''}`}
      role="toolbar"
      aria-label="Application dock"
    >
      <div className="dock-items">
        <button
          type="button"
          className="dock-item dock-launcher"
          style={{ width: iconSize + 20, height: iconSize + 20 }}
          aria-label="Open launcher"
          onClick={() => {
            void adapter.openPopup('launcher');
          }}
        >
          <GridGlyph size={Math.round(iconSize * 0.5)} />
          <DockTooltip label="Launcher" vertical={vertical} />
        </button>

        {entries.map((entry, index) => (
          <span className="dock-slot" key={entry.key}>
            {entry.kind === 'running' && entries[index - 1]?.kind === 'favorite' ? (
              <span className="dock-divider" aria-hidden="true" />
            ) : null}
            <button
              type="button"
              className="dock-item"
              style={{ width: iconSize + 20, height: iconSize + 20 }}
              onClick={() => activateOrLaunch(entry)}
            >
              <AppIcon
                iconToken={entry.iconToken}
                label={entry.label}
                size={iconSize}
              />
              {entry.windows.length > 0 ? (
                <span className="dock-dot" aria-hidden="true" />
              ) : null}
              <DockTooltip label={entry.label} vertical={vertical} />
            </button>
          </span>
        ))}
      </div>

      {appsError !== null ? (
        <span className="dock-error" role="status">
          {appsError}
        </span>
      ) : null}
    </div>
  );
}

function DockTooltip({ label, vertical }: { label: string; vertical: boolean }) {
  return (
    <span className={`dock-tooltip${vertical ? ' is-vertical' : ''}`}>{label}</span>
  );
}

/* ------------------------------------------------------------------ */
/* Entry model                                                         */
/* ------------------------------------------------------------------ */

/**
 * Builds the dock model: favorites resolved against the app database first
 * (each absorbing its running windows), then a divider, then remaining
 * running windows grouped per app id.
 */
function buildEntries(
  favorites: string[],
  apps: AppEntry[],
  windows: WindowInfo[],
): DockEntry[] {
  const byDesktopId = new Map(apps.map((app) => [app.desktopId, app]));
  const consumed = new Set<string>();

  const entries: DockEntry[] = [];

  for (const desktopId of favorites) {
    const app = byDesktopId.get(desktopId);
    if (!app) {
      continue;
    }

    const owned = windows.filter(
      (window) => !consumed.has(window.id) && matchesAppId(app.desktopId, window.appId),
    );
    for (const window of owned) {
      consumed.add(window.id);
    }

    entries.push({
      key: `favorite:${app.desktopId}`,
      kind: 'favorite',
      label: app.name,
      iconToken: app.iconToken,
      desktopId: app.desktopId,
      windows: owned,
    });
  }

  const runningByApp = new Map<string, WindowInfo[]>();
  for (const window of windows) {
    if (window.appId === null || consumed.has(window.id)) {
      continue;
    }
    const list = runningByApp.get(window.appId) ?? [];
    list.push(window);
    runningByApp.set(window.appId, list);
  }

  for (const [appId, appWindows] of runningByApp) {
    appWindows.sort((a, b) =>
      (a.active ? 0 : 1) - (b.active ? 0 : 1) || a.title.localeCompare(b.title),
    );

    const app = apps.find((candidate) => matchesAppId(candidate.desktopId, appId));

    entries.push({
      key: `running:${appId}`,
      kind: 'running',
      label: app?.name ?? appWindows[0]?.title ?? appId,
      iconToken: app?.iconToken ?? appWindows[0]?.iconToken ?? null,
      desktopId: app?.desktopId ?? null,
      windows: appWindows,
    });
  }

  return entries;
}
