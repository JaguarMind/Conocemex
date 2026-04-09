'use client';

import { useCurrencyViewModel } from '../viewmodels/use-currency-viewmodel';
import { cn } from '@/core/utils/cn';

export function CurrencyConverterView() {
  const vm = useCurrencyViewModel();

  const fromCur = vm.currencies.find((c) => c.code === vm.fromCurrency)!;
  const toCur = vm.currencies.find((c) => c.code === vm.toCurrency)!;

  return (
    <div className="bg-surface min-h-screen pt-20 pb-28 px-5 max-w-lg mx-auto">
      {/* Header */}
      <h1 className="font-display text-3xl font-extrabold text-on-surface tracking-tight mb-2">
        Currency Converter
      </h1>
      <p className="text-on-surface-variant text-sm mb-8">
        Real-time exchange rates for your trip
      </p>

      {/* From Currency */}
      <div className="bg-surface-container-lowest rounded-2xl p-5 shadow-sm mb-3">
        <p className="text-[11px] font-black text-on-surface-variant/50 uppercase tracking-widest mb-3">From</p>
        <div className="flex items-center gap-3">
          <input
            type="text"
            inputMode="decimal"
            value={vm.amount}
            onChange={(e) => vm.setAmount(e.target.value.replace(/[^0-9.]/g, ''))}
            className="flex-1 bg-transparent border-none text-3xl font-display font-extrabold text-on-surface focus:ring-0 focus:outline-none p-0"
          />
          <select
            value={vm.fromCurrency}
            onChange={(e) => vm.setFromCurrency(e.target.value)}
            className="bg-surface-container-low rounded-full px-4 py-2.5 text-sm font-bold text-on-surface border-none focus:ring-2 focus:ring-primary-container appearance-none cursor-pointer"
          >
            {vm.currencies.map((c) => (
              <option key={c.code} value={c.code}>{c.flag} {c.code}</option>
            ))}
          </select>
        </div>
        <p className="text-on-surface-variant text-xs mt-2">{fromCur.name}</p>
      </div>

      {/* Swap Button */}
      <div className="flex justify-center -my-2 relative z-10">
        <button
          onClick={vm.swap}
          className="w-12 h-12 bg-primary-container text-on-primary-container rounded-full shadow-lg flex items-center justify-center active:scale-90 transition-all"
        >
          <span className="material-symbols-outlined">swap_vert</span>
        </button>
      </div>

      {/* To Currency */}
      <div className="bg-on-secondary-fixed rounded-2xl p-5 shadow-2xl shadow-on-secondary-fixed/20 mb-6">
        <p className="text-white/50 text-[11px] font-black uppercase tracking-widest mb-3">To</p>
        <div className="flex items-center gap-3">
          <p className="flex-1 text-3xl font-display font-extrabold text-white">
            {vm.isLoading ? '...' : vm.convertedAmount.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
          </p>
          <select
            value={vm.toCurrency}
            onChange={(e) => vm.setToCurrency(e.target.value)}
            className="bg-white/10 rounded-full px-4 py-2.5 text-sm font-bold text-white border-none focus:ring-2 focus:ring-primary-container appearance-none cursor-pointer"
          >
            {vm.currencies.map((c) => (
              <option key={c.code} value={c.code}>{c.flag} {c.code}</option>
            ))}
          </select>
        </div>
        <p className="text-white/50 text-xs mt-2">{toCur.name}</p>
      </div>

      {/* Exchange Rate Info */}
      <div className="bg-surface-container-lowest rounded-2xl p-5 shadow-sm mb-6">
        <div className="flex items-center gap-2 mb-3">
          <span className="w-2 h-2 bg-primary-container rounded-full animate-pulse" />
          <span className="text-xs font-bold text-on-surface-variant">Live Rate</span>
        </div>
        <p className="text-on-surface font-display font-bold text-lg">
          1 {fromCur.code} = {vm.rate.toFixed(4)} {toCur.code}
        </p>
        <p className="text-on-surface-variant/50 text-xs mt-1">
          1 {toCur.code} = {vm.rate ? (1 / vm.rate).toFixed(4) : '...'} {fromCur.code}
        </p>
      </div>

      {/* Quick Amounts */}
      <div className="mb-6">
        <p className="text-[11px] font-black text-on-surface-variant/50 uppercase tracking-widest mb-3">Quick Convert</p>
        <div className="grid grid-cols-2 gap-2">
          {['10', '50', '100', '500'].map((amt) => {
            const converted = (parseFloat(amt) * vm.rate);
            return (
              <button
                key={amt}
                onClick={() => vm.setAmount(amt)}
                className={cn(
                  'bg-surface-container-lowest rounded-xl p-3 shadow-sm text-left active:scale-[0.98] transition-all',
                  vm.amount === amt && 'ring-2 ring-primary-container',
                )}
              >
                <p className="font-bold text-on-surface text-sm">
                  {fromCur.symbol}{amt} {fromCur.code}
                </p>
                <p className="text-primary-container font-bold text-xs mt-0.5">
                  = {toCur.symbol}{converted.toFixed(2)} {toCur.code}
                </p>
              </button>
            );
          })}
        </div>
      </div>

      {/* Last Updated */}
      {vm.lastUpdated && (
        <p className="text-on-surface-variant/40 text-[10px] text-center">
          Last updated: {new Date(vm.lastUpdated).toLocaleString()}
        </p>
      )}
    </div>
  );
}
