import type { CSSProperties, ReactNode } from 'react';

/* ------------------------------------------------------------------ */
/* Segmented control                                                   */
/* ------------------------------------------------------------------ */

export interface SegmentedOption<V extends string> {
  value: V;
  label: string;
}

export interface SegmentedProps<V extends string> {
  options: readonly SegmentedOption<V>[];
  value: V | null;
  onChange: (value: V) => void;
  disabled?: boolean;
  ariaLabel: string;
}

export function Segmented<V extends string>({
  options,
  value,
  onChange,
  disabled = false,
  ariaLabel,
}: SegmentedProps<V>) {
  return (
    <div
      className="oz-segmented"
      role="group"
      aria-label={ariaLabel}
      data-disabled={disabled || undefined}
    >
      {options.map((option) => (
        <button
          key={option.value}
          type="button"
          className={`oz-segmented-option${option.value === value ? ' is-active' : ''}`}
          disabled={disabled}
          aria-pressed={option.value === value}
          onClick={() => onChange(option.value)}
        >
          {option.label}
        </button>
      ))}
    </div>
  );
}

/* ------------------------------------------------------------------ */
/* Toggle switch                                                       */
/* ------------------------------------------------------------------ */

export interface ToggleProps {
  checked: boolean;
  onChange: (checked: boolean) => void;
  disabled?: boolean;
  ariaLabel: string;
}

export function Toggle({
  checked,
  onChange,
  disabled = false,
  ariaLabel,
}: ToggleProps) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={ariaLabel}
      className={`oz-toggle${checked ? ' is-on' : ''}`}
      disabled={disabled}
      onClick={() => onChange(!checked)}
    >
      <span className="oz-toggle-knob" />
    </button>
  );
}

/* ------------------------------------------------------------------ */
/* Slider                                                              */
/* ------------------------------------------------------------------ */

export interface SliderProps {
  value: number;
  min: number;
  max: number;
  step?: number;
  onChange: (value: number) => void;
  disabled?: boolean;
  ariaLabel: string;
}

export function Slider({
  value,
  min,
  max,
  step = 1,
  onChange,
  disabled = false,
  ariaLabel,
}: SliderProps) {
  const fill =
    max > min ? ((Math.min(Math.max(value, min), max) - min) / (max - min)) * 100 : 0;

  return (
    <input
      type="range"
      className="oz-range"
      min={min}
      max={max}
      step={step}
      value={value}
      disabled={disabled}
      aria-label={ariaLabel}
      style={{ '--oz-range-fill': `${fill}%` } as CSSProperties}
      onChange={(event) => onChange(Number(event.target.value))}
    />
  );
}

/* ------------------------------------------------------------------ */
/* Small building blocks                                               */
/* ------------------------------------------------------------------ */

export function StatusLine({ children }: { children: ReactNode }) {
  return <p className="oz-status-line">{children}</p>;
}

export function UnavailableNote({ children }: { children: ReactNode }) {
  return <p className="oz-unavailable-note">{children}</p>;
}
