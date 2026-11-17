import { createContext, useContext } from 'react';
import type { DesktopAdapter } from './desktop-adapter';
import { getDesktopAdapter } from './adapter-instance';

/**
 * Adapter context. Surfaces always resolve an adapter: the explicit provider
 * (tests inject their mock here) or the lazily created singleton.
 */
export const AdapterContext = createContext<DesktopAdapter | null>(null);

export function useAdapter(): DesktopAdapter {
  return useContext(AdapterContext) ?? getDesktopAdapter();
}
