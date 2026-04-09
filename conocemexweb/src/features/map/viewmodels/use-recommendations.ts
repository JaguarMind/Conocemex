'use client';

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/core/hooks/use-auth';
import { useGeolocation } from '@/core/hooks/use-geolocation';
import {
  getRecommendationsForMap,
  getAllBusinesses,
  registerVisit,
  getFallbackRecommendations,
} from '../services/recommendation.service';
import type { RecommendationOnMap } from '../models/map.types';

export function useRecommendations() {
  const { user } = useAuth();
  const { coordinates } = useGeolocation();

  const [recommendations, setRecommendations] = useState<RecommendationOnMap[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setIsLoading(true);
    setError(null);

    try {
      const lat = coordinates?.latitude ?? 19.4326;
      const lng = coordinates?.longitude ?? -99.1332;

      // 1. Fetch ALL active businesses from Supabase
      const allBusinesses = await getAllBusinesses();

      // 2. If logged in, also get personalized recommendations from RPC
      let rpcRecs: RecommendationOnMap[] = [];
      if (user?.id) {
        try {
          rpcRecs = await getRecommendationsForMap({
            touristId: user.id,
            lat,
            lng,
            radiusM: 50000, // 50km to cover wider area
            limit: 15,
          });
        } catch {
          console.warn('[Recommendations] RPC failed, using all businesses only');
        }
      }

      // 3. Merge: RPC recommendations take priority (they have reason_tag)
      // All other businesses appear as regular markers
      const rpcIds = new Set(rpcRecs.map((r) => r.id));
      const nonRecommended = allBusinesses
        .filter((b) => !rpcIds.has(b.id))
        .map((b) => ({ ...b, rankPosition: 99, reasonTag: 'top_quality' as const }));

      const merged = [...rpcRecs, ...nonRecommended];

      if (merged.length > 0) {
        setRecommendations(merged);
      } else {
        // Ultimate fallback to mock data
        setRecommendations(getFallbackRecommendations());
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to load businesses';
      setError(message);
      setRecommendations(getFallbackRecommendations());
    } finally {
      setIsLoading(false);
    }
  }, [user?.id, coordinates?.latitude, coordinates?.longitude]);

  useEffect(() => {
    load();
  }, [load]);

  const trackVisit = useCallback(
    async (businessId: string) => {
      if (user?.id) {
        await registerVisit(user.id, businessId);
      }
    },
    [user?.id],
  );

  return { recommendations, isLoading, error, refresh: load, trackVisit };
}
