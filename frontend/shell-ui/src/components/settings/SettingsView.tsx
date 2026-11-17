import { useEffect, useMemo, useState } from 'react';
import type { ReactNode } from 'react';
import { useAdapter } from '../../lib/adapter-context';
import { useSettings } from '../../hooks/useSettings';
import { usePopupEscape } from '../../hooks/usePopupEscape';
import { describeError } from '../../lib/frontend-types';
import {
  Segmented,
  Slider,
  StatusLine,
  Toggle,
} from '../shared/Controls';
import { DismissGlyph } from '../shared/Glyphs';
import type { AppEntry } from '@oziro/protocol';

export function SettingsView() {
  const adapter = useAdapter();
  const { settings, error, update } = useSettings();
  usePopupEscape('settings');

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

  if (settings === null) {
    return (
      <div className="popup-root settings-root" data-testid="settings-root">
        <section className="oz-glass popup-card settings-card">
          <header className="popup-header">
            <h1 className="popup-title">Settings</h1>
          </header>
          <p className="oz-status-line">
            {error ?? 'Loading settings…'}
          </p>
          {appsError !== null ? (
            <p className="oz-error-note" role="alert">
              {appsError}
            </p>
          ) : null}
        </section>
      </div>
    );
  }

  return (
    <div className="popup-root settings-root" data-testid="settings-root">
      <section className="oz-glass popup-card settings-card">
        <header className="popup-header">
          <h1 className="popup-title">Settings</h1>
        </header>

        {error !== null ? (
          <p className="oz-error-note" role="alert">
            Change failed, reverted — {error}
          </p>
        ) : null}

        <div className="settings-scroll">
          <SettingsSection label="Appearance">
            <SettingsRow label="Theme">
              <Segmented
                ariaLabel="Theme"
                value={settings.theme}
                options={[
                  { value: 'dark', label: 'Dark' },
                  { value: 'light', label: 'Light' },
                ]}
                onChange={(theme) => void update({ theme })}
              />
            </SettingsRow>

            <SettingsRow label="Liquid glass">
              <Toggle
                checked={settings.liquidGlass}
                ariaLabel="Liquid glass"
                onChange={(liquidGlass) => void update({ liquidGlass })}
              />
            </SettingsRow>

            <SettingsRow label="Blur intensity" value={`${settings.blurIntensity}px`}>
              <Slider
                value={settings.blurIntensity}
                min={0}
                max={40}
                ariaLabel="Blur intensity"
                onChange={(blurIntensity) => void update({ blurIntensity })}
              />
            </SettingsRow>

            <SettingsRow label="Reduced motion">
              <Toggle
                checked={settings.reducedMotion}
                ariaLabel="Reduced motion"
                onChange={(reducedMotion) => void update({ reducedMotion })}
              />
            </SettingsRow>

            <SettingsRow label="Animations">
              <Toggle
                checked={settings.animations}
                ariaLabel="Animations"
                onChange={(animations) => void update({ animations })}
              />
            </SettingsRow>
          </SettingsSection>

          <SettingsSection label="Panel">
            <SettingsRow label="Height" value={`${settings.panelHeight}px`}>
              <Slider
                value={settings.panelHeight}
                min={44}
                max={64}
                ariaLabel="Panel height"
                onChange={(panelHeight) => void update({ panelHeight })}
              />
            </SettingsRow>

            <SettingsRow label="Alignment">
              <Segmented
                ariaLabel="Panel alignment"
                value={settings.panelAlignment}
                options={[
                  { value: 'left', label: 'Left' },
                  { value: 'center', label: 'Center' },
                  { value: 'right', label: 'Right' },
                ]}
                onChange={(panelAlignment) => void update({ panelAlignment })}
              />
            </SettingsRow>
          </SettingsSection>

          <SettingsSection label="Dock">
            <SettingsRow label="Icon size" value={`${settings.dockSize}px`}>
              <Slider
                value={settings.dockSize}
                min={44}
                max={88}
                ariaLabel="Dock size"
                onChange={(dockSize) => void update({ dockSize })}
              />
            </SettingsRow>

            <SettingsRow label="Position">
              <Segmented
                ariaLabel="Dock position"
                value={settings.dockPosition}
                options={[
                  { value: 'bottom', label: 'Bottom' },
                  { value: 'left', label: 'Left' },
                  { value: 'right', label: 'Right' },
                ]}
                onChange={(dockPosition) => void update({ dockPosition })}
              />
            </SettingsRow>
          </SettingsSection>

          <SettingsSection label="Favorites">
            <FavoritesEditor
              favorites={settings.favorites}
              apps={apps}
              onChange={(favorites) => void update({ favorites })}
            />
            {appsError !== null ? (
              <StatusLine>{appsError}</StatusLine>
            ) : null}
          </SettingsSection>
        </div>
      </section>
    </div>
  );
}

