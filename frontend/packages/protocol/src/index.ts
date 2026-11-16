export const PROTOCOL_VERSION = 1 as const;

export type IntegrationState =
  | {
      state: 'not-connected';
      reason: string;
    }
  | {
      state: 'connected';
      adapter: string;
    };

export interface RuntimeInfo {
  protocolVersion: typeof PROTOCOL_VERSION;
  appName: string;
  appVersion: string;
  integration: IntegrationState;
}

export interface RequestEnvelope {
  protocolVersion: typeof PROTOCOL_VERSION;
  requestId: string;
  method: string;
}

export interface SuccessEnvelope<T> {
  protocolVersion: typeof PROTOCOL_VERSION;
  requestId: string;
  ok: true;
  result: T;
}

export interface ErrorEnvelope {
  protocolVersion: typeof PROTOCOL_VERSION;
  requestId: string;
  ok: false;
  error: {
    code: string;
    message: string;
    retryable: boolean;
  };
}

export type ResponseEnvelope<T> = SuccessEnvelope<T> | ErrorEnvelope;
