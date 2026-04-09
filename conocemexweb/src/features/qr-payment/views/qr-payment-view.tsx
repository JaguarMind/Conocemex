'use client';

import { useMemo } from 'react';
import { useRouter } from 'next/navigation';
import { QRCodeSVG } from 'qrcode.react';
import { usePaymentViewModel } from '../viewmodels/use-payment-viewmodel';
import { CURRENCIES } from '../models/payment.types';
import { QrScanner } from './qr-scanner';
import { cn } from '@/core/utils/cn';

function PayHeader({ onBack, showBack }: { onBack: () => void; showBack: boolean }) {
  const router = useRouter();
  return (
    <header className="fixed top-0 w-full z-50 bg-white/80 backdrop-blur-xl shadow-xl shadow-on-surface/5 flex items-center gap-3 px-6 h-16">
      <button onClick={showBack ? onBack : () => router.back()} className="p-2 hover:bg-surface-container-low transition-colors rounded-full">
        <span className="material-symbols-outlined text-on-surface">{showBack ? 'arrow_back' : 'close'}</span>
      </button>
      <span className="font-display text-xl font-bold tracking-tighter text-on-surface">CONOCEMEX</span>
    </header>
  );
}

export function QrPaymentView() {
  const router = useRouter();
  const vm = usePaymentViewModel();

  const activeCurrency = useMemo(
    () => CURRENCIES.find((c) => c.code === vm.selectedCurrency) ?? CURRENCIES[0],
    [vm.selectedCurrency],
  );

  // ── Step 0: Choose Role ──
  if (vm.step === 'choose-role') {
    return (
      <div className="bg-background min-h-screen flex flex-col">
        <PayHeader onBack={vm.goBack} showBack={false} />
        <main className="grow pt-24 pb-10 px-6 max-w-lg mx-auto w-full flex flex-col items-center justify-center">
          <span className="material-symbols-outlined text-primary-container text-7xl mb-6" style={{ fontVariationSettings: '"FILL" 1' }}>
            payments
          </span>
          <h1 className="font-display text-3xl font-extrabold text-on-surface tracking-tight text-center mb-2">
            Payment
          </h1>
          <p className="text-on-surface-variant text-center mb-10">
            How would you like to proceed?
          </p>

          <div className="flex flex-col gap-4 w-full">
            <button
              onClick={() => vm.chooseRole('vendor')}
              className="w-full py-5 rounded-xl border-2 border-on-secondary-fixed bg-white flex items-center justify-center gap-3 hover:bg-surface-container-low transition-all active:scale-[0.98]"
            >
              <span className="material-symbols-outlined text-2xl text-on-secondary-fixed" style={{ fontVariationSettings: '"FILL" 1' }}>
                point_of_sale
              </span>
              <div className="text-left">
                <span className="font-display font-extrabold text-on-secondary-fixed text-lg block">I'm the Vendor</span>
                <span className="text-on-surface-variant text-xs">Generate a QR code to charge</span>
              </div>
            </button>

            <button
              onClick={() => vm.chooseRole('tourist')}
              className="w-full py-5 rounded-xl bg-primary-container text-on-primary-container flex items-center justify-center gap-3 font-display font-extrabold text-lg shadow-xl shadow-primary/20 hover:brightness-105 active:scale-[0.98] transition-all"
            >
              <span className="material-symbols-outlined text-2xl">qr_code_scanner</span>
              <div className="text-left">
                <span className="block text-lg">I'm a Tourist</span>
                <span className="text-on-primary-container/70 text-xs font-medium block">Scan QR to pay</span>
              </div>
            </button>
          </div>
        </main>
      </div>
    );
  }

  // ── Step 1: Enter Amount (Vendor) ──
  if (vm.step === 'enter-amount') {
    return (
      <div className="bg-background min-h-screen flex flex-col">
        <PayHeader onBack={vm.goBack} showBack={true} />
        <main className="grow pt-24 pb-10 px-6 max-w-lg mx-auto w-full flex flex-col">
          <div className="flex-1 flex flex-col items-center justify-center">
            <span className="material-symbols-outlined text-primary-container text-6xl mb-4" style={{ fontVariationSettings: '"FILL" 1' }}>point_of_sale</span>
            <h2 className="font-display text-2xl font-extrabold text-on-surface mb-2 text-center">Enter Amount to Charge</h2>
            <p className="text-on-surface-variant text-sm mb-8 text-center">The customer will scan your QR to pay</p>
            <div className="relative w-full max-w-xs mb-4">
              <span className="absolute left-5 top-1/2 -translate-y-1/2 text-3xl font-extrabold text-on-surface/30">$</span>
              <input
                type="text"
                inputMode="decimal"
                value={vm.amountInput}
                onChange={(e) => vm.setAmountInput(e.target.value)}
                placeholder="0.00"
                className="w-full bg-surface-container-low rounded-2xl pl-14 pr-6 py-6 text-4xl font-display font-extrabold text-on-surface text-center border-none focus:ring-2 focus:ring-primary-container focus:outline-none placeholder:text-on-surface/20"
                autoFocus
              />
              <span className="absolute right-5 top-1/2 -translate-y-1/2 text-lg font-bold text-on-surface-variant">MXN</span>
            </div>
            {vm.error && <p className="text-tertiary text-sm font-semibold mb-4">{vm.error}</p>}
          </div>
          <button
            onClick={vm.confirmAmount}
            className="w-full bg-primary-container text-on-primary-container font-display font-extrabold text-lg h-16 rounded-full shadow-xl shadow-primary/20 hover:scale-[1.02] active:scale-95 transition-all flex items-center justify-center gap-2"
          >
            Generate QR
            <span className="material-symbols-outlined">qr_code_2</span>
          </button>
        </main>
      </div>
    );
  }

  // ── Step 2: Show QR (Vendor shows to tourist) ──
  if (vm.step === 'show-qr') {
    return (
      <div className="bg-background min-h-screen flex flex-col">
        <PayHeader onBack={vm.goBack} showBack={true} />
        <main className="grow pt-24 pb-10 px-6 max-w-lg mx-auto w-full flex flex-col items-center">
          {/* Total card */}
          <div className="bg-on-secondary-fixed rounded-xl p-8 shadow-2xl shadow-on-secondary-fixed/20 relative overflow-hidden w-full mb-8">
            <div className="absolute inset-0 opacity-10 pointer-events-none">
              <svg width="100%" height="100%">
                <defs><pattern id="pp2" patternUnits="userSpaceOnUse" width="40" height="40"><path d="M0 40L40 0M-10 10L10 -10M30 50L50 30" fill="none" stroke="white" strokeWidth="1" /></pattern></defs>
                <rect width="100%" height="100%" fill="url(#pp2)" />
              </svg>
            </div>
            <p className="text-white/60 text-sm uppercase tracking-widest mb-1">Total to Charge</p>
            <h1 className="font-display text-5xl font-extrabold text-white tracking-tighter">${vm.totalMXN.toLocaleString()} MXN</h1>
          </div>

          {/* QR Code */}
          <div className="bg-white rounded-2xl p-8 shadow-sm flex flex-col items-center mb-6 w-full">
            <p className="text-[11px] font-black text-on-surface-variant/50 uppercase tracking-widest mb-4">Show this to the customer</p>
            <div className="bg-white p-4 rounded-xl shadow-sm border border-surface-container">
              <QRCodeSVG value={vm.qrPayload} size={220} bgColor="#FFFFFF" fgColor="#001C3A" level="M" />
            </div>
            <p className="text-on-surface-variant text-xs text-center mt-4">
              The customer scans this QR with their CONOCEMEX app
            </p>
          </div>

          <button
            onClick={() => router.push('/map')}
            className="w-full bg-primary-container text-on-primary-container font-display font-extrabold text-lg h-16 rounded-full shadow-xl shadow-primary/20 hover:scale-[1.02] active:scale-95 transition-all flex items-center justify-center gap-3"
          >
            Done
            <span className="material-symbols-outlined">check_circle</span>
          </button>
        </main>
      </div>
    );
  }

  // ── Step 3: Scan QR (Tourist) ──
  if (vm.step === 'scan-qr') {
    return (
      <div className="bg-background min-h-screen flex flex-col">
        <PayHeader onBack={vm.goBack} showBack={true} />
        <main className="grow pt-24 pb-10 px-6 max-w-lg mx-auto w-full flex flex-col items-center">
          <span className="material-symbols-outlined text-primary-container text-5xl mb-4" style={{ fontVariationSettings: '"FILL" 1' }}>
            qr_code_scanner
          </span>
          <h2 className="font-display text-2xl font-extrabold text-on-surface mb-2 text-center">
            Scan Vendor's QR
          </h2>
          <p className="text-on-surface-variant text-sm mb-6 text-center">
            Point your camera at the vendor's QR code to see the amount
          </p>

          {vm.error && (
            <div className="bg-tertiary-container/20 text-tertiary rounded-xl px-4 py-3 text-sm font-medium mb-4 w-full text-center">
              {vm.error}
            </div>
          )}

          <div className="w-full mb-6">
            <QrScanner
              onScan={vm.onQrScanned}
              onError={(err) => console.warn('[QR Scanner]', err)}
            />
          </div>

          <p className="text-on-surface-variant/50 text-xs text-center">
            Make sure the QR code is well lit and within the frame
          </p>
        </main>
      </div>
    );
  }

  // ── Step 4: Confirm Payment (Tourist sees amount + conversion) ──
  return (
    <div className="bg-background min-h-screen flex flex-col">
      <PayHeader onBack={vm.goBack} showBack={true} />
      <main className="grow pt-24 pb-36 px-6 max-w-lg mx-auto w-full flex flex-col items-center">
        {/* Amount card */}
        <div className="bg-on-secondary-fixed rounded-xl p-8 shadow-2xl shadow-on-secondary-fixed/20 relative overflow-hidden w-full mb-6">
          <div className="absolute inset-0 opacity-10 pointer-events-none">
            <svg width="100%" height="100%">
              <defs><pattern id="pp3" patternUnits="userSpaceOnUse" width="40" height="40"><path d="M0 40L40 0M-10 10L10 -10M30 50L50 30" fill="none" stroke="white" strokeWidth="1" /></pattern></defs>
              <rect width="100%" height="100%" fill="url(#pp3)" />
            </svg>
          </div>
          <p className="text-white/60 text-sm uppercase tracking-widest mb-1">You will pay</p>
          <h1 className="font-display text-5xl font-extrabold text-white tracking-tighter">${vm.totalMXN.toLocaleString()} MXN</h1>
          <div className="mt-4 flex items-center gap-2">
            <span className={cn('w-2 h-2 rounded-full', vm.isLoadingRate ? 'bg-yellow-400 animate-pulse' : 'bg-primary-container animate-pulse')} />
            <p className="text-primary-container font-medium text-sm">
              {vm.isLoadingRate ? 'Loading rate...' : vm.selectedCurrency === 'MXN' ? 'Paying in MXN' : `1 ${vm.selectedCurrency} = ${vm.exchangeRate.toFixed(2)} MXN`}
            </p>
          </div>
        </div>

        {/* Currency selector */}
        <div className="w-full mb-6">
          <p className="text-[11px] font-black text-on-surface-variant/50 uppercase tracking-widest mb-3 ml-1">Your Currency</p>
          <div className="flex gap-2 overflow-x-auto hide-scrollbar">
            {CURRENCIES.map((cur) => (
              <button key={cur.code} onClick={() => vm.setCurrency(cur.code)}
                className={cn('shrink-0 flex items-center gap-2 px-4 py-2.5 rounded-full text-sm font-bold transition-all active:scale-95',
                  vm.selectedCurrency === cur.code ? 'bg-on-secondary-fixed text-white shadow-lg' : 'bg-surface-container-lowest text-on-surface-variant shadow-sm')}>
                <span className="text-lg">{cur.flag}</span>{cur.code}
              </button>
            ))}
          </div>
        </div>

        {/* Equivalent */}
        <div className="bg-white rounded-2xl p-6 shadow-sm text-center w-full mb-6">
          <div className="flex items-center justify-center gap-2 mb-1">
            <span className="material-symbols-outlined text-primary-container text-2xl" style={{ fontVariationSettings: '"FILL" 1' }}>check_circle</span>
            <span className="font-display text-2xl font-extrabold text-on-surface">
              {activeCurrency.symbol}{vm.totalInUserCurrency.toFixed(2)} {vm.selectedCurrency}
            </span>
          </div>
          <p className="text-on-surface-variant text-sm">= ${vm.totalMXN.toLocaleString()} MXN</p>
        </div>

        {vm.scannedData && (
          <p className="text-on-surface-variant/50 text-xs text-center mb-4">
            Payment to: {vm.scannedData.merchant}
          </p>
        )}
      </main>

      <footer className="fixed bottom-0 w-full bg-surface/90 backdrop-blur-md px-6 py-6 border-t border-outline-variant/5">
        <button
          onClick={() => router.push('/map')}
          className="w-full bg-primary-container text-on-primary-container font-display font-extrabold text-lg h-16 rounded-full shadow-xl shadow-primary/20 hover:scale-[1.02] active:scale-95 transition-all flex items-center justify-center gap-3"
        >
          Confirm Payment
          <span className="material-symbols-outlined">check_circle</span>
        </button>
      </footer>
    </div>
  );
}
