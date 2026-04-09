export interface Bill {
  denomination: number;
  gradient: string;
  height: string;
}

export interface TrayBill {
  id: number;
  denomination: number;
  rotation: number;
  top: number;
  left: number;
}

export interface CurrencyOption {
  code: string;
  symbol: string;
  flag: string;
  bills: Bill[];
}

export interface PaymentViewState {
  totalMXN: number;
  selectedCurrency: string;
  exchangeRate: number;
  trayBills: TrayBill[];
  totalInserted: number;
  isLoadingRate: boolean;
  error: string | null;
}

export const CURRENCIES: CurrencyOption[] = [
  {
    code: 'USD',
    symbol: '$',
    flag: '🇺🇸',
    bills: [
      { denomination: 20, gradient: 'bill-gradient-20', height: 'h-32' },
      { denomination: 10, gradient: 'bill-gradient-10', height: 'h-28' },
      { denomination: 5, gradient: 'bill-gradient-5', height: 'h-24' },
      { denomination: 1, gradient: 'bill-gradient-1', height: 'h-20' },
    ],
  },
  {
    code: 'EUR',
    symbol: '€',
    flag: '🇪🇺',
    bills: [
      { denomination: 50, gradient: 'bill-gradient-eur-50', height: 'h-32' },
      { denomination: 20, gradient: 'bill-gradient-eur-20', height: 'h-28' },
      { denomination: 10, gradient: 'bill-gradient-eur-10', height: 'h-24' },
      { denomination: 5, gradient: 'bill-gradient-eur-5', height: 'h-20' },
    ],
  },
  {
    code: 'GBP',
    symbol: '£',
    flag: '🇬🇧',
    bills: [
      { denomination: 20, gradient: 'bill-gradient-gbp-20', height: 'h-32' },
      { denomination: 10, gradient: 'bill-gradient-gbp-10', height: 'h-28' },
      { denomination: 5, gradient: 'bill-gradient-gbp-5', height: 'h-24' },
      { denomination: 1, gradient: 'bill-gradient-1', height: 'h-20' },
    ],
  },
  {
    code: 'CAD',
    symbol: 'C$',
    flag: '🇨🇦',
    bills: [
      { denomination: 20, gradient: 'bill-gradient-cad-20', height: 'h-32' },
      { denomination: 10, gradient: 'bill-gradient-cad-10', height: 'h-28' },
      { denomination: 5, gradient: 'bill-gradient-cad-5', height: 'h-24' },
      { denomination: 1, gradient: 'bill-gradient-1', height: 'h-20' },
    ],
  },
  {
    code: 'BRL',
    symbol: 'R$',
    flag: '🇧🇷',
    bills: [
      { denomination: 50, gradient: 'bill-gradient-brl-50', height: 'h-32' },
      { denomination: 20, gradient: 'bill-gradient-brl-20', height: 'h-28' },
      { denomination: 10, gradient: 'bill-gradient-brl-10', height: 'h-24' },
      { denomination: 5, gradient: 'bill-gradient-brl-5', height: 'h-20' },
    ],
  },
  {
    code: 'MXN',
    symbol: '$',
    flag: '🇲🇽',
    bills: [
      { denomination: 500, gradient: 'bill-gradient-mxn-500', height: 'h-32' },
      { denomination: 200, gradient: 'bill-gradient-mxn-200', height: 'h-28' },
      { denomination: 100, gradient: 'bill-gradient-mxn-100', height: 'h-24' },
      { denomination: 50, gradient: 'bill-gradient-mxn-50', height: 'h-20' },
    ],
  },
];
