'use client';

import { useState, useEffect, useCallback } from 'react';
import { dashboardService } from '../services/dashboard.service';
import type { DashboardViewState } from '../models/dashboard.types';

export function useDashboardViewModel() {
  const [state, setState] = useState<DashboardViewState>({
    stats: null,
    zones: [],
    isLoading: true,
    error: null,
  });

  const load = useCallback(async () => {
    setState((prev) => ({ ...prev, isLoading: true, error: null }));
    try {
      const [stats, zones] = await Promise.all([
        dashboardService.getStats(),
        dashboardService.getZoneMetrics(),
      ]);
      setState({ stats, zones, isLoading: false, error: null });
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Error loading dashboard';
      setState((prev) => ({ ...prev, error: message, isLoading: false }));
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  return { ...state, refresh: load };
}
