/**
 * Matching between a desktop entry id (`org.kde.dolphin.desktop`) and a
 * compositor-reported application id (`dolphin`, `org.mozilla.firefox`, …).
 *
 * Matching rules (case-insensitive):
 * - exact equality after stripping a trailing `.desktop` from both sides;
 * - the last dot-segment of one side equal to the *full* stripped value of
 *   the other side (so `org.mozilla.firefox.desktop` matches `firefox`,
 *   and `firefox.desktop` matches `org.mozilla.firefox`).
 */
export function matchesAppId(
  desktopId: string | null | undefined,
  appId: string | null | undefined,
): boolean {
  if (typeof desktopId !== 'string' || typeof appId !== 'string') {
    return false;
  }

  const entry = stripDesktopSuffix(desktopId.trim());
  const app = stripDesktopSuffix(appId.trim());

  if (entry === '' || app === '') {
    return false;
  }

  if (entry === app) {
    return true;
  }

  return lastSegment(entry) === app || lastSegment(app) === entry;
}

function stripDesktopSuffix(value: string): string {
  const lower = value.toLowerCase();
  return lower.endsWith('.desktop') ? lower.slice(0, -'.desktop'.length) : lower;
}

function lastSegment(value: string): string {
  const index = value.lastIndexOf('.');
  return index === -1 ? value : value.slice(index + 1);
}
