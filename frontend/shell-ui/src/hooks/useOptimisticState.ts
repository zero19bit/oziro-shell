import { useEffect, useState } from 'react';

/**
 * Local mirror of server-owned state that supports optimistic updates.
 *
 * - Every time the server state changes, the mirror is reset to it.
 * - `optimistic(next)` stores `next` immediately (the caller persists it in
 *   parallel); on failure the caller calls `optimistic(server)` to revert.
 */
export function useOptimisticState<S>(
  serverState: S | null,
): [S | null, (next: S | null) => void] {
  const [local, setLocal] = useState<S | null>(null);

  useEffect(() => {
    setLocal(serverState);
  }, [serverState]);

  return [local ?? serverState, setLocal];
}
