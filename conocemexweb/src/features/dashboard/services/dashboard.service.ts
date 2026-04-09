import { httpClient } from '@/core/services/http-client';
import type { DashboardStats, ZoneMetrics } from '../models/dashboard.types';

export const dashboardService = {
  async getStats(): Promise<DashboardStats> {
    return httpClient.get('/admin/stats');
  },

  async getZoneMetrics(): Promise<ZoneMetrics[]> {
    return httpClient.get('/admin/zones');
  },
};
