'use client';

import { useEffect, useRef, useState } from 'react';

interface Props {
  onScan: (data: string) => void;
  onError?: (error: string) => void;
}

export function QrScanner({ onScan, onError }: Props) {
  const [isStarted, setIsStarted] = useState(false);
  const scannerRef = useRef<import('html5-qrcode').Html5Qrcode | null>(null);

  useEffect(() => {
    let mounted = true;

    async function startScanner() {
      try {
        const { Html5Qrcode } = await import('html5-qrcode');
        if (!mounted) return;

        const scanner = new Html5Qrcode('qr-reader');
        scannerRef.current = scanner;

        await scanner.start(
          { facingMode: 'environment' },
          { fps: 10, qrbox: { width: 250, height: 250 } },
          (decodedText) => {
            scanner.stop().then(() => {
              setIsStarted(false);
              onScan(decodedText);
            }).catch(() => {});
          },
          () => {},
        );

        if (mounted) setIsStarted(true);
      } catch (err) {
        if (mounted) {
          onError?.((err as Error)?.message ?? 'Camera access denied');
        }
      }
    }

    startScanner();

    return () => {
      mounted = false;
      if (scannerRef.current && isStarted) {
        scannerRef.current.stop().catch(() => {});
      }
    };
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <div className="w-full max-w-sm mx-auto">
      <div id="qr-reader" className="rounded-2xl overflow-hidden" />
      {!isStarted && (
        <div className="flex items-center justify-center py-10">
          <div className="w-8 h-8 border-2 border-surface-container border-t-primary-container rounded-full animate-spin" />
        </div>
      )}
    </div>
  );
}
