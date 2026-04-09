'use client';

import { useState, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { QrScanner } from './qr-scanner';

export function QrPaymentView() {
  const router = useRouter();
  const [error, setError] = useState<string | null>(null);
  const [scanned, setScanned] = useState(false);

  const onQrScanned = useCallback((data: string) => {
    console.log('[QR] Scanned:', data);
    setScanned(true);

    // If it's a URL — open it directly
    if (data.startsWith('http://') || data.startsWith('https://')) {
      window.location.href = data;
      return;
    }

    // Try JSON with URL inside
    try {
      const parsed = JSON.parse(data);
      const url = parsed.url ?? parsed.payment_url ?? parsed.link ?? parsed.init_point;
      if (url) {
        window.open(url, '_blank');
        return;
      }
    } catch {
      // not JSON
    }

    // Not a payment link
    setError(`QR does not contain a payment link`);
    setScanned(false);
  }, []);

  return (
    <div className="bg-background min-h-screen flex flex-col">
      {/* Header */}
      <header className="fixed top-0 w-full z-50 bg-white/80 backdrop-blur-xl shadow-xl shadow-on-surface/5 flex items-center gap-3 px-6 h-16">
        <button onClick={() => router.back()} className="p-2 hover:bg-surface-container-low transition-colors rounded-full">
          <span className="material-symbols-outlined text-on-surface">arrow_back</span>
        </button>
        <span className="font-display text-xl font-bold tracking-tighter text-on-surface">CONOCEMEX</span>
      </header>

      <main className="grow pt-24 pb-10 px-6 max-w-lg mx-auto w-full flex flex-col items-center">
        <span
          className="material-symbols-outlined text-primary-container text-5xl mb-4"
          style={{ fontVariationSettings: '"FILL" 1' }}
        >
          qr_code_scanner
        </span>
        <h2 className="font-display text-2xl font-extrabold text-on-surface mb-2 text-center">
          Scan to Pay
        </h2>
        <p className="text-on-surface-variant text-sm mb-6 text-center">
          Point your camera at the vendor&apos;s QR code
        </p>

        {error && (
          <div className="bg-tertiary-container/20 text-tertiary rounded-xl px-4 py-3 text-sm font-medium mb-4 w-full text-center">
            {error}
          </div>
        )}

        {scanned ? (
          <div className="flex flex-col items-center gap-4 py-10">
            <span
              className="material-symbols-outlined text-primary-container text-6xl"
              style={{ fontVariationSettings: '"FILL" 1' }}
            >
              check_circle
            </span>
            <p className="text-on-surface font-display font-bold text-lg">Payment page opened!</p>
            <p className="text-on-surface-variant text-sm text-center">
              Complete your payment in the new tab
            </p>
            <div className="flex gap-3 mt-4">
              <button
                onClick={() => { setScanned(false); setError(null); }}
                className="bg-surface-container-low text-on-surface font-bold py-3 px-6 rounded-full text-sm active:scale-95 transition-all"
              >
                Scan Again
              </button>
              <button
                onClick={() => router.push('/map')}
                className="bg-primary-container text-on-primary-container font-bold py-3 px-6 rounded-full text-sm active:scale-95 transition-all"
              >
                Done
              </button>
            </div>
          </div>
        ) : (
          <div className="w-full mb-6">
            <QrScanner
              onScan={onQrScanned}
              onError={(err) => console.warn('[QR Scanner]', err)}
            />
          </div>
        )}

        <p className="text-on-surface-variant/50 text-xs text-center">
          The QR code will open your payment app automatically
        </p>
      </main>
    </div>
  );
}
