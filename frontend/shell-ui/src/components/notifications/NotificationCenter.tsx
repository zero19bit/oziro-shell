import { useAdapter } from '../../lib/adapter-context';
import { useDesktopState } from '../../hooks/useDesktopState';
import { usePopupEscape } from '../../hooks/usePopupEscape';
import { describeError, isNotificationsResult } from '../../lib/frontend-types';
import type { NotificationStatus, StoredNotification } from '@oziro/protocol';

const STATUS_TEXTS: Record<NotificationStatus['daemon'], string> = {
  external: 'Plasma is handling notifications on this session',
  oziro: 'Oziro notification daemon active',
  none: 'No notification daemon',
};

export function NotificationCenter() {
  const adapter = useAdapter();
  usePopupEscape('notifications');

  const { data, error, refresh } = useDesktopState({
    fetcher: () => adapter.getNotifications(),
    eventName: 'notifications.changed',
    applyEvent: isNotificationsResult,
  });

  const dismiss = (id: string) => {
    void adapter.dismissNotification(id).catch((cause: unknown) => {
      /* Re-fetch so the honest state is restored even after a failure. */
      refresh();
      console.warn('[oziro] dismiss failed:', describeError(cause));
    });
  };

  const status = data?.status;
  const notifications = data?.notifications ?? [];

  return (
    <div className="popup-root notifications-root" data-testid="notifications-root">
      <section className="oz-glass popup-card notifications-card">
        <header className="popup-header">
          <h1 className="popup-title">Notifications</h1>
          <span className="popup-badge">
            {notifications.length > 0 ? `${notifications.length}` : ''}
          </span>
        </header>

        <p className="notifications-status" data-testid="notifications-status">
          {status !== undefined
            ? STATUS_TEXTS[status.daemon]
            : (error ?? 'Checking notification daemon…')}
        </p>

        {error !== null && status !== undefined ? (
          <p className="oz-error-note" role="alert">
            {error}
          </p>
        ) : null}

        {notifications.length === 0 ? (
          <p className="oz-status-line notifications-empty">
            {status?.canReceive === false
              ? 'This session is not receiving notifications.'
              : 'No notifications.'}
          </p>
        ) : (
          <ul className="notifications-list">
            {notifications.map((item) => (
              <NotificationRow
                key={item.id}
                item={item}
                canDismiss={status?.canDismiss === true}
                onDismiss={() => dismiss(item.id)}
              />
            ))}
          </ul>
        )}
      </section>
    </div>
  );
}

function NotificationRow({
  item,
  canDismiss,
  onDismiss,
}: {
  item: StoredNotification;
  canDismiss: boolean;
  onDismiss: () => void;
}) {
  return (
    <li className="notification-row" data-urgency={item.urgency}>
      <div className="notification-copy">
        <span className="notification-app oz-label">{item.appName}</span>
        <span className="notification-summary">{item.summary}</span>
        {item.body !== '' ? (
          <span className="notification-body">{item.body}</span>
        ) : null}
        <time
          className="notification-time"
          dateTime={new Date(item.timestampMs).toISOString()}
        >
          {formatRelativeTime(item.timestampMs)}
        </time>
      </div>
      {canDismiss ? (
        <button
          type="button"
          className="oz-icon-button"
          aria-label={`Dismiss notification from ${item.appName}`}
          onClick={onDismiss}
        >
          ×
        </button>
      ) : null}
    </li>
  );
}

/** Relative time like `just now`, `4 min ago`, `2 h ago`, `3 d ago`. */
function formatRelativeTime(timestampMs: number, now = Date.now()): string {
  const diffSeconds = Math.round((now - timestampMs) / 1000);

  if (diffSeconds < 45) {
    return 'just now';
  }
  if (diffSeconds < 3600) {
    const minutes = Math.round(diffSeconds / 60);
    return `${minutes} min ago`;
  }
  if (diffSeconds < 86_400) {
    const hours = Math.round(diffSeconds / 3600);
    return `${hours} h ago`;
  }

  const days = Math.round(diffSeconds / 86_400);
  return `${days} d ago`;
}
