export interface BusinessProfile {
  id: string;
  name: string;
  phone: string | null;
  address: string | null;
  latitude: number;
  longitude: number;
  schedule: Record<string, string> | null;
  cover_image_url: string | null;
  is_verified: boolean;
  is_active: boolean;
  total_visits: number;
  average_rating: number | null;
  category: { slug: string; icon?: string } | null;
  translations: BusinessTranslation[];
  images: BusinessImage[];
  offerings: Offering[];
}

export interface BusinessTranslation {
  language_id: string;
  description: string;
}

export interface BusinessImage {
  image_url: string;
  alt_text: string | null;
  sort_order: number;
}

export interface Offering {
  id: string;
  type: 'product' | 'service';
  price_mxn: number;
  price_type: string;
  duration_min: number | null;
  image_url: string | null;
  is_active: boolean;
  sort_order: number;
  translations: OfferingTranslation[];
}

export interface OfferingTranslation {
  language_id: string;
  name: string;
  description: string | null;
}

export interface Review {
  id: string;
  tourist_id: string;
  rating: number;
  comment: string | null;
  created_at: string;
}

export interface BusinessViewState {
  business: BusinessProfile | null;
  reviews: Review[];
  isLoading: boolean;
  error: string | null;
}
