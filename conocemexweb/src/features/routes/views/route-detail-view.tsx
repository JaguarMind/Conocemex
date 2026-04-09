'use client';

import { useRouter } from 'next/navigation';
import { useRouteDetail } from '../viewmodels/use-route-detail';

const TYPE_EMOJI: Record<string, string> = { gastronomica: '🌮', cultural: '🏛️', compras: '🛍️', mixta: '✨' };

export function RouteDetailView({ routeId }: { routeId: string }) {
  const router = useRouter();
  const { route, isLoading, deleteRoute, googleMapsUrl } = useRouteDetail(routeId);

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="w-10 h-10 border-2 border-surface-container border-t-primary-container rounded-full animate-spin" />
      </div>
    );
  }

  if (!route) {
    return (
      <div className="flex flex-col items-center justify-center min-h-screen gap-4">
        <span className="material-symbols-outlined text-5xl text-on-surface-variant/40">error</span>
        <p className="text-on-surface-variant">Route not found</p>
        <button onClick={() => router.push('/routes')} className="text-primary font-bold text-sm">Back to Routes</button>
      </div>
    );
  }

  return (
    <div className="bg-surface min-h-screen pb-32">
      <header className="fixed top-0 w-full z-50 bg-white/80 backdrop-blur-xl shadow-xl shadow-on-surface/5 flex items-center gap-3 px-6 h-16">
        <button onClick={() => router.push('/routes')} className="p-2 hover:bg-surface-container-low rounded-full transition-colors">
          <span className="material-symbols-outlined text-on-surface">arrow_back</span>
        </button>
        <h1 className="font-display text-lg font-bold text-on-surface tracking-tight truncate flex-1">{route.name}</h1>
        <button onClick={deleteRoute} className="p-2 hover:bg-surface-container-low rounded-full transition-colors">
          <span className="material-symbols-outlined text-tertiary">delete</span>
        </button>
      </header>

      <main className="pt-24 px-5 max-w-lg mx-auto">
        {/* Route Info */}
        <div className="bg-on-secondary-fixed rounded-2xl p-6 shadow-2xl shadow-on-secondary-fixed/20 mb-6">
          <div className="flex items-center gap-3 mb-3">
            <span className="text-3xl">{TYPE_EMOJI[route.type] ?? '✨'}</span>
            <div>
              <h2 className="font-display font-extrabold text-white text-xl">{route.name}</h2>
              <p className="text-white/60 text-sm capitalize">{route.type}</p>
            </div>
          </div>
          <div className="flex gap-4 text-white/70 text-sm">
            {route.total_estimated_time_min && (
              <span className="flex items-center gap-1">
                <span className="material-symbols-outlined text-sm">schedule</span>
                {route.total_estimated_time_min} min
              </span>
            )}
            <span className="flex items-center gap-1">
              <span className="material-symbols-outlined text-sm">pin_drop</span>
              {route.stops.length} stops
            </span>
          </div>
        </div>

        {/* Stops */}
        <div className="space-y-0">
          {route.stops.map((stop, i) => (
            <div key={i} className="flex gap-4">
              {/* Timeline */}
              <div className="flex flex-col items-center">
                <div className="w-8 h-8 bg-primary-container rounded-full flex items-center justify-center shrink-0">
                  <span className="font-display font-bold text-on-primary-container text-sm">{stop.stop_order}</span>
                </div>
                {i < route.stops.length - 1 && (
                  <div className="w-0.5 flex-1 bg-primary-container/30 my-1" />
                )}
              </div>

              {/* Stop card */}
              <button
                onClick={() => stop.business && router.push(`/business/${stop.business.id}`)}
                className="flex-1 bg-surface-container-lowest rounded-2xl p-4 shadow-sm mb-3 flex items-center gap-3 text-left active:scale-[0.98] transition-all"
              >
                {stop.business?.cover_image_url ? (
                  <img src={stop.business.cover_image_url} alt="" className="w-14 h-14 rounded-xl object-cover shrink-0" />
                ) : (
                  <div className="w-14 h-14 rounded-xl bg-surface-container flex items-center justify-center shrink-0">
                    <span className="material-symbols-outlined text-on-surface-variant/40 text-2xl">store</span>
                  </div>
                )}
                <div className="flex-1 min-w-0">
                  <p className="font-bold text-on-surface text-sm truncate">{stop.business?.name ?? 'Unknown'}</p>
                  <p className="text-on-surface-variant text-xs capitalize">{(stop.business?.category as { slug: string } | null)?.slug ?? ''}</p>
                  {stop.estimated_time_min && (
                    <p className="text-on-surface-variant/50 text-[10px] mt-0.5">{stop.estimated_time_min} min</p>
                  )}
                </div>
                <span className="material-symbols-outlined text-on-surface-variant/30">chevron_right</span>
              </button>
            </div>
          ))}
        </div>
      </main>

      {/* Bottom Actions */}
      <footer className="fixed bottom-0 w-full bg-surface/90 backdrop-blur-md px-6 py-6 border-t border-outline-variant/5">
        <div className="flex gap-3 max-w-lg mx-auto">
          {googleMapsUrl && (
            <a
              href={googleMapsUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="flex-1 bg-primary-container text-on-primary-container font-display font-extrabold text-base h-14 rounded-full shadow-xl shadow-primary/20 flex items-center justify-center gap-2 active:scale-95 transition-all"
            >
              <span className="material-symbols-outlined">navigation</span>
              Start Navigation
            </a>
          )}
          <a
            href={googleMapsUrl ?? '#'}
            target="_blank"
            rel="noopener noreferrer"
            className="bg-on-secondary-fixed text-white font-bold text-sm h-14 px-5 rounded-full flex items-center justify-center gap-2 active:scale-95 transition-all"
          >
            <span className="material-symbols-outlined text-lg">open_in_new</span>
            Maps
          </a>
        </div>
      </footer>
    </div>
  );
}
