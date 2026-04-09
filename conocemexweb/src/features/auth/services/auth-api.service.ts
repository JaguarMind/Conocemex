import { httpClient } from '@/core/services/http-client';
import type { LoginCredentials } from '../models/auth.types';

export const authApiService = {
  async login(credentials: LoginCredentials) {
    return httpClient.post('/auth/login', credentials);
  },

  async loginWithGoogle(idToken: string) {
    return httpClient.post('/auth/google', { idToken });
  },
};
