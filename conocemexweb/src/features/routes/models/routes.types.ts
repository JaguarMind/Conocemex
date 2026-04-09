export type RouteType = 'gastronomica' | 'cultural' | 'compras' | 'mixta';

export interface Route {
  id: string;
  tourist_id: string;
  name: string;
  type: RouteType;
  total_estimated_time_min: number | null;
  total_estimated_cost_mxn: number | null;
  created_at: string;
}

export interface RouteStop {
  stop_order: number;
  estimated_time_min: number | null;
  business: {
    id: string;
    name: string;
    latitude: number;
    longitude: number;
    cover_image_url: string | null;
    category: { slug: string } | null;
  } | null;
}

export interface RouteWithStops extends Route {
  stops: RouteStop[];
}

export interface StopDraft {
  businessId: string;
  businessName: string;
  imageUrl: string | null;
  categorySlug: string;
  lat: number;
  lng: number;
  estimatedTimeMin: number | null;
}

export const ROUTE_TYPE_OPTIONS: { id: RouteType; label: string; emoji: string }[] = [
  { id: 'gastronomica', label: 'Gastronomy', emoji: '🌮' },
  { id: 'cultural', label: 'Cultural', emoji: '🏛️' },
  { id: 'compras', label: 'Shopping', emoji: '🛍️' },
  { id: 'mixta', label: 'Mixed', emoji: '✨' },
];
