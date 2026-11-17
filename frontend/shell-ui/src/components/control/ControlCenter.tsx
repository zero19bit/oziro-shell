import { useEffect, useRef, useState } from 'react';
import type { ReactNode } from 'react';
import { useAdapter } from '../../lib/adapter-context';
import { useDesktopState } from '../../hooks/useDesktopState';
import { useOptimisticState } from '../../hooks/useOptimisticState';
import { usePopupEscape } from '../../hooks/usePopupEscape';
import { clampInt, secondsToDuration } from '../../lib/format';
import {
  describeError,
  isAudioState,
  isBatteryState,
  isBluetoothState,
  isNetworkState,
} from '../../lib/frontend-types';
import { Slider, StatusLine, Toggle, UnavailableNote } from '../shared/Controls';
import {
  BatteryGlyph,
  BluetoothGlyph,
  EthernetGlyph,
  GearGlyph,
  PowerGlyph,
  SpeakerGlyph,
  SpeakerMutedGlyph,
  SunGlyph,
  VpnGlyph,
  WifiGlyph,
} from '../shared/Glyphs';
import type {
  AudioState,
  BatteryState,
  BluetoothState,
  BrightnessState,
  NetworkState,
  PowerState,
} from '@oziro/protocol';

const SLIDER_COMMIT_MS = 120;

/**
 * Optimistic tile action: apply locally, persist through the adapter, sync
 * to the returned state; on failure revert to the server state and expose
 * the reason.
 */
function useOptimisticAction<S>(
  serverState: S | null,
  setView: (next: S | null) => void,
): [string | null, (next: S, commit: (value: S) => Promise<S>) => void] {
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setError(null);
  }, [serverState]);

  const run = (next: S, commit: (value: S) => Promise<S>) => {
    setView(next);
    setError(null);
    commit(next)
      .then((result) => setView(result))
      .catch((cause: unknown) => {
        setView(serverState);
        setError(describeError(cause));
      });
  };

  return [error, run];
}

export function ControlCenter() {
  const adapter = useAdapter();
  usePopupEscape('control');

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
  const bluetooth = useDesktopState({
    fetcher: () => adapter.getBluetooth(),
    eventName: 'system.bluetooth',
    applyEvent: isBluetoothState,
  });
  const battery = useDesktopState({
    fetcher: () => adapter.getBattery(),
    eventName: 'system.battery',
    applyEvent: isBatteryState,
  });
  const brightness = useDesktopState({
    fetcher: () => adapter.getBrightness(),
    eventName: null,
  });
  const power = useDesktopState({
    fetcher: () => adapter.getPower(),
    eventName: null,
  });

  const openSettings = () => {
    void adapter
      .closePopup('control')
      .catch(() => undefined)
      .then(() => adapter.openPopup('settings'));
  };

  return (
    <div className="popup-root control-root" data-testid="control-root">
      <section className="oz-glass popup-card control-card">
        <header className="popup-header">
          <h1 className="popup-title">Control Center</h1>
          <button
            type="button"
            className="oz-icon-button"
            aria-label="Open settings"
            onClick={openSettings}
          >
            <GearGlyph size={15} />
          </button>
        </header>

        <div className="control-tiles">
          <AudioTile state={audio.data} error={audio.error} />
          <NetworkTile state={network.data} error={network.error} />
          <BluetoothTile state={bluetooth.data} error={bluetooth.error} />
          <BatteryTile state={battery.data} error={battery.error} />
          <BrightnessTile state={brightness.data} error={brightness.error} />
          <PowerTile state={power.data} error={power.error} />
        </div>
      </section>
    </div>
  );
}

/* ------------------------------------------------------------------ */
/* Tile frame                                                          */
/* ------------------------------------------------------------------ */

function Tile({
  title,
  glyph,
  children,
}: {
  title: string;
  glyph: ReactNode;
  children: ReactNode;
}) {
  return (
    <section className="control-tile">
      <header className="control-tile-header">
        <span className="control-tile-glyph">{glyph}</span>
        <h2 className="oz-label">{title}</h2>
      </header>
      {children}
    </section>
  );
}

