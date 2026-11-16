import { useEffect, useMemo, useState } from 'react';
import type { RuntimeInfo } from '@oziro/protocol';
import { Dock } from './components/Dock';
import { TopPanel } from './components/TopPanel';
import { WorkspaceCanvas } from './components/WorkspaceCanvas';
import { createDesktopAdapter } from './lib/desktop-adapter';

export default function App() {
  const adapter = useMemo(() => createDesktopAdapter(), []);
  const [runtimeInfo, setRuntimeInfo] = useState<RuntimeInfo | null>(null);
  const [runtimeError, setRuntimeError] = useState<string | null>(null);

  useEffect(() => {
    let active = true;

    adapter
      .getRuntimeInfo()
      .then((info) => {
        if (active) {
          setRuntimeInfo(info);
        }
      })
      .catch((error: unknown) => {
        if (active) {
          setRuntimeError(
            error instanceof Error ? error.message : 'Unknown bridge error',
          );
        }
      });

    return () => {
      active = false;
    };
  }, [adapter]);

  const bridgeLabel = runtimeError
    ? 'Bridge error'
    : runtimeInfo?.integration.state === 'connected'
      ? 'Native bridge'
      : 'Preview mode';

  return (
    <div className="desktop-root">
      <div className="ambient ambient-one" />
      <div className="ambient ambient-two" />
      <TopPanel bridgeLabel={bridgeLabel} />
      <Dock />
      <WorkspaceCanvas
        runtimeInfo={runtimeInfo}
        runtimeError={runtimeError}
      />
    </div>
  );
}
