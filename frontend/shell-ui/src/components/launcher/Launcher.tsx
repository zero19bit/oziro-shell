import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import type { KeyboardEvent as ReactKeyboardEvent } from 'react';
import { useAdapter } from '../../lib/adapter-context';
import { useSettings } from '../../hooks/useSettings';
import { usePopupEscape } from '../../hooks/usePopupEscape';
import { describeError } from '../../lib/frontend-types';
import { AppIcon } from '../shared/AppIcon';
import type { AppEntry } from '@oziro/protocol';

const SEARCH_DEBOUNCE_MS = 150;

type CategoryChip =
  | { kind: 'all' }
  | { kind: 'favorites' }
  | { kind: 'category'; raw: string; label: string };

const CATEGORY_LABELS: Record<string, string> = {
  utility: 'Utilities',
  utilities: 'Utilities',
  development: 'Development',
  game: 'Games',
  games: 'Games',
  science: 'Science',
  education: 'Education',
  network: 'Network',
  office: 'Office',
  graphics: 'Graphics',
  audiovideo: 'Audio & Video',
  'audio-video': 'Audio & Video',
  system: 'System',
  settings: 'Preferences',
  accessibility: 'Accessibility',
};

function friendlyCategory(raw: string): string {
  const key = raw.toLowerCase();
  const known = CATEGORY_LABELS[key];
  if (known) {
    return known;
  }
  return raw
    .replace(/([a-z])([A-Z])/g, '$1 $2')
    .replace(/\b\w/g, (char) => char.toUpperCase());
}

