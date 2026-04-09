'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';

type PaymentStep = 'choose-role' | 'enter-amount' | 'show-qr' | 'scan-qr' | 'confirm-payment';

export interface PaymentViewState {
  step: PaymentStep;
  totalMXN: number;
  amountInput: string;
  selectedCurrency: string;
  exchangeRate: number;
  isLoadingRate: boolean;
  scannedData: ScannedPayment | null;
  error: string | null;
}

export interface ScannedPayment {
  merchant: string;
  amount_mxn: number;
  timestamp: string;
}

const EXCHANGE_API_BASE = 'https://open.er-api.com/v6/latest';

export function usePaymentViewModel() {
  const [state, setState] = useState<PaymentViewState>({
    step: 'scan-qr',
    totalMXN: 0,
    amountInput: '',
    selectedCurrency: 'USD',
    exchangeRate: 0,
    isLoadingRate: true,
    scannedData: null,
    error: null,
  });

  // Fetch exchange rate
  useEffect(() => {
    let cancelled = false;
    async function fetchRate() {
      setState((prev) => ({ ...prev, isLoadingRate: true }));
      if (state.selectedCurrency === 'MXN') {
        setState((prev) => ({ ...prev, exchangeRate: 1, isLoadingRate: false }));
        return;
      }
      try {
        const res = await fetch(`${EXCHANGE_API_BASE}/${state.selectedCurrency}`);
        const data = await res.json();
        if (!cancelled && data.rates?.MXN) {
          setState((prev) => ({ ...prev, exchangeRate: data.rates.MXN, isLoadingRate: false }));
        }
      } catch {
        if (!cancelled) {
          const fallbacks: Record<string, number> = { USD: 20, EUR: 22, GBP: 25.5, CAD: 14.5, BRL: 3.8 };
          setState((prev) => ({ ...prev, exchangeRate: fallbacks[prev.selectedCurrency] ?? 20, isLoadingRate: false }));
        }
      }
    }
    fetchRate();
    return () => { cancelled = true; };
  }, [state.selectedCurrency]);

  const totalInUserCurrency = useMemo(() => {
    if (!state.exchangeRate) return 0;
    return state.totalMXN / state.exchangeRate;
  }, [state.totalMXN, state.exchangeRate]);

  const qrPayload = useMemo(() => {
    return JSON.stringify({
      merchant: 'CONOCEMEX',
      amount_mxn: state.totalMXN,
      timestamp: new Date().toISOString(),
    });
  }, [state.totalMXN]);

  // Actions
  const chooseRole = useCallback((role: 'vendor' | 'tourist') => {
    setState((prev) => ({ ...prev, step: role === 'vendor' ? 'enter-amount' : 'scan-qr' }));
  }, []);

  const setAmountInput = useCallback((val: string) => {
    if (/^\d*\.?\d{0,2}$/.test(val) || val === '') {
      setState((prev) => ({ ...prev, amountInput: val, error: null }));
    }
  }, []);

  const confirmAmount = useCallback(() => {
    const amount = parseFloat(state.amountInput);
    if (!amount || amount <= 0) {
      setState((prev) => ({ ...prev, error: 'Enter a valid amount' }));
      return;
    }
    setState((prev) => ({ ...prev, totalMXN: amount, step: 'show-qr', error: null }));
  }, [state.amountInput]);

  const onQrScanned = useCallback((data: string) => {
    console.log('[QR] Scanned raw data:', data);

    // 1. If it's a URL (Mercado Pago, Stripe, etc.) — open it directly
    if (data.startsWith('http://') || data.startsWith('https://')) {
      window.open(data, '_blank');
      setState((prev) => ({
        ...prev,
        scannedData: { merchant: 'Payment Link', amount_mxn: 0, timestamp: new Date().toISOString() },
        step: 'confirm-payment',
        error: null,
      }));
      return;
    }

    // 2. Try JSON format (from CONOCEMEX vendor app)
    try {
      const parsed = JSON.parse(data);

      // If JSON contains a URL, open it
      if (parsed.url || parsed.payment_url || parsed.link) {
        const url = parsed.url ?? parsed.payment_url ?? parsed.link;
        window.open(url, '_blank');
        setState((prev) => ({
          ...prev,
          scannedData: { merchant: parsed.merchant ?? 'Vendor', amount_mxn: parsed.amount_mxn ?? 0, timestamp: new Date().toISOString() },
          totalMXN: parsed.amount_mxn ?? 0,
          step: 'confirm-payment',
          error: null,
        }));
        return;
      }

      const amount = parsed.amount_mxn ?? parsed.amount ?? parsed.total ?? parsed.price ?? 0;
      const merchant = parsed.merchant ?? parsed.business ?? parsed.name ?? 'Vendor';

      if (amount > 0) {
        setState((prev) => ({
          ...prev,
          scannedData: { merchant, amount_mxn: Number(amount), timestamp: parsed.timestamp ?? new Date().toISOString() },
          totalMXN: Number(amount),
          step: 'confirm-payment',
          error: null,
        }));
      } else {
        setState((prev) => ({ ...prev, error: 'QR does not contain a valid amount' }));
      }
    } catch {
      // 3. Not JSON, not URL — try to extract a number
      const numberMatch = data.match(/[\d]+\.?[\d]*/);
      if (numberMatch) {
        const amount = parseFloat(numberMatch[0]);
        if (amount > 0) {
          setState((prev) => ({
            ...prev,
            scannedData: { merchant: 'Vendor', amount_mxn: amount, timestamp: new Date().toISOString() },
            totalMXN: amount,
            step: 'confirm-payment',
            error: null,
          }));
          return;
        }
      }
      setState((prev) => ({ ...prev, error: `QR read: "${data.substring(0, 50)}" — not a payment link` }));
    }
  }, []);

  const setCurrency = useCallback((code: string) => {
    setState((prev) => ({ ...prev, selectedCurrency: code }));
  }, []);

  const goBack = useCallback(() => {
    setState((prev) => {
      if (prev.step === 'enter-amount' || prev.step === 'scan-qr') return { ...prev, step: 'choose-role' };
      if (prev.step === 'show-qr') return { ...prev, step: 'enter-amount' };
      if (prev.step === 'confirm-payment') return { ...prev, step: 'scan-qr', scannedData: null };
      return prev;
    });
  }, []);

  return {
    ...state,
    totalInUserCurrency,
    qrPayload,
    chooseRole,
    setAmountInput,
    confirmAmount,
    onQrScanned,
    setCurrency,
    goBack,
  };
}
