import {
  PROTOCOL_VERSION,
  type AppsResult,
  type AudioState,
  type BatteryState,
  type BluetoothState,
  type BrightnessState,
  type FavoritesResult,
  type NetworkState,
  type NotificationStatus,
  type NotificationsResult,
  type PowerState,
  type RuntimeInfo,
  type Settings,
  type WorkspacesResult,
  type WindowsResult,
} from '@oziro/protocol';
import type { DesktopAdapter } from './desktop-adapter';

export const PREVIEW_APP_VERSION = '0.2.0';

const PREVIEW_REASON =
  'Browser preview mode: no native host connection. No live desktop state is being reported.';

const unavailableState = () => ({
  available: false,
  unavailableReason: PREVIEW_REASON,
});

const audio: AudioState = {
  ...unavailableState(),
  volume: null,
  muted: null,
  sinkName: null,
  sinkDescription: null,
};

const network: NetworkState = {
  ...unavailableState(),
  networkingEnabled: null,
  wifiEnabled: null,
  connectivity: 'unknown',
  activeType: null,
  activeName: null,
};

const bluetooth: BluetoothState = {
  ...unavailableState(),
  powered: null,
  connectedDevices: null,
  adapterName: null,
};

const battery: BatteryState = {
  ...unavailableState(),
  percent: null,
  state: 'unknown',
  timeToEmptySeconds: null,
  timeToFullSeconds: null,
  warningLevel: 'unknown',
};

const brightness: BrightnessState = {
  ...unavailableState(),
  percent: null,
  device: null,
  supportsSet: false,
};

const noCompositor = {
  compositor: null,
  supported: false,
  unavailableReason: PREVIEW_REASON,
  workspaces: [],
  activeId: null,
} satisfies WorkspacesResult;

const noWindows = {
  compositor: null,
  supported: false,
  unavailableReason: PREVIEW_REASON,
  windows: [],
  activeId: null,
} satisfies WindowsResult;

const emptyApps: AppsResult = { apps: [] };
const emptyFavorites: FavoritesResult = { favorites: [] };
const notificationStatus: NotificationStatus = {
  daemon: 'none',
  daemonOwner: null,
  canReceive: false,
  canDismiss: false,
};

const emptyNotifications: NotificationsResult = {
  status: notificationStatus,
  notifications: [],
};

export const previewSettings: Settings = {
  theme: 'dark',
  liquidGlass: true,
  blurIntensity: 24,
  panelHeight: 54,
  panelAlignment: 'center',
  dockSize: 56,
  dockPosition: 'bottom',
  reducedMotion: false,
  animations: true,
  favorites: [],
};

/**
 * Explicitly non-production adapter. It does not inspect or simulate host
 * state: system domains report themselves as unavailable with a reason.
 */
export function createPreviewDesktopAdapter(): DesktopAdapter {
  return {
    mode: 'preview',

    async getRuntimeInfo(): Promise<RuntimeInfo> {
      return {
        protocolVersion: PROTOCOL_VERSION,
        appName: 'Oziro Desktop',
        appVersion: PREVIEW_APP_VERSION,
        integration: {
          state: 'not-connected',
          reason: PREVIEW_REASON,
        },
      };
    },

    listApps: async () => emptyApps,
    searchApps: async () => emptyApps,
    launchApp: async () => {
      throw new Error('Application launching requires the native host.');
    },
    getFavorites: async () => emptyFavorites,
    setFavorites: async () => emptyFavorites,

    getWorkspaces: async () => noCompositor,
    activateWorkspace: async () => {
      throw new Error('Compositor control requires the native host.');
    },
    getWindows: async () => noWindows,
    activateWindow: async () => {
      throw new Error('Window control requires the native host.');
    },

    getAudio: async () => audio,
    setVolume: async () => audio,
    setMuted: async () => audio,

    getNetwork: async () => network,
    setWifiEnabled: async () => network,
    setNetworkingEnabled: async () => network,

    getBluetooth: async () => bluetooth,
    setBluetoothPowered: async () => bluetooth,

    getBattery: async () => battery,
    getBrightness: async () => brightness,
    setBrightness: async () => brightness,

    getPower: async (): Promise<PowerState> => ({
      uptimeSeconds: 0,
      sessionDesktop: null,
      battery: null,
    }),

    getSettings: async () => previewSettings,
    updateSettings: async () => previewSettings,

    getNotifications: async () => emptyNotifications,
    getNotificationStatus: async () => emptyNotifications.status,
    dismissNotification: async () => {
      throw new Error('Notifications require the native host.');
    },

    openPopup: async () => {
      /* No popups outside the native shell. */
    },
    closePopup: async () => {
      /* No popups outside the native shell. */
    },
    resizeSurface: async () => {
      /* No layer surfaces outside the native shell. */
    },

    onEvent: () => () => {
      /* Preview never emits events. */
    },
  };
}