export function Launcher() {
  const adapter = useAdapter();
  const { settings } = useSettings();
  usePopupEscape('launcher');

  const [query, setQuery] = useState('');
  const [results, setResults] = useState<AppEntry[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [launchError, setLaunchError] = useState<string | null>(null);
  const [selected, setSelected] = useState(0);
  const [chip, setChip] = useState<CategoryChip>({ kind: 'all' });

  const gridRef = useRef<HTMLDivElement>(null);

  const search = useCallback(
    (value: string) => {
      let cancelled = false;

      setLoading(true);
      const request =
        value === ''
          ? adapter.listApps()
          : adapter.searchApps(value);

      request
        .then((result) => {
          if (cancelled) {
            return;
          }
          setResults(result.apps);
          setError(null);
          setSelected(0);
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
    },
    [adapter],
  );

  const searchRef = useRef(search);

  useEffect(() => {
    searchRef.current = search;
  }, [search]);

  /* Initial load and every (debounced) query change go through here. */
  useEffect(() => {
    const timer = window.setTimeout(() => {
      searchRef.current(query);
    }, SEARCH_DEBOUNCE_MS);

    return () => window.clearTimeout(timer);
  }, [query]);

  /* Reset the active chip when the result set no longer contains it. */
  useEffect(() => {
    setChip((current) => {
      if (current.kind !== 'category') {
        return current;
      }
      return results.some((app) => app.categories.includes(current.raw))
        ? current
        : { kind: 'all' };
    });
  }, [results]);

  const chips = useMemo<CategoryChip[]>(() => {
    const categories = new Map<string, string>();
    for (const app of results) {
      for (const raw of app.categories) {
        if (raw !== '' && !categories.has(raw)) {
          categories.set(raw, friendlyCategory(raw));
        }
      }
    }

    return [
      { kind: 'all' },
      { kind: 'favorites' },
      ...[...categories.entries()]
        .map(([raw, label]) => ({ kind: 'category' as const, raw, label }))
        .sort((a, b) => a.label.localeCompare(b.label)),
    ];
  }, [results]);

  const favorites = useMemo(() => settings?.favorites ?? [], [settings]);

  const visible = useMemo(() => {
    if (chip.kind === 'favorites') {
      return results.filter((app) => favorites.includes(app.desktopId));
    }
    if (chip.kind === 'category') {
      return results.filter((app) => app.categories.includes(chip.raw));
    }
    return results;
  }, [chip, results, favorites]);

  useEffect(() => {
    setSelected((current) => Math.min(current, Math.max(visible.length - 1, 0)));
  }, [visible.length]);

  useEffect(() => {
    const grid = gridRef.current;
    const item = grid?.children[selected];
    if (item instanceof HTMLElement) {
      item.scrollIntoView?.({ block: 'nearest' });
    }
  }, [selected]);

  const launch = (app: AppEntry) => {
    setLaunchError(null);
    adapter
      .launchApp(app.desktopId)
      .then(() => adapter.closePopup('launcher'))
      .catch((cause: unknown) => {
        setLaunchError(describeError(cause));
      });
  };

  const moveSelection = (delta: number) => {
    if (visible.length === 0) {
      return;
    }
    setSelected((current) =>
      Math.min(Math.max(current + delta, 0), visible.length - 1),
    );
  };

  const onKeyDown = (event: ReactKeyboardEvent) => {
    switch (event.key) {
      case 'ArrowLeft':
        event.preventDefault();
        moveSelection(-1);
        break;
      case 'ArrowRight':
        event.preventDefault();
        moveSelection(1);
        break;
      case 'ArrowUp':
        event.preventDefault();
        moveSelection(-gridColumns(gridRef.current));
        break;
      case 'ArrowDown':
        event.preventDefault();
        moveSelection(gridColumns(gridRef.current));
        break;
      case 'Enter': {
        event.preventDefault();
        const app = visible[selected];
        if (app) {
          launch(app);
        }
        break;
      }
      default:
        break;
    }
  };

  return (
    <div className="popup-root launcher-root" data-testid="launcher-root">
      <section className="oz-glass popup-card launcher-card">
        <input
          className="launcher-input"
          type="search"
          placeholder="Search applications…"
          aria-label="Search applications"
          autoFocus
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          onKeyDown={onKeyDown}
        />

        {error !== null ? (
          <p className="oz-error-note" role="alert">
            {error}
          </p>
        ) : null}

        <div className="launcher-chips" role="tablist" aria-label="Filters">
          {chips.map((candidate) => (
            <button
              type="button"
              key={chipKey(candidate)}
              role="tab"
              aria-selected={
                chip.kind === candidate.kind &&
                (candidate.kind !== 'category' ||
                  (chip.kind === 'category' && chip.raw === candidate.raw))
              }
              className={`launcher-chip${isChipActive(chip, candidate) ? ' is-active' : ''}`}
              onClick={() => setChip(candidate)}
            >
              {chipLabel(candidate)}
            </button>
          ))}
        </div>

        <div
          ref={gridRef}
          className="launcher-grid"
          role="listbox"
          aria-label="Applications"
        >
          {visible.map((app, index) => (
            <button
              type="button"
              key={app.desktopId}
              role="option"
              aria-selected={index === selected}
              className={`launcher-item${index === selected ? ' is-selected' : ''}`}
              onPointerEnter={() => setSelected(index)}
              onClick={() => launch(app)}
            >
              <AppIcon iconToken={app.iconToken} label={app.name} size={44} />
              <span className="launcher-item-copy">
                <span className="launcher-item-name">{app.name}</span>
                <span className="launcher-item-sub">
                  {app.comment ?? app.genericName ?? ''}
                </span>
              </span>
            </button>
          ))}
        </div>

        {launchError !== null ? (
          <p className="oz-error-note" role="alert">
            {launchError}
          </p>
        ) : null}

        {error === null && visible.length === 0 ? (
          <p className="oz-status-line launcher-empty">
            {loading ? 'Searching applications…' : 'No applications found.'}
          </p>
        ) : null}
      </section>
    </div>
  );
}

function chipKey(chip: CategoryChip): string {
  switch (chip.kind) {
    case 'all':
      return 'all';
    case 'favorites':
      return 'favorites';
    case 'category':
      return `category:${chip.raw}`;
  }
}

function chipLabel(chip: CategoryChip): string {
  switch (chip.kind) {
    case 'all':
      return 'All';
    case 'favorites':
      return 'Favorites';
    case 'category':
      return chip.label;
  }
}

function isChipActive(current: CategoryChip, candidate: CategoryChip): boolean {
  if (current.kind !== candidate.kind) {
    return false;
  }
  if (current.kind === 'category' && candidate.kind === 'category') {
    return current.raw === candidate.raw;
  }
  return true;
}

/** Counts items on the first visual row of the grid (1 outside a browser). */
function gridColumns(grid: HTMLDivElement | null): number {
  const items = grid?.querySelectorAll<HTMLElement>('.launcher-item');
  if (!items || items.length === 0) {
    return 1;
  }

  const firstTop = items[0].offsetTop;
  let columns = 0;
  for (const item of items) {
    if (item.offsetTop !== firstTop) {
      break;
    }
    columns += 1;
  }

  return Math.max(1, columns);
}
