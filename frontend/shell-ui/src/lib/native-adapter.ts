import { request, subscribe } from './bridge';
import type { DesktopAdapter } from './desktop-adapter';
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
 * Adapter over the real host bridge. Every call goes through the allow-listed
 * request channel; there is no direct access to system facilities here.
 */
export function createNativeDesktopAdapter(): DesktopAdapter {
  const call = <T>(method: string, params?: unknown): Promise<T> =>
    request(method as never, params as never) as Promise<T>;

  const unit = async (method: string, params?: unknown): Promise<void> => {
    await call<unknown>(method, params);
  };

  return {
    mode: 'native',

    getRuntimeInfo: () => call<RuntimeInfo>('runtime.getInfo'),

    listApps: () => call<AppsResult>('apps.list'),
    searchApps: (query) => call<AppsResult>('apps.search', { query }),
    launchApp: (desktopId) => unit('apps.launch', { desktopId }),
    getFavorites: () => call<FavoritesResult>('apps.getFavorites'),
    setFavorites: (favorites) =>
      call<FavoritesResult>('apps.setFavorites', { favorites }),

    getWorkspaces: () => call<WorkspacesResult>('workspaces.list'),
    activateWorkspace: (id) => unit('workspaces.activate', { id }),
    getWindows: () => call<WindowsResult>('windows.list'),
    activateWindow: (id) => unit('windows.activate', { id }),

    getAudio: () => call<AudioState>('system.audio.get'),
    setVolume: (volume) => call<AudioState>('system.audio.setVolume', { volume }),
    setMuted: (muted) => call<AudioState>('system.audio.setMuted', { muted }),

    getNetwork: () => call<NetworkState>('system.network.get'),
    setWifiEnabled: (enabled) =>
      call<NetworkState>('system.network.setWifiEnabled', { enabled }),
    setNetworkingEnabled: (enabled) =>
      call<NetworkState>('system.network.setNetworkingEnabled', { enabled }),

    getBluetooth: () => call<BluetoothState>('system.bluetooth.get'),
    setBluetoothPowered: (powered) =>
      call<BluetoothState>('system.bluetooth.setPowered', { powered }),

    getBattery: () => call<BatteryState>('system.battery.get'),
    getBrightness: () => call<BrightnessState>('system.brightness.get'),
    setBrightness: (percent) =>
      call<BrightnessState>('system.brightness.set', { percent }),

    getPower: () => call<PowerState>('system.power.get'),

    getSettings: () => call<Settings>('settings.get'),
    updateSettings: (patch) => call<Settings>('settings.update', { patch }),

    getNotifications: () => call<NotificationsResult>('notifications.list'),
    getNotificationStatus: () =>
      call<NotificationStatus>('notifications.getStatus'),
    dismissNotification: (id) => unit('notifications.dismiss', { id }),

    openPopup: (surface: PopupSurface) => unit('ui.openPopup', { surface }),
    closePopup: (surface: PopupSurface) => unit('ui.closePopup', { surface }),

    resizeSurface: (width, height) =>
      unit('ui.resizeSurface', { width, height }),

    onEvent: subscribe,
  };
}
