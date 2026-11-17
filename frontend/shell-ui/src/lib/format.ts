/**
 * Small formatting/numeric helpers shared by surfaces.
 */

export function clampNumber(value: number, min: number, max: number): number {
  if (!Number.isFinite(value)) {
    return min;
  }

  return Math.min(Math.max(value, min), max);
}

export function clampInt(value: number, min: number, max: number): number {
  const rounded = Number.isFinite(value) ? Math.round(value) : min;
  return Math.min(Math.max(rounded, min), max);
}

/**
 * Renders seconds as a compact uptime-style duration, e.g. `45s`, `1m 30s`,
 * `1h 1m`, `1d 1h`. Non-finite or negative input collapses to `0s`.
 */
export function secondsToDuration(totalSeconds: number): string {
  if (!Number.isFinite(totalSeconds) || totalSeconds < 0) {
    return '0s';
  }

  const seconds = Math.floor(totalSeconds);
  const days = Math.floor(seconds / 86_400);
  const hours = Math.floor((seconds % 86_400) / 3_600);
  const minutes = Math.floor((seconds % 3_600) / 60);
  const rest = seconds % 60;

  if (days > 0) {
    return `${days}d ${hours}h`;
  }

  if (hours > 0) {
    return `${hours}h ${minutes}m`;
  }

  if (minutes > 0) {
    return `${minutes}m ${rest}s`;
  }

  return `${rest}s`;
}
