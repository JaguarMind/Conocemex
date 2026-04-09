import { authService } from '@/core/services/auth.service';
import { MOCK_BUSINESSES } from '@/core/data/mock-businesses';
import type { BusinessProfile, Review } from '../models/business.types';

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export const businessService = {
  async getById(id: string): Promise<BusinessProfile | null> {
    // If not a valid UUID, return mock data
    if (!UUID_REGEX.test(id)) {
      const mock = MOCK_BUSINESSES.find((b) => b.id === id);
      if (!mock) return null;
      return {
        id: mock.id,
        name: mock.name,
        phone: mock.phone ?? null,
        address: mock.address ?? null,
        latitude: mock.coordinates.latitude,
        longitude: mock.coordinates.longitude,
        schedule: null,
        cover_image_url: mock.imageUrl ?? null,
        is_verified: false,
        is_active: true,
        total_visits: 0,
        average_rating: mock.rating ?? null,
        category: { slug: mock.category },
        translations: [{ language_id: 'en', description: mock.description.en }],
        images: mock.imageUrl ? [{ image_url: mock.imageUrl, alt_text: null, sort_order: 0 }] : [],
        offerings: [],
      };
    }

    const supabase = authService.client;

    const { data, error } = await supabase
      .from('businesses')
      .select(`
        *,
        category:categories(slug),
        translations:business_translations(language_id, description),
        images:business_images(image_url, alt_text, sort_order),
        offerings(*, translations:offering_translations(language_id, name, description))
      `)
      .eq('id', id)
      .single();

    if (error) {
      console.error('[Business] Fetch error:', error);
      return null;
    }

    return data as unknown as BusinessProfile;
  },

  async getReviews(businessId: string): Promise<Review[]> {
    if (!UUID_REGEX.test(businessId)) return [];

    const supabase = authService.client;

    const { data, error } = await supabase
      .from('reviews')
      .select('id, tourist_id, rating, comment, created_at')
      .eq('business_id', businessId)
      .order('created_at', { ascending: false })
      .limit(20);

    if (error) {
      console.error('[Business] Reviews error:', error);
      return [];
    }

    return (data ?? []) as Review[];
  },

  async submitReview(params: {
    touristId: string;
    businessId: string;
    rating: number;
    comment?: string;
  }): Promise<void> {
    if (!UUID_REGEX.test(params.businessId)) return;

    const supabase = authService.client;

    const { error } = await supabase.from('reviews').upsert(
      {
        tourist_id: params.touristId,
        business_id: params.businessId,
        rating: params.rating,
        comment: params.comment ?? null,
      },
      { onConflict: 'tourist_id,business_id' },
    );

    if (error) {
      console.error('[Business] Review submit error:', error);
      throw error;
    }
  },
};
