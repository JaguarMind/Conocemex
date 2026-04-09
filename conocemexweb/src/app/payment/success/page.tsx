'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { Suspense } from 'react';

function PaymentSuccessContent() {
  const router = useRouter();
  const searchParams = useSearchParams();

  const paymentId = searchParams.get('payment_id') ?? searchParams.get('collection_id');
  const status = searchParams.get('status') ?? searchParams.get('collection_status') ?? 'approved';
  const merchantOrderId = searchParams.get('merchant_order_id');

  return (
    <div className="bg-background min-h-screen flex flex-col items-center justify-center px-6">
      {/* Success animation */}
      <div className="w-24 h-24 bg-primary-container/20 rounded-full flex items-center justify-center mb-6 animate-[scaleIn_0.5s_ease-out]">
        <span
          className="material-symbols-outlined text-primary-container text-6xl"
          style={{ fontVariationSettings: '"FILL" 1' }}
        >
          check_circle
        </span>
      </div>

      <h1 className="font-display text-3xl font-extrabold text-on-surface tracking-tight text-center mb-2">
        Payment Successful!
      </h1>
      <p className="text-on-surface-variant text-center mb-8 max-w-xs">
        Your payment has been processed. Thank you for supporting local businesses!
      </p>

      {/* Payment details */}
      {paymentId && (
        <div className="bg-surface-container-lowest rounded-2xl p-5 shadow-sm w-full max-w-sm mb-8">
          <div className="space-y-3">
            <div className="flex justify-between text-sm">
              <span className="text-on-surface-variant">Status</span>
              <span className="font-bold text-primary capitalize">{status}</span>
            </div>
            {paymentId && (
              <div className="flex justify-between text-sm">
                <span className="text-on-surface-variant">Payment ID</span>
                <span className="font-mono text-on-surface text-xs">{paymentId}</span>
              </div>
            )}
            {merchantOrderId && (
              <div className="flex justify-between text-sm">
                <span className="text-on-surface-variant">Order</span>
                <span className="font-mono text-on-surface text-xs">{merchantOrderId}</span>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Actions */}
      <div className="flex flex-col gap-3 w-full max-w-sm">
        <button
          onClick={() => router.push('/map')}
          className="w-full bg-primary-container text-on-primary-container font-display font-extrabold text-lg h-16 rounded-full shadow-xl shadow-primary/20 hover:scale-[1.02] active:scale-95 transition-all flex items-center justify-center gap-2"
        >
          Back to Map
          <span className="material-symbols-outlined">map</span>
        </button>
        <button
          onClick={() => router.push('/discover')}
          className="w-full bg-surface-container-low text-on-surface font-bold h-14 rounded-full active:scale-95 transition-all flex items-center justify-center gap-2"
        >
          Discover More
          <span className="material-symbols-outlined">explore</span>
        </button>
      </div>

      {/* CONOCEMEX branding */}
      <p className="text-on-surface-variant/40 text-xs mt-10">
        CONOCEMEX — Supporting local businesses
      </p>
    </div>
  );
}

export default function PaymentSuccessPage() {
  return (
    <Suspense fallback={
      <div className="flex items-center justify-center min-h-screen">
        <div className="w-10 h-10 border-2 border-surface-container border-t-primary-container rounded-full animate-spin" />
      </div>
    }>
      <PaymentSuccessContent />
    </Suspense>
  );
}
