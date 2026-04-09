import { httpClient } from '@/core/services/http-client';
import type { ExchangeRate } from '../models/currency.types';

export const currencyService = {
  async getRate(from: string, to: string): Promise<ExchangeRate> {
    return httpClient.get('/currency/rate', { params: { from, to } });
  },
};
