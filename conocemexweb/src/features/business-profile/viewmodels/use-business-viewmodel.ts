'use client';

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/core/hooks/use-auth';
import { businessService } from '../services/business.service';
import type { BusinessViewState } from '../models/business.types';

export function useBusinessViewModel(id: string) {
  const { user } = useAuth();

  const [state, setState] = useState<BusinessViewState>({
    business: null,
    reviews: [],
    isLoading: true,
    error: null,
  });

  const [reviewRating, setReviewRating] = useState(0);
  const [reviewComment, setReviewComment] = useState('');
  const [isSubmittingReview, setIsSubmittingReview] = useState(false);

  const load = useCallback(async () => {
    setState((prev) => ({ ...prev, isLoading: true, error: null }));
    try {
      const [business, reviews] = await Promise.all([
        businessService.getById(id),
        businessService.getReviews(id),
      ]);
      setState({ business, reviews, isLoading: false, error: null });
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Error loading business';
      setState({ business: null, reviews: [], isLoading: false, error: message });
    }
  }, [id]);

  useEffect(() => {
    load();
  }, [load]);

  const submitReview = useCallback(async () => {
    if (!user?.id || reviewRating === 0) return;
    setIsSubmittingReview(true);
    try {
      await businessService.submitReview({
        touristId: user.id,
        businessId: id,
        rating: reviewRating,
        comment: reviewComment || undefined,
      });
      setReviewRating(0);
      setReviewComment('');
      // Refresh reviews
      const reviews = await businessService.getReviews(id);
      setState((prev) => ({ ...prev, reviews }));
    } catch (err) {
      console.error('[Review] Submit failed:', err);
    } finally {
      setIsSubmittingReview(false);
    }
  }, [user?.id, id, reviewRating, reviewComment]);

  return {
    ...state,
    reviewRating,
    reviewComment,
    isSubmittingReview,
    setReviewRating,
    setReviewComment,
    submitReview,
    refresh: load,
  };
}
