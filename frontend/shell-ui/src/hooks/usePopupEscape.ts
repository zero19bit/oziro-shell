import { useEffect } from 'react';
import { useAdapter } from '../lib/adapter-context';
import type { PopupSurface } from '@oziro/protocol';

/**
 * Closes a popup surface when the user presses Escape, as required by the
 * surface contract in `docs/contracts/frontend-core.md`.
 */
export function usePopupEscape(surface: PopupSurface): void {
  const adapter = useAdapter();

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        void adapter.closePopup(surface);
      }
    };

    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [adapter, surface]);
}
