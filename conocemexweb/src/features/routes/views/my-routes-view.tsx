'use client';

import { useRouter } from 'next/navigation';
import { useMyRoutes } from '../viewmodels/use-my-routes';
import { cn } from '@/core/utils/cn';

const TYPE_EMOJI: Record<string, string> = { gastronomica: '🌮', cultural: '🏛️', compras: '🛍️', mixta: '✨' };

export function MyRoutesView() {
  const router = useRouter();
  const { routes, isLoading, deleteRoute } = useMyRoutes();

  return (
    <div className="bg-surface min-h-screen pt-20 pb-28 px-5 max-w-lg mx-auto">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="font-display text-3xl font-extrabold text-on-surface tracking-tight">My Routes</h1>
          <p className="text-on-surface-variant text-sm mt-1">Your custom itineraries</p>
        </div>
      </div>

      {isLoading && (
        <div className="flex items-center justify-center py-20">
          <div className="w-8 h-8 border-2 border-surface-container border-t-primary-container rounded-full animate-spin" />
        </div>
      )}

      {!isLoading && routes.length === 0 && (
        <div className="flex flex-col items-center justify-center py-20 text-center">
          <span className="material-symbols-outlined text-5xl text-on-surface-variant/30 mb-3">route</span>
          <p className="text-on-surface-variant font-medium">No routes yet</p>
          <p className="text-on-surface-variant/50 text-sm mt-1">Create your first itinerary</p>
        </div>
      )}

      <div className="space-y-3 mb-6">
        {routes.map((r) => (
          <button
            key={r.id}
            onClick={() => router.push(`/routes/${r.id}`)}
            className="w-full bg-surface-container-lowest rounded-2xl p-5 shadow-sm text-left active:scale-[0.98] transition-all"
          >
            <div className="flex items-center gap-3">
              <span className="text-2xl">{TYPE_EMOJI[r.type] ?? '✨'}</span>
              <div className="flex-1 min-w-0">
                <h3 className="font-display font-bold text-on-surface truncate">{r.name}</h3>
                <div className="flex items-center gap-3 mt-1 text-xs text-on-surface-variant">
                  <span className="capitalize">{r.type}</span>
                  {r.total_estimated_time_min && (
                    <span className="flex items-center gap-1">
                      <span className="material-symbols-outlined text-[14px]">schedule</span>
                      {r.total_estimated_time_min} min
                    </span>
                  )}
                  {r.total_estimated_cost_mxn && (
                    <span className="flex items-center gap-1">
                      <span className="material-symbols-outlined text-[14px]">payments</span>
                      ${r.total_estimated_cost_mxn} MXN
                    </span>
                  )}
                </div>
              </div>
              <span className="material-symbols-outlined text-on-surface-variant/40">chevron_right</span>
            </div>
          </button>
        ))}
      </div>

      {/* FAB Create */}
      <button
        onClick={() => router.push('/routes/create')}
        className="fixed bottom-24 right-5 bg-primary-container text-on-primary-container rounded-full shadow-xl shadow-primary/20 px-6 py-4 flex items-center gap-2 active:scale-90 transition-all z-40 font-bold"
      >
        <span className="material-symbols-outlined">add</span>
        New Route
      </button>
    </div>
  );
}
