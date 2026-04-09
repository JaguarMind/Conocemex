'use client';

import { useState, useEffect, useCallback } from 'react';
import { currencyService } from '../services/currency.service';
import type { CurrencyViewState } from '../models/currency.types';

export function useCurrencyViewModel() {
  const [state, setState] = useState<CurrencyViewState>({
    amount: 100,
    fromCurrency: 'MXN',
    toCurrency: 'USD',
    rate: null,
    convertedAmount: null,
    isLoading: false,
    error: null,
  });

  const fetchRate = useCallback(async () => {
    setState((prev) => ({ ...prev, isLoading: true, error: null }));
    try {
      const rate = await currencyService.getRate(state.fromCurrency, state.toCurrency);
      const converted = state.amount * rate.rate;
      setState((prev) => ({
        ...prev,
        rate,
        convertedAmount: converted,
        isLoading: false,
      }));
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Error fetching rate';
      setState((prev) => ({ ...prev, error: message, isLoading: false }));
    }
  }, [state.fromCurrency, state.toCurrency, state.amount]);

  useEffect(() => {
    fetchRate();
  }, [fetchRate]);

  const setAmount = useCallback((amount: number) => {
    setState((prev) => ({ ...prev, amount }));
  }, []);

  const setFromCurrency = useCallback((currency: string) => {
    setState((prev) => ({ ...prev, fromCurrency: currency }));
  }, []);

  const setToCurrency = useCallback((currency: string) => {
    setState((prev) => ({ ...prev, toCurrency: currency }));
  }, []);

  return { ...state, setAmount, setFromCurrency, setToCurrency, refresh: fetchRate };
}
