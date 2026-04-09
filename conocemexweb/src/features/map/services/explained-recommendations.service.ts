import { env } from '@/core/config/env';
import type { RecommendationOnMap } from '../models/map.types';

interface ExplainedRecommendation {
  rank_position: number;
  business_id: string;
  business_name: string;
  category_slug: string;
  distance_m: number;
  reason_tag: 'top_quality' | 'equity_boost';
  is_verified: boolean;
  average_rating: number | null;
  total_visits: number;
  explanation: string | null;
}

interface ExplainedResponse {
  recommendations: ExplainedRecommendation[];
  meta: {
    tourist_language: string;
    tourist_nationality: string;
    explained_count: number;
    total_count: number;
  };
}

/**
 * Calls the Edge Function `recommend-explained` which adds AI-generated
 * explanations in the tourist's language to the top recommendations.
 * Latency: ~1.1-2.2s. Cost: ~$0.000125 per call.
 */
export async function getExplainedRecommendations(params: {
  touristId: string;
  lat: number;
  lng: number;
  radiusM?: number;
  limit?: number;
  explainTop?: number;
}): Promise<{ recommendations: (RecommendationOnMap & { explanation: string | null })[]; meta: ExplainedResponse['meta'] } | null> {
  try {
    const response = await fetch(
      `${env.SUPABASE_URL}/functions/v1/recommend-explained`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${env.SUPABASE_ANON_KEY}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          tourist_id: params.touristId,
          lat: params.lat,
          lng: params.lng,
          radius_m: params.radiusM ?? 2000,
          limit: params.limit ?? 10,
          explain_top: params.explainTop ?? 3,
        }),
      },
    );

    if (!response.ok) {
      throw new Error(`Edge function returned ${response.status}`);
    }

    const data: ExplainedResponse = await response.json();

    const recommendations = data.recommendations.map((r) => ({
      id: r.business_id,
      name: r.business_name,
      description: { es: r.business_name, en: r.business_name },
      category: mapSlug(r.category_slug),
      coordinates: { latitude: 0, longitude: 0 }, // Will be enriched later
      rating: r.average_rating ?? undefined,
      isOpen: true,
      rankPosition: r.rank_position,
      reasonTag: r.reason_tag,
      isVerified: r.is_verified,
      coverImageUrl: null,
      distanceM: Number(r.distance_m),
      explanation: r.explanation,
    }));

    return { recommendations, meta: data.meta };
  } catch (error) {
    console.warn('[ExplainedRecs] Edge function failed:', error);
    return null;
  }
}

function mapSlug(slug: string): import('@/core/types/common.types').BusinessCategory {
  const map: Record<string, import('@/core/types/common.types').BusinessCategory> = {
    gastronomia: 'restaurant', artesanias: 'crafts', hospedaje: 'lodging',
    entretenimiento: 'entertainment', compras: 'shopping', tours: 'services',
    transporte: 'services', bienestar: 'services',
  };
  return map[slug] ?? 'services';
}
