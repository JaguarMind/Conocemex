'use client';

import { useState, useCallback } from 'react';
import { routeService } from '../services/route.service';
import type { RouteViewState, RoutePreferences, TouristRoute } from '../models/route.types';

export function useRouteViewModel() {
  const [state, setState] = useState<RouteViewState>({
    route: null,
    preferences: { type: 'mixed', maxStops: 5, maxDistance: 5000 },
    isLoading: false,
    error: null,
  });

  const generateRoute = useCallback(
    async (lat: number, lng: number) => {
      setState((prev) => ({ ...prev, isLoading: true, error: null }));
      try {
        const route: TouristRoute = await routeService.generateRoute(
          lat,
          lng,
          state.preferences,
        );
        setState((prev) => ({ ...prev, route, isLoading: false }));
      } catch (err) {
        const message = err instanceof Error ? err.message : 'Error generating route';
        setState((prev) => ({ ...prev, error: message, isLoading: false }));
      }
    },
    [state.preferences],
  );

  const updatePreferences = useCallback((prefs: Partial<RoutePreferences>) => {
    setState((prev) => ({ ...prev, preferences: { ...prev.preferences, ...prefs } }));
  }, []);

  return { ...state, generateRoute, updatePreferences };
}
