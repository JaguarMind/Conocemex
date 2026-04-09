'use client';

import { useState, useCallback, useMemo, useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { useTranslation } from 'react-i18next';
import { AdvancedMarker } from '@vis.gl/react-google-maps';
import { MapContainer } from '@/components/shared/map-container';
import { useOnboardingGuard } from '@/core/hooks/use-onboarding-guard';
import { useRecommendations } from '../viewmodels/use-recommendations';
import { searchBusinesses } from '../services/recommendation.service';
import { ContactBusinessButton } from '@/features/direct-chat/views/contact-business-button';
import { cn } from '@/core/utils/cn';
import { formatDistance } from '@/core/utils/format';
import type { RecommendationOnMap, ReasonTag } from '../models/map.types';
import type { BusinessCategory } from '@/core/types/common.types';

// ── Filter chips ──
const FILTER_CHIPS: { id: BusinessCategory | 'all'; labelKey: string; icon: string }[] = [
  { id: 'all', labelKey: 'map.all', icon: 'apps' },
  { id: 'restaurant', labelKey: 'map.categories.restaurant', icon: 'restaurant' },
  { id: 'entertainment', labelKey: 'map.categories.entertainment', icon: 'museum' },
  { id: 'shopping', labelKey: 'map.categories.shopping', icon: 'shopping_cart' },
  { id: 'crafts', labelKey: 'map.categories.crafts', icon: 'palette' },
  { id: 'lodging', labelKey: 'map.categories.lodging', icon: 'hotel' },
];

const CATEGORY_ICONS: Record<BusinessCategory, string> = {
  restaurant: 'restaurant',
  crafts: 'palette',
  lodging: 'hotel',
  entertainment: 'theater_comedy',
  shopping: 'shopping_bag',
  services: 'build',
};

const CATEGORY_TAGS: Record<BusinessCategory, string> = {
  restaurant: 'FOODIE',
  crafts: 'ARTISAN',
  lodging: 'STAY',
  entertainment: 'CULTURE',
  shopping: 'SHOPPING',
  services: 'LOCAL',
};

const MARKER_COLORS: Record<ReasonTag, { bg: string; text: string }> = {
  equity_boost: { bg: 'bg-[#16a34a]', text: 'text-white' },
  top_quality: { bg: 'bg-[#dc2626]', text: 'text-white' },
};

const ROUTE_IMAGES = [
  'https://lh3.googleusercontent.com/aida-public/AB6AXuAZ0i4bNe7pJenur8sKWzLnmATEj5Xp9jGBwt_Oe5k0ml2HOLdLIfFbTaGUSFF_c6D8ecVtkw8aZRgdLjXT4Krqa9TQEMcno6rjFlYDgAqCDpcH7Vd3_RTsF4yh5hVmJsuG80b4ZOpTBdFmXRnQLyoYs2DU28gykXUYNOsqCCWwsgLnQ0ocgJnnx1rTGdiaqplQdhKBXwnH-uExTVousl4nJ_ZbiH4EHfRVdaGtUwlWW3J6qgZPmbcH51bVPfWIkHIXu86dD49rbq7y',
  'https://lh3.googleusercontent.com/aida-public/AB6AXuB0EEL0Pk9DbjzO1e9F8j1xOxgkHFqFTdc96jafly-qPSvraOsJjOwMuOf6i2JcCKYwjyGhGNTpa0_Jrw6L5SBgY7Fjqm9FTaHZSj-Kj4g5wLMgfMU1yoY8a4sOMYkzuEGwgopjF38jyi9GlJ_ntAQi9CPot4WCbDirlCwQ2EZzcmX6sMpAyrwfwY9duC4zJv27ndY8LOEYrNvuADNHpVGSWEjiX7d35CbRwrxf2YjH0ofjzeV3f6KLJrOUhJbGZAP6IsrQrRkvNtlh',
];

// ── Recommendation Marker ──
function RecommendationMarker({
  rec,
  isSelected,
  onClick,
}: {
  rec: RecommendationOnMap;
  isSelected: boolean;
  onClick: () => void;
}) {
  const isRpcRecommended = rec.rankPosition < 50;
  const colors = isRpcRecommended
    ? MARKER_COLORS[rec.reasonTag]
    : { bg: 'bg-on-secondary-fixed', text: 'text-white' };

  return (
    <AdvancedMarker
      position={{ lat: rec.coordinates.latitude, lng: rec.coordinates.longitude }}
      onClick={onClick}
    >
      <div className="relative flex flex-col items-center cursor-pointer">
        {/* Equity boost glow — only for RPC recommendations */}
        {rec.reasonTag === 'equity_boost' && isRpcRecommended && (
          <div className="absolute -inset-1 bg-[#16a34a]/20 rounded-full animate-pulse" />
        )}
        <div
          className={cn(
            'relative p-2.5 rounded-full shadow-2xl flex items-center justify-center transition-all z-10',
            isSelected ? 'scale-125 ring-2 ring-white' : '',
            colors.bg,
            colors.text,
          )}
        >
          {rec.reasonTag === 'equity_boost' && rec.rankPosition < 50 ? (
            <span className="text-base">🌱</span>
          ) : rec.rankPosition < 50 ? (
            <span className="text-xs font-black">{rec.rankPosition}</span>
          ) : (
            <span className="material-symbols-outlined text-[16px]" style={{ fontVariationSettings: '"FILL" 1' }}>
              {CATEGORY_ICONS[rec.category]}
            </span>
          )}
        </div>
      </div>
    </AdvancedMarker>
  );
}

// ── Main Map View ──
export function MapView() {
  const router = useRouter();
  useOnboardingGuard();

  const { t } = useTranslation();
  const { recommendations, isLoading, trackVisit } = useRecommendations();
  const [activeFilter, setActiveFilter] = useState<BusinessCategory | 'all'>('all');
  const [selectedBusiness, setSelectedBusiness] = useState<RecommendationOnMap | null>(null);
  const [showRoutes, setShowRoutes] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState<RecommendationOnMap[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const searchTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const isSearchActive = searchQuery.trim().length > 0;

  // Debounced search in Supabase
  useEffect(() => {
    if (!searchQuery.trim()) {
      setSearchResults([]);
      setIsSearching(false);
      return;
    }

    setIsSearching(true);

    if (searchTimerRef.current) clearTimeout(searchTimerRef.current);

    searchTimerRef.current = setTimeout(async () => {
      const results = await searchBusinesses(searchQuery);
      setSearchResults(results);
      setIsSearching(false);
    }, 300);

    return () => {
      if (searchTimerRef.current) clearTimeout(searchTimerRef.current);
    };
  }, [searchQuery]);

  const filteredBusinesses = useMemo(() => {
    let filtered = recommendations;

    // Filter by category
    if (activeFilter !== 'all') {
      filtered = filtered.filter((b) => b.category === activeFilter);
    }

    // Filter by search query
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      filtered = filtered.filter(
        (b) =>
          b.name.toLowerCase().includes(q) ||
          b.category.toLowerCase().includes(q) ||
          b.description.es.toLowerCase().includes(q) ||
          b.description.en.toLowerCase().includes(q),
      );
    }

    return filtered;
  }, [recommendations, activeFilter, searchQuery]);

  const dynamicRoutes = useMemo(() => {
    // Prioritize equity_boost for routes
    const sorted = [...filteredBusinesses].sort((a, b) => {
      if (a.reasonTag === 'equity_boost' && b.reasonTag !== 'equity_boost') return -1;
      if (a.reasonTag !== 'equity_boost' && b.reasonTag === 'equity_boost') return 1;
      return a.rankPosition - b.rankPosition;
    });
    return sorted.slice(0, 4).map((biz, i) => ({
      id: biz.id,
      name: `${biz.name} Trail`,
      tag: biz.reasonTag === 'equity_boost' ? '🌱 LOCAL' : CATEGORY_TAGS[biz.category],
      time: `${15 + i * 15} min`,
      cost: i % 2 === 0 ? `$${80 + i * 40} MXN` : 'Free',
      image: biz.imageUrl ?? biz.coverImageUrl ?? ROUTE_IMAGES[i % ROUTE_IMAGES.length],
      reasonTag: biz.reasonTag,
    }));
  }, [filteredBusinesses]);

  const handleMarkerClick = useCallback(
    (rec: RecommendationOnMap) => {
      setSelectedBusiness((prev) => (prev?.id === rec.id ? null : rec));
      trackVisit(rec.id);
    },
    [trackVisit],
  );

  return (
    <div className="relative w-full h-dvh overflow-hidden bg-background">
      {/* Google Map */}
      <div className="absolute inset-0">
        <MapContainer>
          {filteredBusinesses.map((rec) => (
            <RecommendationMarker
              key={rec.id}
              rec={rec}
              isSelected={selectedBusiness?.id === rec.id}
              onClick={() => handleMarkerClick(rec)}
            />
          ))}
        </MapContainer>
      </div>

      {/* Loading overlay */}
      {isLoading && (
        <div className="absolute inset-0 z-30 flex items-center justify-center bg-white/60 backdrop-blur-sm pointer-events-none">
          <div className="flex flex-col items-center gap-3">
            <div className="w-10 h-10 border-2 border-surface-container border-t-primary-container rounded-full animate-spin" />
            <p className="text-on-surface-variant text-sm font-medium">{t('common.findingSpots')}</p>
          </div>
        </div>
      )}

      {/* Floating Controls */}
      <div className="absolute top-18 left-0 w-full px-5 flex flex-col gap-3 pointer-events-none z-30">
        {/* Search Bar + Results Dropdown */}
        <div className="w-full pointer-events-auto relative">
          <div className={cn(
            'bg-surface-container-lowest h-14 flex items-center px-5 shadow-2xl shadow-on-secondary-fixed/5',
            searchQuery && filteredBusinesses.length > 0 ? 'rounded-t-2xl' : 'rounded-full',
          )}>
            <span className="material-symbols-outlined text-outline text-xl">search</span>
            <input
              className="bg-transparent border-none focus:ring-0 focus:outline-none w-full text-on-surface font-body ml-3 text-sm placeholder:text-on-surface-variant/50"
              placeholder={t('map.searchPlaceholder')}
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
            {searchQuery && (
              <button onClick={() => setSearchQuery('')} className="p-1 hover:bg-surface-container rounded-full transition-colors">
                <span className="material-symbols-outlined text-on-surface-variant text-lg">close</span>
              </button>
            )}
          </div>

          {/* Search Results Dropdown */}
          {isSearchActive && (
            <div className="bg-surface-container-lowest rounded-b-2xl shadow-2xl shadow-on-secondary-fixed/5 max-h-72 overflow-y-auto">
              {isSearching ? (
                <div className="px-5 py-6 flex items-center justify-center gap-3">
                  <div className="w-5 h-5 border-2 border-surface-container border-t-primary-container rounded-full animate-spin" />
                  <span className="text-on-surface-variant text-sm">{t('common.search')}...</span>
                </div>
              ) : searchResults.length === 0 ? (
                <div className="px-5 py-4 text-center text-on-surface-variant text-sm">
                  {t('map.noResults')}
                </div>
              ) : (
                searchResults.map((biz) => (
                  <button
                    key={biz.id}
                    onClick={() => {
                      setSelectedBusiness(biz);
                      setSearchQuery('');
                      trackVisit(biz.id);
                    }}
                    className="w-full flex items-center gap-3 px-5 py-3 hover:bg-surface-container-low active:bg-surface-container transition-colors text-left"
                  >
                    {biz.imageUrl || biz.coverImageUrl ? (
                      <img
                        src={biz.imageUrl ?? biz.coverImageUrl ?? ''}
                        alt={biz.name}
                        className="w-10 h-10 rounded-lg object-cover shrink-0"
                      />
                    ) : (
                      <div className="w-10 h-10 rounded-lg bg-surface-container flex items-center justify-center shrink-0">
                        <span className="material-symbols-outlined text-on-surface-variant text-lg">
                          {CATEGORY_ICONS[biz.category]}
                        </span>
                      </div>
                    )}
                    <div className="flex-1 min-w-0">
                      <p className="text-sm font-bold text-on-surface truncate">{biz.name}</p>
                      <div className="flex items-center gap-2">
                        <span className="text-xs text-on-surface-variant capitalize">{t(`map.categories.${biz.category}`)}</span>
                        {biz.rating && <span className="text-xs text-on-surface-variant">⭐ {biz.rating.toFixed(1)}</span>}
                        {biz.reasonTag === 'equity_boost' && biz.rankPosition < 50 && (
                          <span className="text-[10px] text-[#16a34a] font-bold">🌱</span>
                        )}
                      </div>
                    </div>
                    <span className="material-symbols-outlined text-on-surface-variant/40 text-lg">chevron_right</span>
                  </button>
                ))
              )}
            </div>
          )}
        </div>

        {/* Filter Chips — hidden while searching */}
        {!isSearchActive && <div className="flex gap-2 overflow-x-auto hide-scrollbar pointer-events-auto">
          {FILTER_CHIPS.map((chip) => (
            <button
              key={chip.id}
              onClick={() => {
                setActiveFilter(chip.id);
                setSelectedBusiness(null);
              }}
              className={cn(
                'px-5 py-2 rounded-full text-sm font-semibold flex items-center gap-1.5 whitespace-nowrap transition-all active:scale-95 shrink-0',
                activeFilter === chip.id
                  ? 'bg-primary-container text-on-primary-container shadow-lg shadow-primary/10'
                  : 'bg-surface-container-lowest text-on-surface-variant shadow-lg shadow-on-secondary-fixed/5',
              )}
            >
              <span className="material-symbols-outlined text-[16px]">{chip.icon}</span>
              {t(chip.labelKey)}
            </button>
          ))}
        </div>}
      </div>

      {/* Selected Business Bottom Sheet — hidden while searching */}
      {selectedBusiness && !isSearchActive && (
        <div className="absolute bottom-24 left-0 w-full z-40 px-5 animate-[slideUp_0.2s_ease-out]">
          <div className="bg-surface-container-lowest rounded-2xl p-4 shadow-2xl shadow-on-secondary-fixed/10">
            <div className="flex gap-4">
              {selectedBusiness.imageUrl || selectedBusiness.coverImageUrl ? (
                <img
                  src={selectedBusiness.imageUrl ?? selectedBusiness.coverImageUrl ?? ''}
                  alt={selectedBusiness.name}
                  className="w-20 h-20 rounded-xl object-cover shrink-0"
                />
              ) : (
                <div className="w-20 h-20 rounded-xl bg-surface-container-low flex items-center justify-center shrink-0">
                  <span className="material-symbols-outlined text-3xl text-on-surface-variant/40">
                    {CATEGORY_ICONS[selectedBusiness.category]}
                  </span>
                </div>
              )}
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <h3 className="font-display font-bold text-on-surface text-base truncate">
                    {selectedBusiness.name}
                  </h3>
                  {selectedBusiness.isVerified && (
                    <span className="material-symbols-outlined text-primary text-sm" style={{ fontVariationSettings: '"FILL" 1' }}>verified</span>
                  )}
                </div>
                <div className="flex items-center gap-2 mt-1 flex-wrap">
                  {selectedBusiness.reasonTag === 'equity_boost' && (
                    <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-[#16a34a]/10 text-[#16a34a] text-[10px] font-bold rounded-full">
                      🌱 Local discovery
                    </span>
                  )}
                  {selectedBusiness.rating && (
                    <span className="text-xs font-semibold text-on-surface">⭐ {selectedBusiness.rating.toFixed(1)}</span>
                  )}
                  <span className="text-xs text-on-surface-variant">
                    {formatDistance(selectedBusiness.distanceM)}
                  </span>
                </div>
              </div>
            </div>
            <div className="flex gap-2 mt-3">
              <button
                onClick={() => router.push(`/navigate?businessId=${selectedBusiness.id}`)}
                className="flex-1 bg-primary-container text-on-primary-container font-bold py-2.5 rounded-full text-sm active:scale-95 transition-all"
              >
                {t('common.navigate')}
              </button>
              <ContactBusinessButton businessId={selectedBusiness.id} businessName={selectedBusiness.name} variant="icon" />
              <button
                onClick={() => router.push(`/business/${selectedBusiness.id}`)}
                className="flex-1 bg-surface-container-low text-on-surface font-bold py-2.5 rounded-full text-sm active:scale-95 transition-all"
              >
                {t('common.details')}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Smart Routes toggle button */}
      {!selectedBusiness && !isSearchActive && dynamicRoutes.length > 0 && !showRoutes && (
        <button
          onClick={() => setShowRoutes(true)}
          className="absolute bottom-24 left-1/2 -translate-x-1/2 z-30 bg-on-secondary-fixed/80 backdrop-blur-md text-white px-5 py-2.5 rounded-full text-sm font-bold flex items-center gap-2 shadow-lg active:scale-95 transition-all"
        >
          <span className="material-symbols-outlined text-base">route</span>
          {t('common.showRoutes')}
          <span className="material-symbols-outlined text-base">expand_less</span>
        </button>
      )}

      {/* Smart Routes — hidden while searching */}
      {!selectedBusiness && !isSearchActive && dynamicRoutes.length > 0 && showRoutes && (
        <div className="absolute bottom-24 left-0 w-full z-30">
          <div className="px-5 mb-2 mx-5 py-2 flex justify-between items-center bg-white/90 backdrop-blur-md rounded-full shadow-sm">
            <h2 className="font-display font-bold text-on-secondary-fixed text-base tracking-tight pl-3">
              {t('map.smartRoutes')}
            </h2>
            <button
              onClick={() => setShowRoutes(false)}
              className="flex items-center gap-1 bg-on-secondary-fixed text-white px-3 py-1.5 rounded-full text-xs font-bold uppercase tracking-wider active:scale-95 transition-all shadow-md"
            >
              {t('common.hide')}
              <span className="material-symbols-outlined text-sm">expand_more</span>
            </button>
          </div>
          <div className="flex overflow-x-auto hide-scrollbar gap-3 px-5 pb-4">
            {dynamicRoutes.map((route) => (
              <div
                key={route.id}
                className="min-w-65 max-w-70 bg-surface-container-lowest rounded-2xl p-3 shadow-2xl shadow-on-secondary-fixed/10 flex flex-col gap-2.5 shrink-0"
              >
                <div className="relative h-28 w-full rounded-xl overflow-hidden">
                  <img className="w-full h-full object-cover" src={route.image} alt={route.name} />
                  <div className={cn(
                    'absolute top-2 right-2 backdrop-blur-md px-2.5 py-0.5 rounded-full',
                    route.reasonTag === 'equity_boost' ? 'bg-[#16a34a]/90' : 'bg-on-secondary-fixed/80',
                  )}>
                    <span className="text-white text-[10px] font-bold">{route.tag}</span>
                  </div>
                </div>
                <div>
                  <h3 className="font-display font-bold text-on-surface text-sm">{route.name}</h3>
                  <div className="flex items-center gap-3 mt-1.5">
                    <div className="flex items-center gap-1 text-on-surface-variant">
                      <span className="material-symbols-outlined text-[14px]">schedule</span>
                      <span className="text-xs font-medium">{route.time}</span>
                    </div>
                    <div className="flex items-center gap-1 text-on-surface-variant">
                      <span className="material-symbols-outlined text-[14px]">payments</span>
                      <span className="text-xs font-medium">{route.cost}</span>
                    </div>
                  </div>
                </div>
                <button
                  onClick={() => router.push(`/navigate?businessId=${route.id}`)}
                  className="w-full bg-primary-container text-on-primary-container font-bold py-2.5 rounded-full text-sm hover:scale-[1.02] transition-transform active:scale-95"
                >
                  {t('common.startRoute')}
                </button>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
