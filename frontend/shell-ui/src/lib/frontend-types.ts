import type {
  AudioState,
  BatteryState,
  BluetoothState,
  BrightnessState,
  NetworkState,
  NotificationStatus,
  NotificationsResult,
  Settings,
  WorkspacesResult,
  WindowsResult,
} from '@oziro/protocol';

/**
 * Frontend-side mirrors of the method/event table in
 * `docs/contracts/frontend-core.md`. Domain types live in `@oziro/protocol`;
 * this module adds the surface/event names plus payload guards so components
 * can apply host events without trusting arbitrary payloads.
 */

/* ------------------------------------------------------------------ */
/* Surfaces                                                            */
/* ------------------------------------------------------------------ */

export type SurfaceId =
  | 'panel'
  | 'dock'
  | 'launcher'
  | 'control'
  | 'settings'
  | 'notifications'
  | 'overview';

export const SURFACE_IDS: readonly SurfaceId[] = [
  'panel',
  'dock',
  'launcher',
  'control',
  'settings',
  'notifications',
  'overview',
];

/**
 * Resolves the `?surface=` query parameter. A missing parameter means the
 * host fell back to the panel; an unrecognized value means "render nothing".
 */
export function parseSurfaceId(value: string | null | undefined): SurfaceId | null {
  if (value === null || value === undefined || value === '') {
    return 'panel';
  }

  return SURFACE_IDS.find((id) => id === value) ?? null;
}

export function readSurfaceParam(search: string): SurfaceId | null {
  const value = new URLSearchParams(search).get('surface');
  return parseSurfaceId(value);
}

/* ------------------------------------------------------------------ */
/* Theme                                                               */
/* ------------------------------------------------------------------ */

export type ThemeMode = 'dark' | 'light';

/* ------------------------------------------------------------------ */
/* Events                                                              */
/* ------------------------------------------------------------------ */

export interface EventMap {
  'compositor.workspaces': WorkspacesResult;
  'compositor.windows': WindowsResult;
  'system.audio': AudioState;
  'system.network': NetworkState;
  'system.bluetooth': BluetoothState;
  'system.battery': BatteryState;
  'settings.changed': Settings;
  'notifications.changed': NotificationsResult;
}

export type EventName = keyof EventMap;

export type EventPayload<E extends EventName> = EventMap[E];

export function isEventName(value: string): value is EventName {
  return Object.prototype.hasOwnProperty.call(
    {
      'compositor.workspaces': true,
      'compositor.windows': true,
      'system.audio': true,
      'system.network': true,
      'system.bluetooth': true,
      'system.battery': true,
      'settings.changed': true,
      'notifications.changed': true,
    },
    value,
  );
}

/* ------------------------------------------------------------------ */
/* Payload guards                                                      */
/* ------------------------------------------------------------------ */

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null;
}

function isBoolean(value: unknown): value is boolean {
  return typeof value === 'boolean';
}

function isStringOrNull(value: unknown): value is string | null {
  return typeof value === 'string' || value === null;
}

function isNumberOrNull(value: unknown): value is number | null {
  return typeof value === 'number' || value === null;
}

export function isWorkspacesResult(value: unknown): value is WorkspacesResult {
  if (!isRecord(value)) {
    return false;
  }

  return (
    isBoolean(value.supported) &&
    Array.isArray(value.workspaces) &&
    isStringOrNull(value.activeId) &&
    isStringOrNull(value.compositor) &&
    isStringOrNull(value.unavailableReason)
  );
}

export function isWindowsResult(value: unknown): value is WindowsResult {
  if (!isRecord(value)) {
    return false;
  }

  return (
    isBoolean(value.supported) &&
    Array.isArray(value.windows) &&
    isStringOrNull(value.activeId) &&
    isStringOrNull(value.compositor) &&
    isStringOrNull(value.unavailableReason)
  );
}

export function isAudioState(value: unknown): value is AudioState {
  if (!isRecord(value)) {
    return false;
  }

  return (
    isBoolean(value.available) &&
    isNumberOrNull(value.volume) &&
    (typeof value.muted === 'boolean' || value.muted === null)
  );
}

export function isNetworkState(value: unknown): value is NetworkState {
  if (!isRecord(value)) {
    return false;
  }

  return (
    isBoolean(value.available) &&
    isStringOrNull(value.activeName) &&
    isStringOrNull(value.unavailableReason) &&
    (typeof value.networkingEnabled === 'boolean' ||
      value.networkingEnabled === null) &&
    (typeof value.wifiEnabled === 'boolean' || value.wifiEnabled === null)
  );
}

export function isBatteryState(value: unknown): value is BatteryState {
  if (!isRecord(value)) {
    return false;
  }

  return (
    isBoolean(value.available) &&
    isNumberOrNull(value.percent) &&
    isStringOrNull(value.unavailableReason)
  );
}

export function isBluetoothState(value: unknown): value is BluetoothState {
  if (!isRecord(value)) {
    return false;
  }

  return (
    isBoolean(value.available) &&
    isNumberOrNull(value.connectedDevices) &&
    isStringOrNull(value.unavailableReason)
  );
}

export function isBrightnessState(value: unknown): value is BrightnessState {
  if (!isRecord(value)) {
    return false;
  }

  return isBoolean(value.available) && isNumberOrNull(value.percent);
}

export function isSettings(value: unknown): value is Settings {
  if (!isRecord(value)) {
    return false;
  }

  return (
    (value.theme === 'dark' || value.theme === 'light') &&
    isBoolean(value.liquidGlass) &&
    typeof value.blurIntensity === 'number' &&
    typeof value.panelHeight === 'number' &&
    typeof value.dockSize === 'number' &&
    Array.isArray(value.favorites)
  );
}

export function isNotificationStatus(value: unknown): value is NotificationStatus {
  if (!isRecord(value)) {
    return false;
  }

  return (
    (value.daemon === 'external' ||
      value.daemon === 'oziro' ||
      value.daemon === 'none') &&
    isBoolean(value.canReceive) &&
    isBoolean(value.canDismiss)
  );
}

export function isNotificationsResult(value: unknown): value is NotificationsResult {
  if (!isRecord(value)) {
    return false;
  }

  return (
    isNotificationStatus(value.status) && Array.isArray(value.notifications)
  );
}

/* ------------------------------------------------------------------ */
/* Errors                                                              */
/* ------------------------------------------------------------------ */

/** Extracts an honest human-readable reason from any thrown value. */
export function describeError(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }

  if (typeof error === 'string') {
    return error;
  }

  return 'Unknown failure while contacting the desktop host.';
}
