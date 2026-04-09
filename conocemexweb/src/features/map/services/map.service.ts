import { httpClient } from '@/core/services/http-client';
import type { Business } from '../models/map.types';
import type { BusinessCategory } from '@/core/types/common.types';

export const mapService = {
  async getBusinesses(params?: {
    category?: BusinessCategory;
    lat?: number;
    lng?: number;
    radius?: number;
  }): Promise<Business[]> {
    return httpClient.get('/businesses', { params });
  },

  async getCategories(): Promise<string[]> {
    return httpClient.get('/businesses/categories');
  },
};
