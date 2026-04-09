import type { Coordinates, BusinessCategory } from '@/core/types/common.types';

export interface RouteStop {
  businessId: string;
  name: string;
  category: BusinessCategory;
  coordinates: Coordinates;
  estimatedTime: number;
}

export interface TouristRoute {
  id: string;
  name: string;
  stops: RouteStop[];
  totalDistance: number;
  totalTime: number;
  type: 'gastronomy' | 'cultural' | 'shopping' | 'mixed';
}

export interface RoutePreferences {
  type: TouristRoute['type'];
  maxStops: number;
  maxDistance: number;
}

export interface RouteViewState {
  route: TouristRoute | null;
  preferences: RoutePreferences;
  isLoading: boolean;
  error: string | null;
}

export interface NavigationInstruction {
  icon: string;
  text: string;
  distance: string;
}

export interface ActiveNavigation {
  destination: string;
  walkTime: string;
  remaining: string;
  instruction: NavigationInstruction;
}
