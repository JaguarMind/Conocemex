import { httpClient } from '@/core/services/http-client';

export interface PaymentConfirmation {
  id: string;
  status: 'completed' | 'failed';
  qrCode: string;
}

export const paymentService = {
  async confirmPayment(businessId: string, amountMXN: number, amountUSD: number): Promise<PaymentConfirmation> {
    return httpClient.post('/payments', { businessId, amountMXN, amountUSD });
  },
};
