import { useCallback, useEffect, useRef, useState } from 'react';
import { useAdapter } from '../lib/adapter-context';
import { describeError, type EventName } from '../lib/frontend-types';

export interface DesktopState<T> {
  data: T | null;
  error: string | null;
  loading: boolean;
  refresh: () => void;
}

export interface UseDesktopStateOptions<T> {
  /** Initial (and refresh) fetch. Identity is allowed to change per render. */
  fetcher: () => Promise<T>;
  /** Live event to subscribe to, or null for fetch-only state. */
  eventName: EventName | null;
  /** Validates a raw event payload; a rejected payload is ignored. */
  applyEvent?: (payload: unknown) => payload is T;
  /** Set false to skip fetching and subscribing entirely. */
  enabled?: boolean;
}

/**
 * Generic state hook: fetches once, then keeps the state live by applying
 * payloads of the given host event. Fetch and event errors surface as
 * `error` strings — nothing is ever faked while a domain is unavailable.
 */
export function useDesktopState<T>(
  options: UseDesktopStateOptions<T>,
): DesktopState<T> {
  const adapter = useAdapter();
  const { fetcher, eventName, applyEvent, enabled = true } = options;

  const fetcherRef = useRef(fetcher);
  const applyEventRef = useRef(applyEvent);

  useEffect(() => {
    fetcherRef.current = fetcher;
    applyEventRef.current = applyEvent;
  });

  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(enabled);
  const [tick, setTick] = useState(0);

  const refresh = useCallback(() => {
    setTick((value) => value + 1);
  }, []);

  useEffect(() => {
    if (!enabled) {
      return;
    }

    let cancelled = false;

    setLoading(true);
    fetcherRef
      .current()
      .then((result) => {
        if (cancelled) {
          return;
        }
        setData(result);
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
  }, [adapter, enabled, tick]);

  useEffect(() => {
    if (!enabled || eventName === null) {
      return;
    }

    return adapter.onEvent(eventName, (payload) => {
      const apply = applyEventRef.current;
      if (!apply || !apply(payload)) {
        return;
      }

      setData(payload);
      setError(null);
    });
  }, [adapter, enabled, eventName]);

  return { data, error, loading, refresh };
}