function ActionError({ reason }: { reason: string | null }) {
  if (reason === null) {
    return null;
  }
  return (
    <p className="oz-error-note" role="alert">
      {reason}
    </p>
  );
}

/* ------------------------------------------------------------------ */
/* Audio                                                               */
/* ------------------------------------------------------------------ */

function AudioTile({
  state,
  error,
}: {
  state: AudioState | null;
  error: string | null;
}) {
  const adapter = useAdapter();
  const [view, setView] = useOptimisticState(state);
  const [actionError, run] = useOptimisticAction(state, setView);
  const commitTimer = useRef(0);

  useEffect(() => () => window.clearTimeout(commitTimer.current), []);

  if (error !== null) {
    return (
      <Tile title="Audio" glyph={<SpeakerGlyph />}>
        <UnavailableNote>{error}</UnavailableNote>
      </Tile>
    );
  }

  if (view === null || view.available !== true) {
    return (
      <Tile title="Audio" glyph={<SpeakerGlyph />}>
        <UnavailableNote>
          {view?.unavailableReason ?? 'Volume state is not available yet.'}
        </UnavailableNote>
      </Tile>
    );
  }

  const volume = clampInt(view.volume ?? 0, 0, 100);
  const muted = view.muted === true;

  const applyVolume = (next: number) => {
    const clamped = clampInt(next, 0, 100);
    setView({ ...view, volume: clamped });
    window.clearTimeout(commitTimer.current);
    commitTimer.current = window.setTimeout(() => {
      run({ ...view, volume: clamped }, (value) =>
        adapter.setVolume(clampInt(value.volume ?? 0, 0, 100)),
      );
    }, SLIDER_COMMIT_MS);
  };

  const applyMuted = (next: boolean) => {
    run({ ...view, muted: next }, (value) => adapter.setMuted(value.muted === true));
  };

  return (
    <Tile title="Audio" glyph={muted ? <SpeakerMutedGlyph /> : <SpeakerGlyph />}>
      <div className="tile-row">
        <Slider
          value={volume}
          min={0}
          max={100}
          ariaLabel="Volume"
          onChange={applyVolume}
        />
        <span className="tile-value tabular">{volume}%</span>
      </div>
      <div className="tile-row">
        <Toggle checked={muted} onChange={applyMuted} ariaLabel="Mute audio" />
        <span className="tile-copy">{muted ? 'Muted' : 'Sound on'}</span>
      </div>
      {view.sinkDescription !== null ? (
        <StatusLine>{view.sinkDescription}</StatusLine>
      ) : null}
      <ActionError reason={actionError} />
    </Tile>
  );
}

/* ------------------------------------------------------------------ */
/* Network                                                             */
/* ------------------------------------------------------------------ */

