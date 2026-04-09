'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';

const EXCHANGE_API = 'https://open.er-api.com/v6/latest';

const CURRENCIES = [
  { code: 'MXN', symbol: '$', flag: '🇲🇽', name: 'Mexican Peso' },
  { code: 'USD', symbol: '$', flag: '🇺🇸', name: 'US Dollar' },
  { code: 'EUR', symbol: '€', flag: '🇪🇺', name: 'Euro' },
  { code: 'GBP', symbol: '£', flag: '🇬🇧', name: 'British Pound' },
  { code: 'CAD', symbol: 'C$', flag: '🇨🇦', name: 'Canadian Dollar' },
  { code: 'BRL', symbol: 'R$', flag: '🇧🇷', name: 'Brazilian Real' },
  { code: 'JPY', symbol: '¥', flag: '🇯🇵', name: 'Japanese Yen' },
  { code: 'KRW', symbol: '₩', flag: '🇰🇷', name: 'Korean Won' },
];

export function useCurrencyViewModel() {
  const [amount, setAmount] = useState('100');
  const [fromCurrency, setFromCurrency] = useState('USD');
  const [toCurrency, setToCurrency] = useState('MXN');
  const [rates, setRates] = useState<Record<string, number>>({});
  const [isLoading, setIsLoading] = useState(true);
  const [lastUpdated, setLastUpdated] = useState('');

  useEffect(() => {
    let cancelled = false;
    async function fetchRates() {
      setIsLoading(true);
      try {
        const res = await fetch(`${EXCHANGE_API}/${fromCurrency}`);
        const data = await res.json();
        if (!cancelled && data.rates) {
          setRates(data.rates);
          setLastUpdated(data.time_last_update_utc ?? new Date().toISOString());
        }
      } catch { /* fallback */ }
      if (!cancelled) setIsLoading(false);
    }
    fetchRates();
    return () => { cancelled = true; };
  }, [fromCurrency]);

  const convertedAmount = useMemo(() => {
    const num = parseFloat(amount) || 0;
    const rate = rates[toCurrency] ?? 0;
    return num * rate;
  }, [amount, rates, toCurrency]);

  const rate = rates[toCurrency] ?? 0;

  const swap = useCallback(() => {
    setFromCurrency(toCurrency);
    setToCurrency(fromCurrency);
  }, [fromCurrency, toCurrency]);

  return {
    amount, setAmount,
    fromCurrency, setFromCurrency,
    toCurrency, setToCurrency,
    convertedAmount, rate,
    isLoading, lastUpdated,
    currencies: CURRENCIES,
    swap,
  };
}
