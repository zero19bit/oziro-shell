import {
  PROTOCOL_VERSION,
  type RuntimeInfo,
} from '@oziro/protocol';
import type { DesktopAdapter } from './desktop-adapter';

/**
 * Explicitly non-production adapter. It does not inspect or simulate host state.
 */
export function createPreviewDesktopAdapter(): DesktopAdapter {
  return {
    async getRuntimeInfo(): Promise<RuntimeInfo> {
      return {
        protocolVersion: PROTOCOL_VERSION,
        appName: 'Oziro Desktop',
        appVersion: '0.1.0',
        integration: {
          state: 'not-connected',
          reason: 'Native system integration is not connected. No live desktop state is being reported.',
        },
      };
    },
  };
}