function NetworkTile({
  state,
  error,
}: {
  state: NetworkState | null;
  error: string | null;
}) {
  const adapter = useAdapter();
  const [view, setView] = useOptimisticState(state);
  const [actionError, run] = useOptimisticAction(state, setView);

  if (error !== null) {
    return (
      <Tile title="Network" glyph={<WifiGlyph />}>
        <UnavailableNote>{error}</UnavailableNote>
      </Tile>
    );
  }

  if (view === null || view.available !== true) {
    return (
      <Tile title="Network" glyph={<WifiGlyph />}>
        <UnavailableNote>
          {view?.unavailableReason ?? 'Network state is not available yet.'}
        </UnavailableNote>
      </Tile>
    );
  }

  const connectivityLabels: Record<NetworkState['connectivity'], string> = {
    none: 'Offline',
    portal: 'Sign-in required',
    limited: 'Limited connectivity',
    full: 'Connected',
    unknown: 'Connectivity unknown',
  };

  const typeGlyph =
    view.activeType === 'ethernet' ? (
      <EthernetGlyph />
    ) : view.activeType === 'vpn' ? (
      <VpnGlyph />
    ) : (
      <WifiGlyph />
    );

  return (
    <Tile title="Network" glyph={typeGlyph}>
      <StatusLine>
        {connectivityLabels[view.connectivity]}
        {view.activeName !== null ? ` · ${view.activeName}` : ''}
      </StatusLine>
      <div className="tile-row">
        <Toggle
          checked={view.networkingEnabled === true}
          disabled={view.networkingEnabled === null}
          ariaLabel="Networking"
          onChange={(next) =>
            run(
              { ...view, networkingEnabled: next },
              (value) => adapter.setNetworkingEnabled(value.networkingEnabled === true),
            )
          }
        />
        <span className="tile-copy">Networking</span>
      </div>
      <div className="tile-row">
        <Toggle
          checked={view.wifiEnabled === true}
          disabled={view.wifiEnabled === null}
          ariaLabel="Wi-Fi"
          onChange={(next) =>
            run(
              { ...view, wifiEnabled: next },
              (value) => adapter.setWifiEnabled(value.wifiEnabled === true),
            )
          }
        />
        <span className="tile-copy">Wi-Fi</span>
      </div>
      <ActionError reason={actionError} />
    </Tile>
  );
}

/* ------------------------------------------------------------------ */
/* Bluetooth                                                           */
/* ------------------------------------------------------------------ */

function BluetoothTile({
  state,
  error,
}: {
  state: BluetoothState | null;
  error: string | null;
}) {
  const adapter = useAdapter();
  const [view, setView] = useOptimisticState(state);
  const [actionError, run] = useOptimisticAction(state, setView);

  if (error !== null) {
    return (
      <Tile title="Bluetooth" glyph={<BluetoothGlyph />}>
        <UnavailableNote>{error}</UnavailableNote>
      </Tile>
    );
  }

  if (view === null || view.available !== true) {
    return (
      <Tile title="Bluetooth" glyph={<BluetoothGlyph />}>
        <UnavailableNote>
          {view?.unavailableReason ?? 'Bluetooth state is not available yet.'}
        </UnavailableNote>
      </Tile>
    );
  }

  const devices = view.connectedDevices;

  return (
    <Tile title="Bluetooth" glyph={<BluetoothGlyph />}>
      <div className="tile-row">
        <Toggle
          checked={view.powered === true}
          disabled={view.powered === null}
          ariaLabel="Bluetooth power"
          onChange={(next) =>
            run(
              { ...view, powered: next },
              (value) => adapter.setBluetoothPowered(value.powered === true),
            )
          }
        />
        <span className="tile-copy">{view.powered === true ? 'On' : 'Off'}</span>
      </div>
      <StatusLine>
        {devices === null
          ? 'Device count unknown'
          : `${devices} device${devices === 1 ? '' : 's'} connected`}
      </StatusLine>
      <ActionError reason={actionError} />
    </Tile>
  );
}

/* ------------------------------------------------------------------ */
/* Battery                                                             */
/* ------------------------------------------------------------------ */

const BATTERY_STATE_LABELS: Record<BatteryState['state'], string> = {
  charging: 'Charging',
  discharging: 'Discharging',
  'fully-charged': 'Fully charged',
  unknown: 'State unknown',
};