/* ------------------------------------------------------------------ */
/* Layout helpers                                                      */
/* ------------------------------------------------------------------ */

function SettingsSection({
  label,
  children,
}: {
  label: string;
  children: ReactNode;
}) {
  return (
    <section className="settings-section">
      <h2 className="oz-label">{label}</h2>
      <div className="settings-rows">{children}</div>
    </section>
  );
}

function SettingsRow({
  label,
  value,
  children,
}: {
  label: string;
  value?: string;
  children: ReactNode;
}) {
  return (
    <div className="settings-row">
      <div className="settings-row-copy">
        <span className="settings-row-label">{label}</span>
        {value !== undefined ? (
          <span className="settings-row-value tabular">{value}</span>
        ) : null}
      </div>
      <div className="settings-row-control">{children}</div>
    </div>
  );
}

/* ------------------------------------------------------------------ */
/* Favorites editor                                                    */
/* ------------------------------------------------------------------ */

function FavoritesEditor({
  favorites,
  apps,
  onChange,
}: {
  favorites: string[];
  apps: AppEntry[];
  onChange: (favorites: string[]) => void;
}) {
  const [query, setQuery] = useState('');

  const byDesktopId = useMemo(
    () => new Map(apps.map((app) => [app.desktopId, app])),
    [apps],
  );

  const candidates = useMemo(() => {
    const needle = query.trim().toLowerCase();
    return apps.filter(
      (app) =>
        !favorites.includes(app.desktopId) &&
        (needle === '' ||
          app.name.toLowerCase().includes(needle) ||
          app.desktopId.toLowerCase().includes(needle)),
    );
  }, [apps, favorites, query]);

  const remove = (desktopId: string) => {
    onChange(favorites.filter((id) => id !== desktopId));
  };

  const add = (desktopId: string) => {
    onChange([...favorites, desktopId]);
  };

  return (
    <div className="favorites-editor">
      <ul className="favorites-list">
        {favorites.map((desktopId) => {
          const app = byDesktopId.get(desktopId);
          return (
            <li className="favorites-item" key={desktopId}>
              <span className="favorites-name">
                {app?.name ?? desktopId}
              </span>
              <button
                type="button"
                className="oz-icon-button"
                aria-label={`Remove ${app?.name ?? desktopId} from favorites`}
                onClick={() => remove(desktopId)}
              >
                <DismissGlyph size={11} />
              </button>
            </li>
          );
        })}
        {favorites.length === 0 ? (
          <li className="favorites-empty">No pinned applications yet.</li>
        ) : null}
      </ul>

      <input
        className="launcher-input favorites-search"
        type="search"
        placeholder="Add application…"
        aria-label="Add application"
        value={query}
        onChange={(event) => setQuery(event.target.value)}
      />

      {query.trim() !== '' && candidates.length > 0 ? (
        <ul className="favorites-candidates">
          {candidates.slice(0, 8).map((app) => (
            <li key={app.desktopId}>
              <button
                type="button"
                className="favorites-candidate"
                onClick={() => {
                  add(app.desktopId);
                  setQuery('');
                }}
              >
                {app.name}
              </button>
            </li>
          ))}
        </ul>
      ) : null}
    </div>
  );
}
