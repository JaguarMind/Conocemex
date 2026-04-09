import { authService } from '@/core/services/auth.service';
import { MOCK_BUSINESSES } from '@/core/data/mock-businesses';
import type { RecommendationOnMap, ReasonTag } from '../models/map.types';

interface RpcRow {
  rank_position: number;
  business_id: string;
  business_name: string;
  category_slug: string;
  distance_m: number;
  reason_tag: ReasonTag;
  is_verified: boolean;
  average_rating: number | null;
  total_visits: number;
}

interface BusinessCoords {
  id: string;
  latitude: number;
  longitude: number;
  cover_image_url: string | null;
  translations?: { language_id: string; description: string }[];
  images?: { image_url: string; sort_order: number }[];
}

/**
 * Calls the Supabase RPC `recommend_businesses_discovery`
 * and enriches results with lat/lng from the businesses table.
 * Falls back to mock data if RPC fails.
 */
export async function getRecommendationsForMap(params: {
  touristId: string;
  lat: number;
  lng: number;
  radiusM?: number;
  limit?: number;
}): Promise<RecommendationOnMap[]> {
  try {
    const supabase = authService.client;

    // 1. Call the recommendation RPC
    const { data: recs, error: recsError } = await supabase.rpc(
      'recommend_businesses_discovery',
      {
        p_tourist_id: params.touristId,
        p_lat: params.lat,
        p_lng: params.lng,
        p_radius_m: params.radiusM ?? 2000,
        p_limit: params.limit ?? 10,
      },
    );

    if (recsError) {
      console.error('[Recommendations] RPC error:', JSON.stringify(recsError, null, 2));
      console.error('[Recommendations] Error details — code:', recsError.code, 'message:', recsError.message, 'hint:', recsError.hint);
      throw recsError;
    }
    console.log('[Recommendations] RPC returned', recs?.length ?? 0, 'results:', recs);
    if (!recs || recs.length === 0) return getFallbackRecommendations();

    const typedRecs = recs as RpcRow[];

    // 2. Get coordinates from businesses table
    const ids = typedRecs.map((r) => r.business_id);
    const { data: coords, error: coordsError } = await supabase
      .from('businesses')
      .select('id, latitude, longitude, cover_image_url, translations:business_translations(language_id, description), images:business_images(image_url, sort_order)')
      .in('id', ids);

    if (coordsError) throw coordsError;

    const coordsById = new Map(
      (coords as BusinessCoords[]).map((c) => [c.id, c]),
    );

    // 3. Merge RPC results with coordinates
    return typedRecs
      .filter((r) => coordsById.has(r.business_id))
      .map((r) => {
        const c = coordsById.get(r.business_id)!;
        const esDesc = c.translations?.find((t) => t.language_id)?.description ?? r.business_name;
        const firstImage = c.images?.sort((a, b) => a.sort_order - b.sort_order)?.[0]?.image_url;
        return {
          id: r.business_id,
          name: r.business_name,
          description: { es: esDesc, en: esDesc },
          category: mapCategorySlug(r.category_slug),
          coordinates: { latitude: c.latitude, longitude: c.longitude },
          imageUrl: firstImage ?? c.cover_image_url ?? undefined,
          rating: r.average_rating ?? undefined,
          isOpen: true,
          rankPosition: r.rank_position,
          reasonTag: r.reason_tag,
          isVerified: r.is_verified,
          coverImageUrl: c.cover_image_url,
          distanceM: Number(r.distance_m),
        };
      });
  } catch (error) {
    console.warn('[Recommendations] RPC failed, using fallback:', error);
    return getFallbackRecommendations();
  }
}

/**
 * Register a visit when tourist taps on a recommended business
 */
export async function registerVisit(touristId: string, businessId: string): Promise<void> {
  try {
    const supabase = authService.client;
    await supabase.from('visits').insert({
      tourist_id: touristId,
      business_id: businessId,
      source: 'recommendation',
    });
  } catch (error) {
    console.warn('[Recommendations] Failed to register visit:', error);
  }
}

// ── Helpers ──

