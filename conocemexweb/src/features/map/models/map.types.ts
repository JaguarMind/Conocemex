import type { BusinessCategory, Coordinates } from '@/core/types/common.types';

export interface Business {
  id: string;
  name: string;
  description: Record<'es' | 'en', string>;
  category: BusinessCategory;
  coordinates: Coordinates;
  imageUrl?: string;
  rating?: number;
  isOpen?: boolean;
  phone?: string;
  address?: string;
}

export type ReasonTag = 'top_quality' | 'equity_boost';

export interface RecommendationOnMap extends Business {
  rankPosition: number;
  reasonTag: ReasonTag;
  isVerified: boolean;
  coverImageUrl: string | null;
  distanceM: number;
}

export interface MapFilter {
  category: BusinessCategory | null;
  radius: number;
}

export interface MapViewState {
  businesses: RecommendationOnMap[];
  filters: MapFilter;
  selectedBusiness: RecommendationOnMap | null;
  isLoading: boolean;
  error: string | null;
}
