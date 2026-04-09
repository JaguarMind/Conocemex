export interface ExchangeRate {
  base: string;
  target: string;
  rate: number;
  lastUpdated: string;
}

export interface CurrencyViewState {
  amount: number;
  fromCurrency: string;
  toCurrency: string;
  rate: ExchangeRate | null;
  convertedAmount: number | null;
  isLoading: boolean;
  error: string | null;
}

export const SUPPORTED_CURRENCIES = ['MXN', 'USD', 'EUR', 'BRL', 'CAD', 'GBP'] as const;
export type SupportedCurrency = (typeof SUPPORTED_CURRENCIES)[number];
