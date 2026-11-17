import { useMemo } from 'react';
import { readSurfaceParam, type SurfaceId } from '../lib/frontend-types';
import { useSettings } from '../hooks/useSettings';
import { useShellTheme } from '../hooks/useShellTheme';
import { TopPanel } from './panel/TopPanel';
import { Dock } from './dock/Dock';
import { Launcher } from './launcher/Launcher';
import { ControlCenter } from './control/ControlCenter';
import { SettingsView } from './settings/SettingsView';
import { NotificationCenter } from './notifications/NotificationCenter';
import { WindowOverview } from './overview/WindowOverview';

function useSurfaceId(): SurfaceId | null {
  return useMemo(() => readSurfaceParam(window.location.search), []);
}

/**
 * Root component every host surface loads. Resolves `?surface=` and applies
 * settings-driven theme attributes before switching to the surface view.
 * An unknown surface value renders nothing — the host never sends those.
 */
export function Surface() {
  const surfaceId = useSurfaceId();
  const { settings } = useSettings();
  useShellTheme(settings);

  switch (surfaceId) {
    case 'panel':
      return <TopPanel />;
    case 'dock':
      return <Dock />;
    case 'launcher':
      return <Launcher />;
    case 'control':
      return <ControlCenter />;
    case 'settings':
      return <SettingsView />;
    case 'notifications':
      return <NotificationCenter />;
    case 'overview':
      return <WindowOverview />;
    default:
      return null;
  }
}