function BatteryTile({
  state,
  error,
}: {
  state: BatteryState | null;
  error: string | null;
}) {
  if (error !== null) {
    return (
      <Tile title="Battery" glyph={<BatteryGlyph />}>
        <UnavailableNote>{error}</UnavailableNote>
      </Tile>
    );
  }

  if (state === null || state.available !== true) {
    return (
      <Tile title="Battery" glyph={<BatteryGlyph />}>
        <UnavailableNote>
          {state?.unavailableReason ?? 'Battery state is not available yet.'}
        </UnavailableNote>
      </Tile>
    );
  }

  const percent = state.percent === null ? null : clampInt(state.percent, 0, 100);
  const tone =
    state.warningLevel === 'critical'
      ? ' is-critical'
      : state.warningLevel === 'low'
        ? ' is-low'
        : '';

  return (
    <Tile title="Battery" glyph={<BatteryGlyph />}>
      <div className="tile-row">
        <span
          className={`battery-bar${tone}`}
          role="progressbar"
          aria-label="Battery charge"
          aria-valuenow={percent ?? undefined}
          aria-valuemin={0}
          aria-valuemax={100}
        >
          <span style={{ width: `${percent ?? 0}%` }} />
        </span>
        <span className="tile-value tabular">
          {percent === null ? '—' : `${percent}%`}
        </span>
      </div>
      <StatusLine>
        {BATTERY_STATE_LABELS[state.state]}
        {state.state === 'charging' && state.timeToFullSeconds !== null
          ? ` · ${secondsToDuration(state.timeToFullSeconds)} to full`
          : ''}
        {state.state === 'discharging' && state.timeToEmptySeconds !== null
          ? ` · ${secondsToDuration(state.timeToEmptySeconds)} left`
          : ''}
      </StatusLine>
    </Tile>
  );
}

/* ------------------------------------------------------------------ */
/* Brightness                                                          */
/* ------------------------------------------------------------------ */

function BrightnessTile({
  state,
  error,
}: {
  state: BrightnessState | null;
  error: string | null;
}) {
  const adapter = useAdapter();
  const [view, setView] = useOptimisticState(state);
  const [actionError, run] = useOptimisticAction(state, setView);
  const commitTimer = useRef(0);

  useEffect(() => () => window.clearTimeout(commitTimer.current), []);

  if (error !== null) {
    return (
      <Tile title="Brightness" glyph={<SunGlyph />}>
        <UnavailableNote>{error}</UnavailableNote>
      </Tile>
    );
  }

  if (view === null || view.available !== true) {
    return (
      <Tile title="Brightness" glyph={<SunGlyph />}>
        <UnavailableNote>
          {view?.unavailableReason ?? 'Brightness is not available yet.'}
        </UnavailableNote>
      </Tile>
    );
  }

  const percent = clampInt(view.percent ?? 0, 0, 100);

  if (!view.supportsSet) {
    return (
      <Tile title="Brightness" glyph={<SunGlyph />}>
        <StatusLine>
          {percent}%{view.device !== null ? ` · ${view.device}` : ''}
        </StatusLine>
        <UnavailableNote>
          This brightness device reports read-only values.
        </UnavailableNote>
      </Tile>
    );
  }

  const apply = (next: number) => {
    const clamped = clampInt(next, 0, 100);
    setView({ ...view, percent: clamped });
    window.clearTimeout(commitTimer.current);
    commitTimer.current = window.setTimeout(() => {
      run({ ...view, percent: clamped }, (value) =>
        adapter.setBrightness(clampInt(value.percent ?? 0, 0, 100)),
      );
    }, SLIDER_COMMIT_MS);
  };

  return (
    <Tile title="Brightness" glyph={<SunGlyph />}>
      <div className="tile-row">
        <Slider
          value={percent}
          min={0}
          max={100}
          ariaLabel="Screen brightness"
          onChange={apply}
        />
        <span className="tile-value tabular">{percent}%</span>
      </div>
      <ActionError reason={actionError} />
    </Tile>
  );
}

/* ------------------------------------------------------------------ */
/* Power (info only — no destructive actions)                          */
/* ------------------------------------------------------------------ */

function PowerTile({
  state,
  error,
}: {
  state: PowerState | null;
  error: string | null;
}) {
  return (
    <Tile title="Power" glyph={<PowerGlyph />}>
      {error !== null ? (
        <UnavailableNote>{error}</UnavailableNote>
      ) : state === null ? (
        <UnavailableNote>Session state is not available yet.</UnavailableNote>
      ) : (
        <>
          <StatusLine>Up {secondsToDuration(state.uptimeSeconds)}</StatusLine>
          <StatusLine>
            {state.sessionDesktop ?? 'Session desktop unknown'}
          </StatusLine>
        </>
      )}
    </Tile>
  );
}
