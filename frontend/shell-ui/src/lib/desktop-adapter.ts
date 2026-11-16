import type { RuntimeInfo } from '@oziro/protocol';
import { createNativeDesktopAdapter } from './native-adapter';
import { createPreviewDesktopAdapter } from './preview-adapter';

export interface DesktopAdapter {
  getRuntimeInfo(): Promise<RuntimeInfo>;
}

export function createDesktopAdapter(): DesktopAdapter {
  if (typeof window !== 'undefined' && window.oziroBridge) {
    return createNativeDesktopAdapter(window.oziroBridge);
  }

  return createPreviewDesktopAdapter();
}
