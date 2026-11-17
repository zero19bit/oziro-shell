import type { SVGProps } from 'react';

/**
 * Inline SVG glyphs (no icon library — keep the bundle lean).
 * Every glyph inherits `currentColor` and scales via `size`.
 */

interface GlyphProps {
  size?: number;
  className?: string;
}

function base(size: number, className?: string): SVGProps<SVGSVGElement> {
  return {
    width: size,
    height: size,
    viewBox: '0 0 16 16',
    fill: 'none',
    stroke: 'currentColor',
    strokeWidth: 1.4,
    strokeLinecap: 'round',
    strokeLinejoin: 'round',
    'aria-hidden': true,
    focusable: false,
    className,
  };
}

export function GridGlyph({ size = 14, className }: GlyphProps) {
  return (
    <svg {...base(size, className)}>
      <rect x="2" y="2" width="4.6" height="4.6" rx="1.2" />
      <rect x="9.4" y="2" width="4.6" height="4.6" rx="1.2" />
      <rect x="2" y="9.4" width="4.6" height="4.6" rx="1.2" />
      <rect x="9.4" y="9.4" width="4.6" height="4.6" rx="1.2" />
    </svg>
  );
}

export function SlidersGlyph({ size = 14, className }: GlyphProps) {
  return (
    <svg {...base(size, className)}>
      <path d="M2.5 4.5h11M2.5 11.5h11" />
      <circle cx="6" cy="4.5" r="1.7" fill="currentColor" stroke="none" />
      <circle cx="10.5" cy="11.5" r="1.7" fill="currentColor" stroke="none" />
    </svg>
  );
}

export function BellGlyph({ size = 14, className }: GlyphProps) {
  return (
    <svg {...base(size, className)}>
      <path d="M4 7a4 4 0 0 1 8 0c0 2.4.6 3.6 1.2 4.4H2.8C3.4 10.6 4 9.4 4 7Z" />
      <path d="M6.6 13.4a1.5 1.5 0 0 0 2.8 0" />
    </svg>
  );
}

export function GearGlyph({ size = 14, className }: GlyphProps) {
  return (
    <svg {...base(size, className)}>
      <circle cx="8" cy="8" r="2.2" />
      <path d="M8 2.2v1.6M8 12.2v1.6M2.2 8h1.6M12.2 8h1.6M3.9 3.9l1.1 1.1M11 11l1.1 1.1M12.1 3.9 11 5M5 11l-1.1 1.1" />
    </svg>
  );
}

export function SpeakerGlyph({ size = 14, className }: GlyphProps) {
  return (
    <svg {...base(size, className)}>
      <path d="M2.5 6.2h2.2L8 3.4v9.2L4.7 9.8H2.5Z" />
      <path d="M10.2 5.8a3.2 3.2 0 0 1 0 4.4M12.2 4.2a5.6 5.6 0 0 1 0 7.6" />
    </svg>
  );
}

export function SpeakerMutedGlyph({ size = 14, className }: GlyphProps) {
  return (
    <svg {...base(size, className)}>
      <path d="M2.5 6.2h2.2L8 3.4v9.2L4.7 9.8H2.5Z" />
      <path d="M10.4 6.2l3.2 3.6M13.6 6.2l-3.2 3.6" />
    </svg>
  );
}

export function WifiGlyph({ size = 14, className }: GlyphProps) {
  return (
    <svg {...base(size, className)}>
      <path d="M2 6.4a9 9 0 0 1 12 0M4.4 9a5.6 5.6 0 0 1 7.2 0" />
      <circle cx="8" cy="12" r="1" fill="currentColor" stroke="none" />
    </svg>
  );
}

export function EthernetGlyph({ size = 14, className }: GlyphProps) {
  return (
    <svg {...base(size, className)}>
      <rect x="2.5" y="6" width="11" height="6.5" rx="1.2" />
      <path d="M5 12.5V9.6h2v2.9M9 12.5V9.6h2v2.9M5.5 6V3.8M10.5 6V3.8" />
    </svg>
  );
}

export function VpnGlyph({ size = 14, className }: GlyphProps) {
  return (
    <svg {...base(size, className)}>
      <rect x="3.5" y="7" width="9" height="6" rx="1.4" />
      <path d="M5.5 7V5.4a2.5 2.5 0 0 1 5 0V7" />
    </svg>
  );
}

export function BluetoothGlyph({ size = 14, className }: GlyphProps) {
  return (
    <svg {...base(size, className)}>
      <path d="M8 2v12M8 2l3 2.6L8 7.4 5 4.6 8 2ZM8 14l3-2.6-3-2.6-3 2.6L8 14Z" />
    </svg>
  );
}

export function BatteryGlyph({ size = 14, className }: GlyphProps) {
  return (
    <svg {...base(size, className)}>
      <rect x="2" y="5" width="10.5" height="6" rx="1.4" />
      <path d="M13.8 7.2v1.6" />
      <path d="M8.4 5.8 6.4 8h2l-1 2.4 2.4-2.6H7.8Z" fill="currentColor" stroke="none" />
    </svg>
  );
}

export function SunGlyph({ size = 14, className }: GlyphProps) {
  return (
    <svg {...base(size, className)}>
      <circle cx="8" cy="8" r="2.8" />
      <path d="M8 2.4v1.4M8 12.2v1.4M2.4 8h1.4M12.2 8h1.4M4 4l1 1M11 11l1 1M12 4l-1 1M5 11l-1 1" />
    </svg>
  );
}

export function PowerGlyph({ size = 14, className }: GlyphProps) {
  return (
    <svg {...base(size, className)}>
      <path d="M8 2.5V8" />
      <path d="M5.2 4.4a5 5 0 1 0 5.6 0" />
    </svg>
  );
}

export function DismissGlyph({ size = 12, className }: GlyphProps) {
  return (
    <svg {...base(size, className)}>
      <path d="M4.5 4.5l7 7M11.5 4.5l-7 7" />
    </svg>
  );
}

export function WindowsGlyph({ size = 14, className }: GlyphProps) {
  return (
    <svg {...base(size, className)}>
      <rect x="2.2" y="2.6" width="11.6" height="7.2" rx="1.6" />
      <path d="M5.2 13.4h5.6" />
    </svg>
  );
}
