import { useEffect } from 'react';
import type { Settings } from '@oziro/protocol';
import { clampInt, clampNumber } from '../lib/format';

/**
 * Applies settings that affect the whole surface: theme + reduced-motion
 * attributes on `document.documentElement`, and the runtime-settable CSS
 * custom properties (`--oz-blur`, `--oz-panel-height`, `--oz-dock-size`).
 */
export function applyShellTheme(settings: Settings | null): void {
  const root = document.documentElement;

  if (settings === null) {
    return;
  }

  root.dataset.theme = settings.theme;
  root.dataset.reducedMotion = String(settings.reducedMotion);
  root.dataset.liquidGlass = String(settings.liquidGlass);

  root.style.setProperty(
    '--oz-blur',
    `${clampNumber(settings.blurIntensity, 0, 40)}px`,
  );
  root.style.setProperty(
    '--oz-panel-height',
    `${clampInt(settings.panelHeight, 44, 64)}px`,
  );
  root.style.setProperty(
    '--oz-dock-size',
    `${clampInt(settings.dockSize, 44, 88)}px`,
  );
}

/** Hook wrapper around `applyShellTheme` for surface roots. */
export function useShellTheme(settings: Settings | null): void {
  useEffect(() => {
    applyShellTheme(settings);
  }, [settings]);
}