function mapCategorySlug(slug: string): import('@/core/types/common.types').BusinessCategory {
  const map: Record<string, import('@/core/types/common.types').BusinessCategory> = {
    restaurant: 'restaurant',
    food: 'restaurant',
    crafts: 'crafts',
    artisan: 'crafts',
    lodging: 'lodging',
    hotel: 'lodging',
    entertainment: 'entertainment',
    culture: 'entertainment',
    shopping: 'shopping',
    services: 'services',
  };
  return map[slug] ?? 'services';
}

/**
 * Search businesses by name in Supabase.
 */
export async function searchBusinesses(query: string): Promise<RecommendationOnMap[]> {
  if (!query.trim()) return [];

  try {
    const supabase = authService.client;

    // First try with is_active filter
    let { data, error } = await supabase
      .from('businesses')
      .select('id, name, latitude, longitude, cover_image_url, is_verified, average_rating, total_visits, is_active, category:categories(slug), images:business_images(image_url, sort_order)')
      .ilike('name', `%${query}%`)
      .limit(10);

    console.log('[Search] Query:', query, 'Results:', data?.length, 'Error:', error?.message);
    if (data && data.length > 0) {
      console.log('[Search] Found names:', data.map(b => b.name));
    }

    if (error) throw error;
    if (!data || data.length === 0) return [];

    return data.map((biz, i) => {
      const slug = (biz.category as unknown as { slug: string } | null)?.slug ?? 'services';
      const firstImage = (biz.images as { image_url: string; sort_order: number }[] | null)
        ?.sort((a, b) => a.sort_order - b.sort_order)?.[0]?.image_url;

      return {
        id: biz.id,
        name: biz.name,
        description: { es: biz.name, en: biz.name },
        category: mapCategorySlug(slug),
        coordinates: { latitude: biz.latitude, longitude: biz.longitude },
        imageUrl: firstImage ?? biz.cover_image_url ?? undefined,
        rating: biz.average_rating ?? undefined,
        isOpen: true,
        rankPosition: 99 + i,
        reasonTag: 'top_quality' as ReasonTag,
        isVerified: biz.is_verified,
        coverImageUrl: biz.cover_image_url,
        distanceM: 0,
      };
    });
  } catch (error) {
    console.warn('[Search] Failed to search businesses:', error);
    return [];
  }
}

/**
 * Fetch ALL active businesses from Supabase (not just recommendations).
 * These are shown as regular markers on the map.
 */
export async function getAllBusinesses(): Promise<RecommendationOnMap[]> {
  try {
    const supabase = authService.client;

    const { data, error } = await supabase
      .from('businesses')
      .select('id, name, latitude, longitude, cover_image_url, is_verified, is_active, average_rating, total_visits, category:categories(slug), images:business_images(image_url, sort_order)')
      .eq('is_active', true)
      .limit(50);

    if (error) throw error;
    if (!data || data.length === 0) return [];

    return data.map((biz, i) => {
      const slug = (biz.category as unknown as { slug: string } | null)?.slug ?? 'services';
      const firstImage = (biz.images as { image_url: string; sort_order: number }[] | null)
        ?.sort((a, b) => a.sort_order - b.sort_order)?.[0]?.image_url;

      return {
        id: biz.id,
        name: biz.name,
        description: { es: biz.name, en: biz.name },
        category: mapCategorySlug(slug),
        coordinates: { latitude: biz.latitude, longitude: biz.longitude },
        imageUrl: firstImage ?? biz.cover_image_url ?? undefined,
        rating: biz.average_rating ?? undefined,
        isOpen: true,
        rankPosition: 99 + i,
        reasonTag: 'top_quality' as ReasonTag,
        isVerified: biz.is_verified,
        coverImageUrl: biz.cover_image_url,
        distanceM: 0,
      };
    });
  } catch (error) {
    console.warn('[Businesses] Failed to fetch all businesses:', error);
    return [];
  }
}

export function getFallbackRecommendations(): RecommendationOnMap[] {
  return MOCK_BUSINESSES.map((biz, i) => ({
    ...biz,
    rankPosition: i + 1,
    reasonTag: (i % 3 === 0 ? 'equity_boost' : 'top_quality') as ReasonTag,
    isVerified: i % 2 === 0,
    coverImageUrl: biz.imageUrl ?? null,
    distanceM: 200 + i * 150,
  }));
}
