import { createDesktopAdapter } from './desktop-adapter';
import type { DesktopAdapter } from './desktop-adapter';

/**
 * Process-wide adapter singleton. Created lazily the first time a surface
 * needs it, so tests can inject a mock through `AdapterContext` without ever
 * touching the real selection logic.
 */
let instance: DesktopAdapter | null = null;

export function getDesktopAdapter(): DesktopAdapter {
  instance ??= createDesktopAdapter();
  return instance;
}
