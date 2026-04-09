export interface DishCard {
  id: string;
  name: string;
  businessId: string;
  businessName: string;
  priceMxn: number;
  imageUrl: string | null;
  distanceM: number;
  isLocalSpecialty: boolean;
  isFavorite: boolean;
  categorySlug: string;
}

export type DiscoverFilter = 'all' | 'location' | 'distance' | 'price' | 'category';

export interface DiscoverViewState {
  dishes: DishCard[];
  searchQuery: string;
  activeFilter: DiscoverFilter;
  isLoading: boolean;
  error: string | null;
}
