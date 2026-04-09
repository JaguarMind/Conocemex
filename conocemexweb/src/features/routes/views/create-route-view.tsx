'use client';

import { useRouter } from 'next/navigation';
import { useCreateRoute } from '../viewmodels/use-create-route';
import { ROUTE_TYPE_OPTIONS } from '../models/routes.types';
import { cn } from '@/core/utils/cn';

export function CreateRouteView() {
  const router = useRouter();
  const vm = useCreateRoute();

  return (
    <div className="bg-surface min-h-screen">
      <header className="fixed top-0 w-full z-50 bg-white/80 backdrop-blur-xl shadow-xl shadow-on-surface/5 flex items-center gap-3 px-6 h-16">
        <button onClick={() => router.back()} className="p-2 hover:bg-surface-container-low rounded-full transition-colors">
          <span className="material-symbols-outlined text-on-surface">close</span>
        </button>
        <h1 className="font-display text-xl font-bold text-on-surface tracking-tight">Create Route</h1>
      </header>

      <main className="pt-24 pb-36 px-5 max-w-lg mx-auto">
        {/* Name */}
        <div className="mb-6">
          <label className="text-[11px] font-black text-on-surface-variant/50 uppercase tracking-widest mb-2 block">Route Name</label>
          <input
            value={vm.name}
            onChange={(e) => vm.setName(e.target.value)}
            placeholder="e.g., Zócalo Food Tour"
            className="w-full bg-surface-container-lowest rounded-xl px-5 py-4 text-on-surface font-semibold border-none focus:ring-2 focus:ring-primary-container outline-none shadow-sm"
          />
        </div>

        {/* Type */}
        <div className="mb-6">
          <label className="text-[11px] font-black text-on-surface-variant/50 uppercase tracking-widest mb-2 block">Route Type</label>
          <div className="flex gap-2 overflow-x-auto hide-scrollbar">
            {ROUTE_TYPE_OPTIONS.map((opt) => (
              <button
                key={opt.id}
                onClick={() => vm.setType(opt.id)}
                className={cn(
                  'shrink-0 flex items-center gap-2 px-5 py-3 rounded-full text-sm font-bold transition-all active:scale-95',
                  vm.type === opt.id ? 'bg-primary text-white shadow-lg' : 'bg-surface-container-lowest text-on-surface shadow-sm',
                )}
              >
                <span>{opt.emoji}</span> {opt.label}
              </button>
            ))}
          </div>
        </div>

        {/* Search & Add Stops */}
        <div className="mb-6">
          <label className="text-[11px] font-black text-on-surface-variant/50 uppercase tracking-widest mb-2 block">
            Add Stops ({vm.stops.length} added, min 2)
          </label>
          <div className="relative">
            <input
              value={vm.searchQuery}
              onChange={(e) => vm.search(e.target.value)}
              placeholder="Search businesses to add..."
              className="w-full bg-surface-container-lowest rounded-xl px-5 py-3 text-on-surface border-none focus:ring-2 focus:ring-primary-container outline-none shadow-sm text-sm"
            />
            {vm.searchQuery && vm.searchResults.length > 0 && (
              <div className="absolute top-full left-0 w-full bg-surface-container-lowest rounded-b-xl shadow-lg z-10 max-h-48 overflow-y-auto">
                {vm.searchResults.map((r) => (
                  <button
                    key={r.businessId}
                    onClick={() => vm.addStop(r)}
                    className="w-full flex items-center gap-3 px-4 py-3 hover:bg-surface-container-low text-left text-sm"
                  >
                    {r.imageUrl ? (
                      <img src={r.imageUrl} alt="" className="w-8 h-8 rounded-lg object-cover" />
                    ) : (
                      <div className="w-8 h-8 rounded-lg bg-surface-container flex items-center justify-center">
                        <span className="material-symbols-outlined text-sm text-on-surface-variant">store</span>
                      </div>
                    )}
                    <span className="font-semibold text-on-surface truncate">{r.businessName}</span>
                    <span className="material-symbols-outlined text-primary-container ml-auto">add_circle</span>
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Stops List */}
        {vm.stops.length > 0 && (
          <div className="mb-6 space-y-2">
            {vm.stops.map((stop, i) => (
              <div key={stop.businessId} className="bg-surface-container-lowest rounded-xl p-4 shadow-sm flex items-center gap-3">
                <div className="w-8 h-8 bg-primary-container/20 rounded-full flex items-center justify-center shrink-0">
                  <span className="font-display font-bold text-primary text-sm">{i + 1}</span>
                </div>
                {stop.imageUrl ? (
                  <img src={stop.imageUrl} alt="" className="w-10 h-10 rounded-lg object-cover shrink-0" />
                ) : (
                  <div className="w-10 h-10 rounded-lg bg-surface-container flex items-center justify-center shrink-0">
                    <span className="material-symbols-outlined text-on-surface-variant text-lg">store</span>
                  </div>
                )}
                <div className="flex-1 min-w-0">
                  <p className="font-bold text-on-surface text-sm truncate">{stop.businessName}</p>
                  <input
                    type="number"
                    placeholder="min"
                    value={stop.estimatedTimeMin ?? ''}
                    onChange={(e) => vm.setStopTime(i, e.target.value ? parseInt(e.target.value) : null)}
                    className="w-16 bg-surface-container-low rounded px-2 py-0.5 text-[10px] text-on-surface-variant border-none mt-0.5"
                  />
                </div>
                <div className="flex flex-col gap-1">
                  <button onClick={() => vm.moveStop(i, 'up')} disabled={i === 0} className="text-on-surface-variant/40 disabled:opacity-20">
                    <span className="material-symbols-outlined text-sm">expand_less</span>
                  </button>
                  <button onClick={() => vm.moveStop(i, 'down')} disabled={i === vm.stops.length - 1} className="text-on-surface-variant/40 disabled:opacity-20">
                    <span className="material-symbols-outlined text-sm">expand_more</span>
                  </button>
                </div>
                <button onClick={() => vm.removeStop(stop.businessId)} className="text-tertiary p-1">
                  <span className="material-symbols-outlined text-lg">close</span>
                </button>
              </div>
            ))}
          </div>
        )}

        {vm.error && <p className="text-tertiary text-sm font-semibold text-center mb-4">{vm.error}</p>}
      </main>

      <footer className="fixed bottom-0 w-full bg-surface/90 backdrop-blur-md px-6 py-6 border-t border-outline-variant/5">
        <button
          onClick={vm.createRoute}
          disabled={vm.isCreating || vm.stops.length < 2}
          className={cn(
            'w-full font-display font-extrabold text-lg h-16 rounded-full shadow-xl flex items-center justify-center gap-2 transition-all',
            vm.stops.length >= 2
              ? 'bg-primary-container text-on-primary-container shadow-primary/20 hover:scale-[1.02] active:scale-95'
              : 'bg-surface-container-high text-on-surface-variant/50 cursor-not-allowed',
          )}
        >
          {vm.isCreating ? 'Creating...' : `Create Route (${vm.stops.length} stops)`}
          <span className="material-symbols-outlined">route</span>
        </button>
      </footer>
    </div>
  );
}
