'use client';

import { useState, useEffect, useCallback } from 'react';
import { routesService } from '../services/routes.service';
import type { Route } from '../models/routes.types';

export function useMyRoutes() {
  const [routes, setRoutes] = useState<Route[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const load = useCallback(async () => {
    setIsLoading(true);
    const data = await routesService.getMyRoutes();
    setRoutes(data);
    setIsLoading(false);
  }, []);

  useEffect(() => { load(); }, [load]);

  const deleteRoute = useCallback(async (id: string) => {
    await routesService.deleteRoute(id);
    setRoutes((prev) => prev.filter((r) => r.id !== id));
  }, []);

  return { routes, isLoading, deleteRoute, refresh: load };
}
