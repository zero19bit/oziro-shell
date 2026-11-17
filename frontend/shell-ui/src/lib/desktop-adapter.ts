import { isNativeBridgeAvailable } from './bridge';
import { createNativeDesktopAdapter } from './native-adapter';
import { createPreviewDesktopAdapter } from './preview-adapter';
import type {
  AppsResult,
  AudioState,
  BatteryState,
  BluetoothState,
  BrightnessState,
  FavoritesResult,
  NetworkState,
  NotificationStatus,
  NotificationsResult,
  PopupSurface,
  PowerState,
  RuntimeInfo,
  Settings,
  WorkspacesResult,
  WindowsResult,
} from '@oziro/protocol';

/**
 * The single boundary every surface talks through. Components must not access
 * D-Bus, compositor sockets, the filesystem, or shell commands directly.
 *
 * Every domain reports its own availability (`available` / `supported` flags
 * with reason strings); the adapter never fabricates live state.
 */
export type AdapterMode = 'native' | 'preview' | 'mock';

export interface DesktopAdapter {
  /** Which implementation is backing this adapter instance. */
  readonly mode: AdapterMode;

  getRuntimeInfo(): Promise<RuntimeInfo>;

  listApps(): Promise<AppsResult>;
  searchApps(query: string): Promise<AppsResult>;
  launchApp(desktopId: string): Promise<void>;
  getFavorites(): Promise<FavoritesResult>;
  setFavorites(favorites: string[]): Promise<FavoritesResult>;

  getWorkspaces(): Promise<WorkspacesResult>;
  activateWorkspace(id: string): Promise<void>;
  getWindows(): Promise<WindowsResult>;
  activateWindow(id: string): Promise<void>;

  getAudio(): Promise<AudioState>;
  setVolume(volume: number): Promise<AudioState>;
  setMuted(muted: boolean): Promise<AudioState>;

  getNetwork(): Promise<NetworkState>;
  setWifiEnabled(enabled: boolean): Promise<NetworkState>;
  setNetworkingEnabled(enabled: boolean): Promise<NetworkState>;

  getBluetooth(): Promise<BluetoothState>;
  setBluetoothPowered(powered: boolean): Promise<BluetoothState>;

  getBattery(): Promise<BatteryState>;
  getBrightness(): Promise<BrightnessState>;
  setBrightness(percent: number): Promise<BrightnessState>;

  getPower(): Promise<PowerState>;

  getSettings(): Promise<Settings>;
  updateSettings(patch: Partial<Settings>): Promise<Settings>;

  getNotifications(): Promise<NotificationsResult>;
  getNotificationStatus(): Promise<NotificationStatus>;
  dismissNotification(id: string): Promise<void>;

  openPopup(surface: PopupSurface): Promise<void>;
  closePopup(surface: PopupSurface): Promise<void>;
  resizeSurface(width: number, height: number): Promise<void>;

  /**
   * Subscribe to a host event (see the event table in
   * `docs/contracts/frontend-core.md`). Returns an unsubscribe function.
   */
  onEvent(event: string, handler: (payload: unknown) => void): () => void;
}

export type AdapterFactory = () => DesktopAdapter;

/**
 * Selects the adapter once at startup: the native host bridge when present,
 * otherwise the explicit preview adapter.
 */
export function createDesktopAdapter(): DesktopAdapter {
  const factory: AdapterFactory = isNativeBridgeAvailable()
    ? createNativeDesktopAdapter
    : createPreviewDesktopAdapter;

  return factory();
}
