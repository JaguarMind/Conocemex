export const env = {
  API_URL: process.env.NEXT_PUBLIC_API_URL ?? 'https://api.conocemex.com/api/v1',
  SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL ?? '',
  SUPABASE_ANON_KEY: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? '',
  GOOGLE_MAPS_KEY: process.env.NEXT_PUBLIC_GOOGLE_MAPS_KEY ?? '',
  DEBUG_MODE: process.env.NODE_ENV === 'development',
} as const;
