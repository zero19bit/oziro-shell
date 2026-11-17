import { useCallback, useEffect, useRef, useState } from 'react';
import { useAdapter } from '../lib/adapter-context';
import type { Settings } from '@oziro/protocol';
import { describeError, isSettings } from '../lib/frontend-types';

export interface UseSettingsResult {
  settings: Settings | null;
  error: string | null;
  loading: boolean;
  refresh: () => void;
  /**
   * Applies a patch optimistically, persists it through the adapter and
   * syncs to the returned settings. On failure the previous value is
   * restored and the reason is exposed through `error`.
   */
  update: (patch: Partial<Settings>) => Promise<boolean>;
}

export function useSettings(): UseSettingsResult {
  const adapter = useAdapter();

  const [settings, setSettings] = useState<Settings | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [tick, setTick] = useState(0);

  const settingsRef = useRef<Settings | null>(null);

  useEffect(() => {
    settingsRef.current = settings;
  }, [settings]);

  useEffect(() => {
    let cancelled = false;

    setLoading(true);
    adapter
      .getSettings()
      .then((result) => {
        if (cancelled) {
          return;
        }
        setSettings(result);
        setError(null);
      })
      .catch((cause: unknown) => {
        if (cancelled) {
          return;
        }
        setError(describeError(cause));
      })
      .finally(() => {
        if (!cancelled) {
          setLoading(false);
        }
      });

    return () => {
      cancelled = true;
    };
  }, [adapter, tick]);

  useEffect(
    () =>
      adapter.onEvent('settings.changed', (payload) => {
        if (!isSettings(payload)) {
          return;
        }
        setSettings(payload);
        setError(null);
      }),
    [adapter],
  );

  const refresh = useCallback(() => {
    setTick((value) => value + 1);
  }, []);

  const update = useCallback(
    async (patch: Partial<Settings>): Promise<boolean> => {
      const snapshot = settingsRef.current;

      if (snapshot !== null) {
        setSettings({ ...snapshot, ...patch });
      }

      try {
        const next = await adapter.updateSettings(patch);
        setSettings(next);
        setError(null);
        return true;
      } catch (cause: unknown) {
        setSettings(snapshot);
        setError(describeError(cause));
        return false;
      }
    },
    [adapter],
  );

  return { settings, error, loading, refresh, update };
}
