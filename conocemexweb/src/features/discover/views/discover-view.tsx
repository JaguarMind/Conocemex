'use client';

import { useRouter } from 'next/navigation';
import { useTranslation } from 'react-i18next';
import { useDiscoverViewModel } from '../viewmodels/use-discover-viewmodel';
import { formatCurrency } from '@/core/utils/format';
import { cn } from '@/core/utils/cn';
import type { DiscoverFilter } from '../models/discover.types';

const CATEGORY_ICONS: Record<string, string> = {
  gastronomia: 'restaurant',
  artesanias: 'palette',
  hospedaje: 'hotel',
  entretenimiento: 'theater_comedy',
  compras: 'shopping_bag',
  tours: 'tour',
  transporte: 'directions_bus',
  bienestar: 'spa',
};

const FILTERS: { id: DiscoverFilter; labelKey: string; icon?: string }[] = [
  { id: 'location', labelKey: 'discover.location', icon: 'location_on' },
  { id: 'distance', labelKey: 'discover.distance' },
  { id: 'price', labelKey: 'discover.price' },
  { id: 'category', labelKey: 'discover.category' },
];

export function DiscoverView() {
  const router = useRouter();
  const { t } = useTranslation();
  const vm = useDiscoverViewModel();

  return (
    <div className="bg-surface text-on-surface min-h-screen">
      {/* Header — glass white */}
      <header className="fixed top-0 w-full z-50 bg-white/80 backdrop-blur-xl shadow-xl shadow-on-surface/5">
        <div className="flex items-center justify-between px-6 h-16 w-full">
          <button
            onClick={() => router.back()}
            className="text-on-surface hover:bg-surface-container-low transition-colors p-2 rounded-full active:scale-90"
          >
            <span className="material-symbols-outlined">arrow_back</span>
          </button>
          <h1 className="text-xl font-bold text-on-surface font-display tracking-tight">
            {t('discover.title')}
          </h1>
          <button className="text-on-surface hover:bg-surface-container-low transition-colors p-2 rounded-full active:scale-90">
            <span className="material-symbols-outlined">search</span>
          </button>
        </div>

        {/* Search Bar */}
        <div className="px-6 pb-4">
          <input
            type="text"
            value={vm.searchQuery}
            onChange={(e) => vm.setSearchQuery(e.target.value)}
            className="w-full bg-surface-container-low border-none rounded-full py-3 px-5 text-on-surface placeholder-on-surface-variant/50 focus:ring-2 focus:ring-primary-container transition-all outline-none text-sm"
            placeholder={t('discover.searchPlaceholder')}
          />
        </div>
      </header>

      <main className="pt-36 pb-28">
        {/* Filter Chips */}
        <section className="px-4 mb-6 flex gap-2 overflow-x-auto hide-scrollbar">
          {FILTERS.map((f) => (
            <button
              key={f.id}
              onClick={() => vm.setActiveFilter(vm.activeFilter === f.id ? 'all' : f.id)}
              className={cn(
                'flex items-center gap-1.5 px-4 py-2 rounded-full whitespace-nowrap font-semibold text-sm transition-all active:scale-95 shrink-0',
                vm.activeFilter === f.id
                  ? 'bg-primary-container text-on-primary-container shadow-lg shadow-primary/10'
                  : 'bg-surface-container-low text-on-secondary-fixed hover:bg-surface-container',
              )}
            >
              {f.icon && (
                <span
                  className="material-symbols-outlined text-[18px]"
                  style={{ fontVariationSettings: '"FILL" 1' }}
                >
                  {f.icon}
                </span>
              )}
              {t(f.labelKey)}
            </button>
          ))}
        </section>

        {/* Loading */}
        {vm.isLoading && (
          <div className="flex items-center justify-center py-20">
            <div className="w-8 h-8 border-2 border-surface-container border-t-primary-container rounded-full animate-spin" />
          </div>
        )}

        {/* Empty */}
        {!vm.isLoading && vm.dishes.length === 0 && (
          <div className="flex flex-col items-center justify-center py-20 text-center px-6">
            <span className="material-symbols-outlined text-5xl text-on-surface-variant/30 mb-3">restaurant</span>
            <p className="text-on-surface-variant font-medium">{t('discover.noDishes')}</p>
          </div>
        )}

        {/* Dish Grid */}
        {!vm.isLoading && vm.dishes.length > 0 && (
          <section className="px-4 grid grid-cols-2 gap-4 max-w-7xl mx-auto">
            {vm.dishes.map((dish) => (
              <div
                key={dish.id}
                onClick={() => router.push(`/business/${dish.businessId}`)}
                className="bg-surface-container-lowest rounded-2xl overflow-hidden shadow-(--shadow-ambient) group flex flex-col cursor-pointer"
              >
                {/* Image */}
                <div className="relative h-44 overflow-hidden">
                  {dish.imageUrl ? (
                    <img
                      src={dish.imageUrl}
                      alt={dish.name}
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-700"
                    />
                  ) : (
                    <div className="w-full h-full bg-surface-container flex flex-col items-center justify-center gap-2">
                      <span className="material-symbols-outlined text-5xl text-on-surface-variant/20">
                        {CATEGORY_ICONS[dish.categorySlug] ?? 'store'}
                      </span>
                      <span className="text-xs text-on-surface-variant/30 font-semibold">{dish.businessName}</span>
                    </div>
                  )}

                  {/* Local Specialty badge */}
                  {dish.isLocalSpecialty && (
                    <div className="absolute top-2 left-0 bg-tertiary text-on-tertiary px-2.5 py-1 rounded-r-full font-bold text-[10px] tracking-wide uppercase">
                      {t('discover.localSpecialty')}
                    </div>
                  )}

                  {/* Favorite button */}
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      vm.toggleFavorite(dish.id);
                    }}
                    className="absolute top-2 right-2 bg-white/30 backdrop-blur-md p-1.5 rounded-full text-primary-container hover:bg-white/50 transition-colors"
                  >
                    <span
                      className="material-symbols-outlined text-[18px]"
                      style={{ fontVariationSettings: `"FILL" ${dish.isFavorite ? 1 : 0}` }}
                    >
                      favorite
                    </span>
                  </button>

                  {/* Gradient overlay with name */}
                  <div className="absolute bottom-0 left-0 right-0 h-1/2 bg-gradient-to-t from-on-secondary-fixed/90 to-transparent flex items-end p-3">
                    <h3 className="text-white text-sm font-bold leading-tight">{dish.name}</h3>
                  </div>
                </div>

                {/* Info */}
                <div className="p-3 flex flex-col flex-grow">
                  <div className="flex justify-between items-start gap-1">
                    <div className="min-w-0">
                      <p className="text-on-secondary-fixed font-bold text-xs truncate">{dish.businessName}</p>
                      <p className="text-secondary text-[10px]">
                        {dish.distanceM > 0 ? `${(dish.distanceM / 1609).toFixed(1)} mi` : t('discover.nearby')}
                      </p>
                    </div>
                    <span className="text-primary-container font-bold text-xs shrink-0">
                      {dish.priceMxn > 0 ? formatCurrency(dish.priceMxn) : t('discover.visit')}
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </section>
        )}
      </main>
    </div>
  );
}
