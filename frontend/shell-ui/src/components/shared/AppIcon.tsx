import { useEffect, useState } from 'react';

export interface AppIconProps {
  /** Opaque host icon token; `null`/empty falls back to the letter glyph. */
  iconToken: string | null;
  /** App or window title used for the fallback letter and alt text. */
  label: string;
  /** Rendered size in px. */
  size?: number;
}

/**
 * Renders an application icon through the host icon endpoint
 * (`/oziro-icon/<token>`, same origin). Without a usable token — or when the
 * image fails to load — a letter glyph with an accent background is shown.
 */
export function AppIcon({ iconToken, label, size = 32 }: AppIconProps) {
  const [failed, setFailed] = useState(false);
  const usable = typeof iconToken === 'string' && iconToken.length > 0 && !failed;

  useEffect(() => {
    setFailed(false);
  }, [iconToken]);

  if (usable) {
    return (
      <img
        className="app-icon"
        src={`${window.location.origin}/oziro-icon/${iconToken}`}
        alt={label}
        width={size}
        height={size}
        onError={() => setFailed(true)}
        draggable={false}
      />
    );
  }

  const letter = (label.trim()[0] ?? '·').toUpperCase();

  return (
    <span
      className="app-icon app-icon-fallback"
      style={{ width: size, height: size, fontSize: Math.round(size * 0.46) }}
      aria-hidden="true"
    >
      {letter}
    </span>
  );
}
