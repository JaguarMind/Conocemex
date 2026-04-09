import axios, { type AxiosInstance, type AxiosRequestConfig } from 'axios';
import { env } from '@/core/config/env';

const instance: AxiosInstance = axios.create({
  baseURL: env.API_URL,
  timeout: 30000,
  headers: { 'Content-Type': 'application/json' },
});

// Request interceptor: attach auth token
instance.interceptors.request.use((config) => {
  if (typeof window !== 'undefined') {
    const token = localStorage.getItem('access_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
  }

  if (env.DEBUG_MODE) {
    console.log(`[HTTP] ${config.method?.toUpperCase()} ${config.url}`, config.params ?? '');
  }

  return config;
});

// Response interceptor: error handling
instance.interceptors.response.use(
  (response) => response,
  (error) => {
    if (env.DEBUG_MODE) {
      console.error('[HTTP Error]', error.response?.status, error.response?.data);
    }

    const message =
      error.response?.data?.message ??
      error.message ??
      'An unexpected error occurred';

    return Promise.reject(new Error(message));
  },
);

export const httpClient = {
  async get<T>(url: string, config?: AxiosRequestConfig): Promise<T> {
    const response = await instance.get<T>(url, config);
    return response.data;
  },

  async post<T>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<T> {
    const response = await instance.post<T>(url, data, config);
    return response.data;
  },

  async put<T>(url: string, data?: unknown, config?: AxiosRequestConfig): Promise<T> {
    const response = await instance.put<T>(url, data, config);
    return response.data;
  },

  async delete<T>(url: string, config?: AxiosRequestConfig): Promise<T> {
    const response = await instance.delete<T>(url, config);
    return response.data;
  },
};
