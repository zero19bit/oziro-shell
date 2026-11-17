export const PROTOCOL_VERSION = 1 as const;

export type IntegrationState =
  | {
      state: 'not-connected';
      reason: string;
    }
  | {
      state: 'connected';
      adapter: string;
    };

export interface RuntimeInfo {
  protocolVersion: typeof PROTOCOL_VERSION;
  appName: string;
  appVersion: string;
  integration: IntegrationState;
}

export interface RequestEnvelope {
  protocolVersion: typeof PROTOCOL_VERSION;
  requestId: string;
  method: string;
  params?: unknown;
}

export interface SuccessEnvelope<T> {
  protocolVersion: typeof PROTOCOL_VERSION;
  requestId: string;
  ok: true;
  result: T;
}

export interface ErrorEnvelope {
  protocolVersion: typeof PROTOCOL_VERSION;
  requestId: string;
  ok: false;
  error: {
    code: string;
    message: string;
    retryable: boolean;
  };
}

export type ResponseEnvelope<T> = SuccessEnvelope<T> | ErrorEnvelope;

export interface EventEnvelope {
  protocolVersion: typeof PROTOCOL_VERSION;
  event: string;
  payload: unknown;
}

/* ------------------------------------------------------------------ */
/* Domain types                                                        */
/* ------------------------------------------------------------------ */

export interface Workspace {
  id: string;
  name: string;
  index: number;
  active: boolean;
}

export interface WindowInfo {
  id: string;
  title: string;
  appId: string | null;
  workspaceId: string | null;
  active: boolean;
  iconToken: string | null;
}

export interface WorkspacesResult {
  compositor: string | null;
  supported: boolean;
  unavailableReason: string | null;
  workspaces: Workspace[];
  activeId: string | null;
}

export interface WindowsResult {
  compositor: string | null;
  supported: boolean;
  unavailableReason: string | null;
  windows: WindowInfo[];
  activeId: string | null;
}

/**
 * Opaque token that can be resolved through the host HTTP endpoint
 * `/oziro-icon/<token>`. The token never encodes a filesystem path.
 */
export type IconToken = string | null;

export interface AppEntry {
  desktopId: string;
  name: string;
  genericName: string | null;
  comment: string | null;
  categories: string[];
  iconToken: IconToken;
}

export interface AppsResult {
  apps: AppEntry[];
}

export interface FavoritesResult {
  favorites: string[];
}

export interface AudioState {
  available: boolean;
  unavailableReason: string | null;
  volume: number | null;
  muted: boolean | null;
  sinkName: string | null;
  sinkDescription: string | null;
}

export type NetworkType = 'ethernet' | 'wifi' | 'vpn' | null;

export interface NetworkState {
  available: boolean;
  unavailableReason: string | null;
  networkingEnabled: boolean | null;
  wifiEnabled: boolean | null;
  connectivity: 'none' | 'portal' | 'limited' | 'full' | 'unknown';
  activeType: NetworkType;
  activeName: string | null;
}

export interface BluetoothState {
  available: boolean;
  unavailableReason: string | null;
  powered: boolean | null;
  connectedDevices: number | null;
  adapterName: string | null;
}

export type BatteryStateKind =
  | 'charging'
  | 'discharging'
  | 'fully-charged'
  | 'unknown';

export interface BatteryState {
  available: boolean;
  unavailableReason: string | null;
  percent: number | null;
  state: BatteryStateKind;
  timeToEmptySeconds: number | null;
  timeToFullSeconds: number | null;
  warningLevel: 'none' | 'low' | 'critical' | 'unknown';
}

export interface BrightnessState {
  available: boolean;
  unavailableReason: string | null;
  percent: number | null;
  device: string | null;
  supportsSet: boolean;
}

export interface PowerState {
  uptimeSeconds: number;
  sessionDesktop: string | null;
  battery: BatteryState | null;
}

export interface Settings {
  theme: 'dark' | 'light';
  liquidGlass: boolean;
  blurIntensity: number;
  panelHeight: number;
  panelAlignment: 'left' | 'center' | 'right';
  dockSize: number;
  dockPosition: 'bottom' | 'left' | 'right';
  reducedMotion: boolean;
  animations: boolean;
  favorites: string[];
}

export type NotificationDaemonMode =
  | 'external'
  | 'oziro'
  | 'none';

export interface NotificationStatus {
  daemon: NotificationDaemonMode;
  daemonOwner: string | null;
  canReceive: boolean;
  canDismiss: boolean;
}

export interface StoredNotification {
  id: string;
  appName: string;
  appIcon: string | null;
  summary: string;
  body: string;
  timestampMs: number;
  urgency: 'low' | 'normal' | 'critical';
}

export interface NotificationsResult {
  status: NotificationStatus;
  notifications: StoredNotification[];
}

export type PopupSurface =
  | 'launcher'
  | 'control'
  | 'notifications'
  | 'overview'
  | 'settings';

/* ------------------------------------------------------------------ */
/* Method map (method name -> params -> result)                        */
/* ------------------------------------------------------------------ */

export interface MethodMap {
  'runtime.getInfo': void;
  'apps.list': void;
  'apps.search': { query: string };
  'apps.launch': { desktopId: string };
  'apps.getFavorites': void;
  'apps.setFavorites': { favorites: string[] };
  'workspaces.list': void;
  'workspaces.activate': { id: string };
  'windows.list': void;
  'windows.activate': { id: string };
  'system.audio.get': void;
  'system.audio.setVolume': { volume: number };
  'system.audio.setMuted': { muted: boolean };
  'system.network.get': void;
  'system.network.setWifiEnabled': { enabled: boolean };
  'system.network.setNetworkingEnabled': { enabled: boolean };
  'system.bluetooth.get': void;
  'system.bluetooth.setPowered': { powered: boolean };
  'system.battery.get': void;
  'system.brightness.get': void;
  'system.brightness.set': { percent: number };
  'system.power.get': void;
  'settings.get': void;
  'settings.update': { patch: Partial<Settings> };
  'notifications.list': void;
  'notifications.getStatus': void;
  'notifications.dismiss': { id: string };
  'ui.openPopup': { surface: PopupSurface };
  'ui.closePopup': { surface: PopupSurface };
  'ui.resizeSurface': { width: number; height: number };
}

export type RequestMethod = keyof MethodMap;

export type MethodParams<M extends RequestMethod> = MethodMap[M] extends void
  ? undefined
  : MethodMap[M];

export interface OziroErrorShape {
  code: string;
  message: string;
  retryable: boolean;
}
