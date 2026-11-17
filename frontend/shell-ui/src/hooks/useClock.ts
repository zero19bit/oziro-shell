import { useEffect, useState } from 'react';

/**
 * Current wall-clock time, refreshed on a fixed interval (default 1s) so the
 * panel clock stays in step with the host clock.
 */
export function useClock(intervalMs = 1000): Date {
  const [now, setNow] = useState(() => new Date());

  useEffect(() => {
    const timer = window.setInterval(() => {
      setNow(new Date());
    }, intervalMs);

    return () => window.clearInterval(timer);
  }, [intervalMs]);

  return now;
}
