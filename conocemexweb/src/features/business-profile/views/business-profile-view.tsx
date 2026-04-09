'use client';

import { use } from 'react';
import { useRouter } from 'next/navigation';
import { useBusinessViewModel } from '../viewmodels/use-business-viewmodel';
import { formatCurrency } from '@/core/utils/format';
import { cn } from '@/core/utils/cn';

interface Props {
  paramsPromise: Promise<{ id: string }>;
}

const DAY_LABELS: Record<string, string> = {
  lun: 'Mon', mar: 'Tue', mie: 'Wed', jue: 'Thu', vie: 'Fri', sab: 'Sat', dom: 'Sun',
};

export function BusinessProfileView({ paramsPromise }: Props) {
  const { id } = use(paramsPromise);
  const router = useRouter();
  const vm = useBusinessViewModel(id);

  if (vm.isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="w-10 h-10 border-2 border-surface-container border-t-primary-container rounded-full animate-spin" />
      </div>
    );
  }

  if (!vm.business) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen gap-4 px-6">
        <span className="material-symbols-outlined text-5xl text-on-surface-variant/40">store_off</span>
        <p className="text-on-surface-variant font-medium">Business not found</p>
        <button onClick={() => router.push('/map')} className="text-primary font-bold text-sm">Back to Map</button>
      </div>
    );
  }

  const biz = vm.business;
  const description = biz.translations?.[0]?.description ?? '';
  const allImages = [
    ...(biz.cover_image_url ? [biz.cover_image_url] : []),
    ...(biz.images?.map((img) => img.image_url) ?? []),
  ];

  return (
    <div className="bg-background min-h-screen pb-32">
      {/* Header */}
      <header className="fixed top-0 w-full z-50 bg-white/80 backdrop-blur-xl shadow-xl shadow-on-surface/5 flex items-center px-6 h-16">
        <button onClick={() => router.back()} className="p-2 hover:bg-surface-container-low rounded-full transition-colors">
          <span className="material-symbols-outlined text-on-surface">arrow_back</span>
        </button>
        <h1 className="flex-1 text-center font-display font-bold text-on-surface truncate mx-4">{biz.name}</h1>
        <div className="w-10" />
      </header>

      {/* Image Gallery */}
      <div className="pt-16">
        {allImages.length > 0 ? (
          <div className="flex overflow-x-auto hide-scrollbar gap-1">
            {allImages.map((url, i) => (
              <img key={i} src={url} alt={biz.name} className="h-64 w-full object-cover shrink-0 first:rounded-none" />
            ))}
          </div>
        ) : (
          <div className="h-48 bg-surface-container-low flex items-center justify-center">
            <span className="material-symbols-outlined text-5xl text-on-surface-variant/30">store</span>
          </div>
        )}
      </div>

      <div className="px-6 pt-6">
        {/* Name + Badges */}
        <div className="flex items-start justify-between gap-3 mb-2">
          <h2 className="font-display text-2xl font-extrabold text-on-surface tracking-tight">{biz.name}</h2>
          <div className="flex items-center gap-2 shrink-0">
            {biz.is_verified && (
              <span className="inline-flex items-center gap-1 bg-primary/10 text-primary px-2.5 py-1 rounded-full text-xs font-bold">
                <span className="material-symbols-outlined text-xs" style={{ fontVariationSettings: '"FILL" 1' }}>verified</span>
                Verified
              </span>
            )}
          </div>
        </div>

        {/* Category + Rating */}
        <div className="flex items-center gap-3 text-sm text-on-surface-variant mb-4">
          {biz.category?.slug && <span className="capitalize">{biz.category.slug}</span>}
          {biz.average_rating && <span className="font-semibold">⭐ {biz.average_rating.toFixed(1)}</span>}
          <span>{biz.total_visits} visits</span>
        </div>

        {/* Description */}
        {description && (
          <p className="text-on-surface-variant text-base leading-relaxed mb-6">{description}</p>
        )}

        {/* Address + Phone */}
        {(biz.address || biz.phone) && (
          <div className="bg-surface-container-lowest rounded-2xl p-5 mb-6 space-y-3 shadow-sm">
            {biz.address && (
              <div className="flex items-start gap-3">
                <span className="material-symbols-outlined text-on-surface-variant text-lg mt-0.5">location_on</span>
                <span className="text-sm text-on-surface">{biz.address}</span>
              </div>
            )}
            {biz.phone && (
              <div className="flex items-center gap-3">
                <span className="material-symbols-outlined text-on-surface-variant text-lg">call</span>
                <a href={`tel:${biz.phone}`} className="text-sm text-primary font-semibold">{biz.phone}</a>
              </div>
            )}
          </div>
        )}

        {/* Schedule */}
        {biz.schedule && Object.keys(biz.schedule).length > 0 && (
          <div className="mb-6">
            <h3 className="font-display font-bold text-on-surface text-lg mb-3">Schedule</h3>
            <div className="bg-surface-container-lowest rounded-2xl p-5 shadow-sm">
              <div className="grid grid-cols-2 gap-2">
                {Object.entries(biz.schedule).map(([day, hours]) => (
                  <div key={day} className="flex justify-between text-sm">
                    <span className="font-semibold text-on-surface">{DAY_LABELS[day] ?? day}</span>
                    <span className="text-on-surface-variant">{hours}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* Offerings */}
        {biz.offerings && biz.offerings.length > 0 && (
          <div className="mb-6">
            <h3 className="font-display font-bold text-on-surface text-lg mb-3">
              Products & Services
            </h3>
            <div className="space-y-3">
              {biz.offerings
                .filter((o) => o.is_active)
                .sort((a, b) => a.sort_order - b.sort_order)
                .map((offering) => {
                  const name = offering.translations?.[0]?.name ?? 'Item';
                  const desc = offering.translations?.[0]?.description;
                  return (
                    <div key={offering.id} className="bg-surface-container-lowest rounded-2xl p-4 shadow-sm flex gap-4">
                      {offering.image_url && (
                        <img src={offering.image_url} alt={name} className="w-16 h-16 rounded-xl object-cover shrink-0" />
                      )}
                      <div className="flex-1 min-w-0">
                        <div className="flex justify-between items-start">
                          <h4 className="font-bold text-on-surface text-sm truncate">{name}</h4>
                          <span className="font-display font-extrabold text-primary text-sm shrink-0 ml-2">
                            {formatCurrency(offering.price_mxn)}
                          </span>
                        </div>
                        {desc && <p className="text-on-surface-variant text-xs mt-1 line-clamp-2">{desc}</p>}
                        <div className="flex items-center gap-2 mt-1.5">
                          <span className={cn('text-[10px] font-bold uppercase px-2 py-0.5 rounded-full',
                            offering.type === 'product' ? 'bg-primary/10 text-primary' : 'bg-secondary/10 text-secondary')}>
                            {offering.type}
                          </span>
                          {offering.duration_min && (
                            <span className="text-xs text-on-surface-variant">{offering.duration_min} min</span>
                          )}
                        </div>
                      </div>
                    </div>
                  );
                })}
            </div>
          </div>
        )}

        {/* Reviews */}
        <div className="mb-6">
          <h3 className="font-display font-bold text-on-surface text-lg mb-3">
            Reviews ({vm.reviews.length})
          </h3>

          {/* Write review */}
          <div className="bg-surface-container-lowest rounded-2xl p-5 shadow-sm mb-4">
            <p className="text-sm font-semibold text-on-surface mb-3">Leave a review</p>
            <div className="flex gap-1 mb-3">
              {[1, 2, 3, 4, 5].map((star) => (
                <button key={star} onClick={() => vm.setReviewRating(star)} className="transition-transform active:scale-90">
                  <span className={cn('material-symbols-outlined text-2xl', star <= vm.reviewRating ? 'text-yellow-500' : 'text-surface-container-high')}
                    style={{ fontVariationSettings: `"FILL" ${star <= vm.reviewRating ? 1 : 0}` }}>
                    star
                  </span>
                </button>
              ))}
            </div>
            <textarea
              value={vm.reviewComment}
              onChange={(e) => vm.setReviewComment(e.target.value)}
              placeholder="Share your experience..."
              className="w-full bg-surface-container-low rounded-xl p-3 text-sm text-on-surface border-none focus:ring-2 focus:ring-primary-container resize-none h-20 placeholder:text-on-surface-variant/40"
            />
            <button
              onClick={vm.submitReview}
              disabled={vm.reviewRating === 0 || vm.isSubmittingReview}
              className={cn('mt-3 px-6 py-2.5 rounded-full text-sm font-bold transition-all active:scale-95',
                vm.reviewRating > 0 ? 'bg-primary-container text-on-primary-container' : 'bg-surface-container-high text-on-surface-variant/50 cursor-not-allowed')}
            >
              {vm.isSubmittingReview ? 'Sending...' : 'Submit Review'}
            </button>
          </div>

          {/* Reviews list */}
          {vm.reviews.map((review) => (
            <div key={review.id} className="bg-surface-container-lowest rounded-2xl p-4 shadow-sm mb-3">
              <div className="flex items-center gap-2 mb-2">
                <div className="flex">
                  {[1, 2, 3, 4, 5].map((star) => (
                    <span key={star} className={cn('material-symbols-outlined text-sm', star <= review.rating ? 'text-yellow-500' : 'text-surface-container-high')}
                      style={{ fontVariationSettings: `"FILL" ${star <= review.rating ? 1 : 0}` }}>
                      star
                    </span>
                  ))}
                </div>
                <span className="text-xs text-on-surface-variant">
                  {new Date(review.created_at).toLocaleDateString()}
                </span>
              </div>
              {review.comment && <p className="text-sm text-on-surface">{review.comment}</p>}
            </div>
          ))}
        </div>
      </div>

      {/* Bottom Actions */}
      <footer className="fixed bottom-0 left-0 w-full bg-surface/90 backdrop-blur-md px-6 py-4 border-t border-outline-variant/5 z-50">
        <div className="flex gap-2 max-w-lg mx-auto">
          <button
            onClick={() => router.push(`/navigate?businessId=${id}`)}
            className="flex-1 bg-primary-container text-on-primary-container py-3.5 rounded-full font-display font-extrabold text-sm flex items-center justify-center gap-1.5 active:scale-95 transition-all shadow-lg shadow-primary/20"
          >
            <span className="material-symbols-outlined text-lg">directions</span>
            Navigate
          </button>
          <button
            onClick={() => router.push(`/chat-setup?businessId=${id}&businessName=${encodeURIComponent(biz.name)}`)}
            className="flex-1 bg-secondary-container text-on-secondary-container py-3.5 rounded-full font-display font-extrabold text-sm flex items-center justify-center gap-1.5 active:scale-95 transition-all"
          >
            <span className="material-symbols-outlined text-lg">chat</span>
            Chat
          </button>
          <button
            onClick={() => router.push('/pay')}
            className="flex-1 bg-on-secondary-fixed text-white py-3.5 rounded-full font-display font-extrabold text-sm flex items-center justify-center gap-1.5 active:scale-95 transition-all"
          >
            <span className="material-symbols-outlined text-lg">payments</span>
            Pay
          </button>
        </div>
      </footer>
    </div>
  );
}
