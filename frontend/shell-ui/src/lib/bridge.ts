import {
  PROTOCOL_VERSION,
  type EventEnvelope,
  type MethodParams,
  type RequestMethod,
  type ResponseEnvelope,
} from '@oziro/protocol';

/**
 * Transport glue for the native WebKitGTK host.
 *
 * - Requests go through the WebKit script message handler `oziro`.
 * - Replies arrive via `window.__oziroResolve(requestId, json)`.
 * - Events arrive via `window.__oziroEvent(json)`.
 *
 * The host only ever receives JSON envelopes with allow-listed method names.
 * Arbitrary values (paths, shell strings) are never part of the protocol.
 */

type ResolveFn = (requestId: string, json: string) => void;
type EventFn = (json: string) => void;

interface BridgeGlobals {
  __oziroPending?: Map<string, (response: ResponseEnvelope<unknown>) => void>;
  __oziroResolve?: ResolveFn;
  __oziroEvent?: EventFn;
  __oziroBridgeReady?: boolean;
}

interface WebKitMessageHandler {
  postMessage(message: string): void;
}

declare global {
  interface Window {
    webkit?: {
      messageHandlers?: {
        oziro?: WebKitMessageHandler;
      };
    };
  }
}

const globals = window as unknown as BridgeGlobals;

const pending =
  globals.__oziroPending ??
  (globals.__oziroPending = new Map<
    string,
    (response: ResponseEnvelope<unknown>) => void
  >());

if (!globals.__oziroResolve) {
  globals.__oziroResolve = (requestId, json) => {
    const resolve = pending.get(requestId);
    if (!resolve) {
      return;
    }
    pending.delete(requestId);

    let envelope: ResponseEnvelope<unknown>;
    try {
      envelope = JSON.parse(json) as ResponseEnvelope<unknown>;
    } catch {
      envelope = {
        protocolVersion: PROTOCOL_VERSION,
        requestId,
        ok: false,
        error: {
          code: 'INTERNAL',
          message: 'Malformed bridge response.',
          retryable: false,
        },
      };
    }

    resolve(envelope);
  };
}

if (!globals.__oziroEvent) {
  globals.__oziroEvent = (json) => {
    let envelope: EventEnvelope;
    try {
      envelope = JSON.parse(json) as EventEnvelope;
    } catch {
      return;
    }
    if (envelope.protocolVersion !== PROTOCOL_VERSION) {
      return;
    }
    for (const handler of [...eventHandlers(envelope.event)]) {
      try {
        handler(envelope.payload);
      } catch (error) {
        console.error('[oziro-bridge] event handler failed', error);
      }
    }
  };
}

globals.__oziroBridgeReady = true;

/* ------------------------------------------------------------------ */

type EventHandler = (payload: unknown) => void;

const eventRegistry = new Map<string, Set<EventHandler>>();

function eventHandlers(event: string): ReadonlySet<EventHandler> {
  return eventRegistry.get(event) ?? EMPTY;
}

const EMPTY: ReadonlySet<EventHandler> = new Set();

/** Returns the native bridge when running inside the Oziro GTK host. */
export function getNativeHandler(): WebKitMessageHandler | null {
  return window.webkit?.messageHandlers?.oziro ?? null;
}

export function isNativeBridgeAvailable(): boolean {
  return getNativeHandler() !== null;
}

let nextRequestId = 0;

function nextId(): string {
  nextRequestId += 1;
  return `req-${Date.now().toString(36)}-${nextRequestId.toString(36)}`;
}

export class BridgeRequestError extends Error {
  readonly code: string;
  readonly retryable: boolean;

  constructor(code: string, message: string, retryable: boolean) {
    super(message);
    this.name = 'BridgeRequestError';
    this.code = code;
    this.retryable = retryable;
  }
}

const REQUEST_TIMEOUT_MS = 10_000;

export function request<M extends RequestMethod>(
  method: M,
  params?: MethodParams<M>,
): Promise<unknown> {
  const handler = getNativeHandler();

  if (!handler) {
    return Promise.reject(
      new BridgeRequestError('NOT_NATIVE', 'Native bridge is not available.', false),
    );
  }

  const requestId = nextId();

  return new Promise((resolve, reject) => {
    const timer = window.setTimeout(() => {
      pending.delete(requestId);
      reject(
        new BridgeRequestError('TIMEOUT', 'Bridge request timed out.', true),
      );
    }, REQUEST_TIMEOUT_MS);

    pending.set(requestId, (envelope) => {
      window.clearTimeout(timer);

      if (envelope.ok) {
        resolve(envelope.result);
      } else {
        reject(
          new BridgeRequestError(
            envelope.error.code,
            envelope.error.message,
            envelope.error.retryable,
          ),
        );
      }
    });

    handler.postMessage(
      JSON.stringify({
        protocolVersion: PROTOCOL_VERSION,
        requestId,
        method,
        ...(params === undefined ? {} : { params }),
      }),
    );
  });
}

/** Typed helper that resolves the payload after enforcing error semantics. */
export async function requestResult<M extends RequestMethod>(
  method: M,
  params?: MethodParams<M>,
): Promise<unknown> {
  return request(method, params);
}

export function subscribe(
  event: string,
  handler: (payload: unknown) => void,
): () => void {
  let set = eventRegistry.get(event);

  if (!set) {
    set = new Set();
    eventRegistry.set(event, set);
  }

  set.add(handler);

  return () => {
    set?.delete(handler);
  };
}
