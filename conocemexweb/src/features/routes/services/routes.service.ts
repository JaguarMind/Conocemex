import { authService } from '@/core/services/auth.service';
import type { Route, RouteWithStops, RouteType } from '../models/routes.types';

export const routesService = {
  async createRoute(params: {
    name: string;
    type: RouteType;
    totalTimeMin?: number;
    totalCostMxn?: number;
    stops: { businessId: string; estimatedTimeMin?: number }[];
  }): Promise<Route | null> {
    const supabase = authService.client;
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return null;

    const { data: route, error } = await supabase
      .from('routes')
      .insert({
        tourist_id: user.id,
        name: params.name,
        type: params.type,
        total_estimated_time_min: params.totalTimeMin ?? null,
        total_estimated_cost_mxn: params.totalCostMxn ?? null,
      })
      .select()
      .single();

    if (error) { console.error('[Routes] Create:', error); return null; }

    const stopsPayload = params.stops.map((s, i) => ({
      route_id: route.id,
      business_id: s.businessId,
      stop_order: i + 1,
      estimated_time_min: s.estimatedTimeMin ?? null,
    }));

    const { error: stopsError } = await supabase.from('route_stops').insert(stopsPayload);
    if (stopsError) console.error('[Routes] Stops:', stopsError);

    return route as Route;
  },

  async getMyRoutes(): Promise<Route[]> {
    const supabase = authService.client;
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return [];

    const { data, error } = await supabase
      .from('routes')
      .select('id, tourist_id, name, type, total_estimated_time_min, total_estimated_cost_mxn, created_at')
      .eq('tourist_id', user.id)
      .order('created_at', { ascending: false });

    if (error) { console.error('[Routes] List:', error); return []; }
    return (data ?? []) as Route[];
  },

  async getRouteWithStops(routeId: string): Promise<RouteWithStops | null> {
    const supabase = authService.client;

    const { data, error } = await supabase
      .from('routes')
      .select(`
        *,
        stops:route_stops(
          stop_order, estimated_time_min,
          business:businesses(id, name, latitude, longitude, cover_image_url, category:categories(slug))
        )
      `)
      .eq('id', routeId)
      .single();

    if (error) { console.error('[Routes] Detail:', error); return null; }

    if (data?.stops) {
      (data.stops as { stop_order: number }[]).sort((a, b) => a.stop_order - b.stop_order);
    }

    return data as unknown as RouteWithStops;
  },

  async deleteRoute(routeId: string): Promise<void> {
    const supabase = authService.client;
    await supabase.from('route_stops').delete().eq('route_id', routeId);
    await supabase.from('routes').delete().eq('id', routeId);
  },

  async searchBusinesses(query: string) {
    const supabase = authService.client;
    const { data } = await supabase
      .from('businesses')
      .select('id, name, latitude, longitude, cover_image_url, category:categories(slug)')
      .eq('is_active', true)
      .ilike('name', `%${query}%`)
      .limit(6);
    return (data ?? []) as unknown as { id: string; name: string; latitude: number; longitude: number; cover_image_url: string | null; category: { slug: string } | null }[];
  },
};
