import { describe, expect, it } from 'vitest';
import { createPreviewDesktopAdapter } from './preview-adapter';

describe('PreviewDesktopAdapter', () => {
  it('clearly reports that native integration is not connected', async () => {
    const adapter = createPreviewDesktopAdapter();
    const info = await adapter.getRuntimeInfo();

    expect(info.protocolVersion).toBe(1);
    expect(info.integration.state).toBe('not-connected');
    expect(info.integration.state).toBe('not-connected');

    if (info.integration.state === 'not-connected') {
      expect(info.integration.reason).toContain('Native system integration is not connected');
    }
  });
});
