import type { RuntimeInfo } from '@oziro/protocol';
import type { DesktopAdapter } from './desktop-adapter';

export interface NativeOziroBridge {
  getRuntimeInfo(): Promise<RuntimeInfo>;
}

declare global {
  interface Window {
    oziroBridge?: NativeOziroBridge;
  }
}

export function createNativeDesktopAdapter(
  bridge: NativeOziroBridge,
): DesktopAdapter {
  return {
    getRuntimeInfo: () => bridge.getRuntimeInfo(),
  };
}
