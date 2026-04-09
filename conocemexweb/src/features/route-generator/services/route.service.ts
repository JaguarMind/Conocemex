import { httpClient } from '@/core/services/http-client';
import type { TouristRoute, RoutePreferences } from '../models/route.types';

export const routeService = {
  async generateRoute(
    lat: number,
    lng: number,
    preferences: RoutePreferences,
  ): Promise<TouristRoute> {
    return httpClient.post('/routes/generate', { lat, lng, ...preferences });
  },
};
