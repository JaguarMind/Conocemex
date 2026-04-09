'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import { routesService } from '../services/routes.service';
import type { RouteWithStops } from '../models/routes.types';

export function useRouteDetail(routeId: string) {
  const router = useRouter();
  const [route, setRoute] = useState<RouteWithStops | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    routesService.getRouteWithStops(routeId).then((data) => {
      setRoute(data);
      setIsLoading(false);
    });
  }, [routeId]);

  const deleteRoute = useCallback(async () => {
    await routesService.deleteRoute(routeId);
    router.push('/routes');
  }, [routeId, router]);

  // Build Google Maps URL with waypoints
  const googleMapsUrl = route?.stops && route.stops.length >= 2
    ? (() => {
        const origin = route.stops[0].business;
        const dest = route.stops[route.stops.length - 1].business;
        const waypoints = route.stops.slice(1, -1)
          .map((s) => s.business ? `${s.business.latitude},${s.business.longitude}` : '')
          .filter(Boolean)
          .join('|');

        let url = `https://www.google.com/maps/dir/?api=1&origin=${origin?.latitude},${origin?.longitude}&destination=${dest?.latitude},${dest?.longitude}&travelmode=walking`;
        if (waypoints) url += `&waypoints=${waypoints}`;
        return url;
      })()
    : null;

  return { route, isLoading, deleteRoute, googleMapsUrl };
}
