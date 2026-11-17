import { useAdapter } from '../../lib/adapter-context';
import { useClock } from '../../hooks/useClock';
import { useDesktopState } from '../../hooks/useDesktopState';
import { useSettings } from '../../hooks/useSettings';
import {
  isAudioState,
  isBatteryState,
  isNetworkState,
  isNotificationsResult,
  isWorkspacesResult,
} from '../../lib/frontend-types';
import {
  BatteryGlyph,
  BellGlyph,
  EthernetGlyph,
  GridGlyph,
  SlidersGlyph,
  SpeakerGlyph,
  SpeakerMutedGlyph,
  VpnGlyph,
  WifiGlyph,
  WindowsGlyph,
} from '../shared/Glyphs';

export function TopPanel() {
  const adapter = useAdapter();
  const { settings } = useSettings();
  const now = useClock();

  const workspaces = useDesktopState({
    fetcher: () => adapter.getWorkspaces(),
    eventName: 'compositor.workspaces',
    applyEvent: isWorkspacesResult,
  });

  const audio = useDesktopState({
    fetcher: () => adapter.getAudio(),
    eventName: 'system.audio',
    applyEvent: isAudioState,
  });

  const network = useDesktopState({
    fetcher: () => adapter.getNetwork(),
    eventName: 'system.network',
    applyEvent: isNetworkState,
  });

  const battery = useDesktopState({
    fetcher: () => adapter.getBattery(),
    eventName: 'system.battery',
    applyEvent: isBatteryState,
  });

  const notifications = useDesktopState({
    fetcher: () => adapter.getNotifications(),
    eventName: 'notifications.changed',
    applyEvent: isNotificationsResult,
  });

  const time = new Intl.DateTimeFormat(undefined, {
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  }).format(now);

  const date = new Intl.DateTimeFormat(undefined, {
    weekday: 'short',
    day: '2-digit',
    month: 'short',
  }).format(now);

  const showWorkspaces =
    workspaces.data?.supported === true && workspaces.data.workspaces.length > 0;
  const unreadCount = notifications.data?.notifications.length ?? 0;

  const openControl = () => {
    void adapter.openPopup('control');
  };

  const activate = (id: string) => {
    void adapter.activateWorkspace(id).catch(() => {
      /* Activation failures cannot be surfaced in a pill; state stays honest. */
    });
  };

  return (
    <div className="panel-root" data-panel-align={settings?.panelAlignment ?? 'center'}>
      <div className="ambient-glow" aria-hidden="true" />
      <header className="top-panel" data-testid="top-panel">
      <div className="panel-left">
        <span className="brand-mark" aria-hidden="true">
          o
        </span>
        <span className="brand-name">oziro</span>
        <span className="brand-divider" />
        <button
          type="button"
          className="panel-icon-button"
          aria-label="Open launcher"
          onClick={() => {
            void adapter.openPopup('launcher');
          }}
        >
          <GridGlyph size={15} />
        </button>
      </div>

      <div className="panel-center">
        {showWorkspaces
          ? workspaces.data?.workspaces.map((workspace) => (
              <button
                type="button"
                key={workspace.id}
                className={`ws-pill${workspace.active ? ' is-active' : ''}`}
                aria-pressed={workspace.active}
                onClick={() => activate(workspace.id)}
              >
                {workspace.name}
              </button>
            ))
          : null}
      </div>

      <div className="panel-right">
        {audio.data?.available === true ? (
          <button
            type="button"
            className="panel-indicator"
            aria-label="Audio"
            onClick={openControl}
          >
            {audio.data.muted === true ? (
              <SpeakerMutedGlyph size={14} />
            ) : (
              <SpeakerGlyph size={14} />
            )}
            <span className="panel-indicator-value">
              {audio.data.muted === true
                ? 'Muted'
                : `${Math.round(audio.data.volume ?? 0)}%`}
            </span>
          </button>
        ) : null}

        {network.data?.available === true ? (
          <button
            type="button"
            className="panel-indicator"
            aria-label="Network"
            onClick={openControl}
          >
            <NetworkGlyph state={network.data} />
            <span className="panel-indicator-value">
              {describeNetwork(network.data)}
            </span>
          </button>
        ) : null}

        {battery.data?.available === true ? (
          <button
            type="button"
            className="panel-indicator"
            aria-label="Battery"
            data-warning={
              (battery.data.warningLevel === 'low' ||
                battery.data.warningLevel === 'critical') || undefined
            }
            onClick={openControl}
          >
            <BatteryGlyph size={14} />
            <span className="panel-indicator-value">
              {battery.data.state === 'charging' ? '⚡' : ''}
              {battery.data.percent === null
                ? '—'
                : `${Math.round(battery.data.percent)}%`}
            </span>
          </button>
        ) : null}

        <span className="panel-divider" />

        <button
          type="button"
          className="panel-icon-button"
          aria-label="Notifications"
          onClick={() => {
            void adapter.openPopup('notifications');
          }}
        >
          <BellGlyph size={15} />
          {unreadCount > 0 ? (
            <span className="panel-badge">{unreadCount}</span>
          ) : null}
        </button>

        <button
          type="button"
          className="panel-icon-button"
          aria-label="Open window overview"
          onClick={() => {
            void adapter.openPopup('overview');
          }}
        >
          <WindowsGlyph size={15} />
        </button>

        <button
          type="button"
          className="panel-icon-button"
          aria-label="Open control center"
          onClick={openControl}
        >
          <SlidersGlyph size={15} />
        </button>

        <span className="panel-divider" />

        <div className="clock-copy">
          <time className="clock-time" dateTime={now.toISOString()}>
            {time}
          </time>
          <span className="clock-date">{date}</span>
        </div>
      </div>
      </header>
    </div>
  );
}

/* ------------------------------------------------------------------ */
/* Indicator helpers                                                   */
/* ------------------------------------------------------------------ */

interface NetworkLike {
  connectivity: 'none' | 'portal' | 'limited' | 'full' | 'unknown';
  activeType: 'ethernet' | 'wifi' | 'vpn' | null;
}

function NetworkGlyph({ state }: { state: NetworkLike }) {
  if (state.activeType === 'ethernet') {
    return <EthernetGlyph size={14} />;
  }
  if (state.activeType === 'vpn') {
    return <VpnGlyph size={14} />;
  }
  return <WifiGlyph size={14} />;
}

function describeNetwork(state: NetworkLike): string {
  switch (state.connectivity) {
    case 'none':
      return 'Offline';
    case 'portal':
      return 'Portal';
    case 'limited':
      return 'Limited';
    case 'full':
      return state.activeType === 'ethernet'
        ? 'Wired'
        : state.activeType === 'vpn'
          ? 'VPN'
          : 'Online';
    default:
      return '…';
  }
}
