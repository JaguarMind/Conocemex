'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useState, useEffect, useCallback, useRef } from 'react';
import { APIProvider, Map, AdvancedMarker, useMap } from '@vis.gl/react-google-maps';
import { env } from '@/core/config/env';
import { useGeolocation } from '@/core/hooks/use-geolocation';
import { authService } from '@/core/services/auth.service';
import { getBusinessById, MOCK_BUSINESSES } from '@/core/data/mock-businesses';
import { cn } from '@/core/utils/cn';
import type { BusinessCategory } from '@/core/types/common.types';

const DEFAULT_ORIGIN = { lat: 19.4326, lng: -99.1370 };
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const TRAVEL_MODES = [
  { id: 'WALKING', icon: 'directions_walk', label: 'Walk' },
  { id: 'DRIVING', icon: 'directions_car', label: 'Drive' },
  { id: 'TRANSIT', icon: 'directions_transit', label: 'Transit' },
] as const;

type TravelModeId = (typeof TRAVEL_MODES)[number]['id'];

const CATEGORY_ICONS: Record<BusinessCategory, string> = {
  restaurant: 'restaurant',
  crafts: 'palette',
  lodging: 'hotel',
  entertainment: 'theater_comedy',
  shopping: 'shopping_bag',
  services: 'build',
};

interface DestinationInfo {
  name: string;
  lat: number;
  lng: number;
  id: string;
}

function DirectionsRenderer({
  origin,
  destination,
  travelMode,
  onDirectionsLoaded,
}: {
  origin: google.maps.LatLngLiteral;
  destination: google.maps.LatLngLiteral;
  travelMode: TravelModeId;
  onDirectionsLoaded: (result: google.maps.DirectionsResult) => void;
}) {
  const map = useMap();
  const rendererRef = useRef<google.maps.DirectionsRenderer | null>(null);

  useEffect(() => {
    if (!map) return;

    const directionsService = new google.maps.DirectionsService();

    if (!rendererRef.current) {
      rendererRef.current = new google.maps.DirectionsRenderer({
        suppressMarkers: true,
        polylineOptions: { strokeColor: '#00DF5F', strokeWeight: 6, strokeOpacity: 0.9 },
      });
    }

    rendererRef.current.setMap(map);
    const mode = google.maps.TravelMode[travelMode];

    directionsService.route(
      { origin, destination, travelMode: mode },
      (result, status) => {
        if (status === google.maps.DirectionsStatus.OK && result) {
          rendererRef.current?.setDirections(result);
          onDirectionsLoaded(result);
          const bounds = result.routes[0]?.bounds;
          if (bounds && map) {
            map.fitBounds(bounds, { top: 120, bottom: 280, left: 40, right: 80 });
          }
        }
      },
    );

    return () => { rendererRef.current?.setMap(null); };
  }, [map, origin, destination, travelMode, onDirectionsLoaded]);

  return null;
}

export function RouteNavigationView() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const { coordinates } = useGeolocation();

  const businessId = searchParams.get('businessId');

  const [dest, setDest] = useState<DestinationInfo | null>(null);
  const [isLoadingDest, setIsLoadingDest] = useState(true);
  const [travelMode, setTravelMode] = useState<TravelModeId>('DRIVING');
  const [directionsInfo, setDirectionsInfo] = useState<{
    distance: string; duration: string; instruction: string;
  } | null>(null);

  // Load destination — from mock or Supabase
  useEffect(() => {
    async function loadDestination() {
      if (!businessId) {
        const fallback = MOCK_BUSINESSES[0];
        setDest({ name: fallback.name, lat: fallback.coordinates.latitude, lng: fallback.coordinates.longitude, id: fallback.id });
        setIsLoadingDest(false);
        return;
      }

      // Try mock first
      const mock = getBusinessById(businessId);
      if (mock) {
        setDest({ name: mock.name, lat: mock.coordinates.latitude, lng: mock.coordinates.longitude, id: mock.id });
        setIsLoadingDest(false);
        return;
      }

      // If UUID, fetch from Supabase
      if (UUID_REGEX.test(businessId)) {
        try {
          const supabase = authService.client;
          const { data, error } = await supabase
            .from('businesses')
            .select('id, name, latitude, longitude')
            .eq('id', businessId)
            .single();

          if (!error && data) {
            setDest({ name: data.name, lat: data.latitude, lng: data.longitude, id: data.id });
            setIsLoadingDest(false);
            return;
          }
        } catch {
          // fallthrough
        }
      }

      // Ultimate fallback
      setDest({ name: 'Destination', lat: 19.4320, lng: -99.1330, id: businessId });
      setIsLoadingDest(false);
    }

    loadDestination();
  }, [businessId]);

  const origin = coordinates
    ? { lat: coordinates.latitude, lng: coordinates.longitude }
    : DEFAULT_ORIGIN;

  const destination = dest ? { lat: dest.lat, lng: dest.lng } : { lat: 19.4320, lng: -99.1330 };
  const destinationName = dest?.name ?? 'Loading...';

  const handleDirectionsLoaded = useCallback((result: google.maps.DirectionsResult) => {
    const leg = result.routes[0]?.legs[0];
    if (leg) {
      setDirectionsInfo({
        distance: leg.distance?.text ?? '',
        duration: leg.duration?.text ?? '',
        instruction: leg.steps[0]?.instructions?.replace(/<[^>]*>/g, '') ?? 'Head towards destination',
      });
    }
  }, []);

  const modeLabel = travelMode === 'WALKING' ? 'walk' : travelMode === 'DRIVING' ? 'drive' : 'transit';

  if (isLoadingDest) {
    return (
      <div className="fixed inset-0 flex items-center justify-center bg-background">
        <div className="w-10 h-10 border-2 border-surface-container border-t-primary-container rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="fixed inset-0 font-body text-on-background pointer-events-none">
      {/* Google Map */}
      <div className="absolute inset-0 z-10 pointer-events-auto">
        <APIProvider apiKey={env.GOOGLE_MAPS_KEY}>
          <Map
            defaultCenter={destination}
            defaultZoom={14}
            gestureHandling="greedy"
            disableDefaultUI
            mapId="DEMO_MAP_ID"
            className="w-full h-full"
          >
            <DirectionsRenderer origin={origin} destination={destination} travelMode={travelMode} onDirectionsLoaded={handleDirectionsLoaded} />

            <AdvancedMarker position={origin}>
              <div className="relative flex items-center justify-center">
                <div className="absolute w-12 h-12 bg-primary-container/30 rounded-full animate-ping" />
                <div className="w-6 h-6 bg-primary-container rounded-full border-4 border-white shadow-lg" />
              </div>
            </AdvancedMarker>

            <AdvancedMarker position={destination}>
              <div className="flex flex-col items-center">
                <div className="bg-primary-container text-on-primary-container px-3 py-1 rounded-full text-xs font-bold mb-1 shadow-md max-w-40 truncate">
                  {destinationName}
                </div>
                <span className="material-symbols-outlined text-primary-container text-4xl drop-shadow-md" style={{ fontVariationSettings: '"FILL" 1' }}>
                  location_on
                </span>
              </div>
            </AdvancedMarker>
          </Map>
        </APIProvider>
      </div>

      {/* Instruction Card */}
      <div className="fixed top-0 left-0 w-full px-6 pt-8 z-20 flex justify-center pointer-events-none">
        <div className="bg-on-secondary-fixed text-white rounded-xl px-6 py-4 flex items-center gap-4 w-full max-w-md shadow-[0_8px_32px_0_rgba(0,31,58,0.25)] border border-white/10 backdrop-blur-md pointer-events-auto">
          <div className="bg-primary-container text-on-primary-container p-2 rounded-lg flex items-center justify-center">
            <span className="material-symbols-outlined text-2xl font-bold">
              {travelMode === 'WALKING' ? 'turn_left' : travelMode === 'DRIVING' ? 'directions_car' : 'directions_transit'}
            </span>
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-white/70 text-[10px] font-bold uppercase tracking-wider">Instruction</p>
            <h1 className="text-base font-display font-extrabold tracking-tight truncate">
              {directionsInfo?.instruction ?? 'Calculating route...'}
            </h1>
          </div>
          <div className="text-right shrink-0">
            <p className="text-primary-container text-xl font-display font-black tracking-tighter">
              {directionsInfo?.distance ?? '...'}
            </p>
          </div>
        </div>
      </div>

      {/* Travel Mode + Controls */}
      <div className="fixed right-6 top-1/2 -translate-y-1/2 flex flex-col gap-3 z-20 pointer-events-auto">
        {TRAVEL_MODES.map((mode) => (
          <button key={mode.id} onClick={() => setTravelMode(mode.id)}
            className={cn('w-12 h-12 rounded-full shadow-lg flex items-center justify-center transition-all active:scale-90',
              travelMode === mode.id ? 'bg-primary-container text-on-primary-container' : 'bg-white/90 backdrop-blur-md text-on-secondary-fixed hover:bg-white')}>
            <span className="material-symbols-outlined">{mode.icon}</span>
          </button>
        ))}
        <div className="h-px" />
        <button className="w-12 h-12 bg-white/90 backdrop-blur-md rounded-full shadow-lg flex items-center justify-center text-on-secondary-fixed hover:bg-white active:scale-90 transition-all">
          <span className="material-symbols-outlined">my_location</span>
        </button>
      </div>

      {/* Bottom Sheet */}
      <div className="fixed bottom-0 left-0 w-full z-20 pointer-events-none">
        <div className="bg-surface-container-lowest rounded-t-xl px-8 pt-8 pb-10 shadow-[0_-12px_48px_0_rgba(0,31,58,0.12)] pointer-events-auto">
          <div className="absolute top-3 left-1/2 -translate-x-1/2 w-12 h-1 bg-surface-container-highest rounded-full" />
          <div className="flex justify-between items-start mb-6">
            <div className="flex-1">
              <h2
                onClick={() => router.push(`/business/${dest?.id ?? businessId}`)}
                className="text-on-secondary-fixed text-2xl font-display font-extrabold tracking-tight cursor-pointer hover:text-primary transition-colors"
              >
                {destinationName}
              </h2>
              <div className="flex items-center gap-2 mt-1">
                <span className="material-symbols-outlined text-primary-container text-sm" style={{ fontVariationSettings: '"FILL" 1' }}>
                  {travelMode === 'WALKING' ? 'directions_walk' : travelMode === 'DRIVING' ? 'directions_car' : 'directions_transit'}
                </span>
                <p className="text-on-surface-variant font-medium text-sm">
                  {directionsInfo ? `${directionsInfo.duration} ${modeLabel} • ${directionsInfo.distance} remaining` : 'Calculating...'}
                </p>
              </div>
            </div>
            <span className="bg-primary-container/10 text-primary-container px-3 py-1 rounded-full text-xs font-bold">LIVE</span>
          </div>
          <div className="flex flex-col gap-3">
            <div className="flex gap-3">
              <button onClick={() => router.push('/pay')}
                className="flex-1 bg-primary-container text-on-primary-container py-4 rounded-xl font-display font-black text-base tracking-tight shadow-[0_8px_20px_-4px_rgba(0,223,95,0.4)] hover:brightness-105 active:scale-[0.98] transition-all flex items-center justify-center gap-2">
                Arrive &amp; Pay
                <span className="material-symbols-outlined text-lg">payments</span>
              </button>
              <a href={`https://www.google.com/maps/dir/?api=1&destination=${destination.lat},${destination.lng}&travelmode=${travelMode.toLowerCase()}`}
                target="_blank" rel="noopener noreferrer"
                className="bg-on-secondary-fixed text-white px-5 py-4 rounded-xl font-bold text-sm flex items-center justify-center gap-2 active:scale-[0.98] transition-all">
                <span className="material-symbols-outlined text-lg">open_in_new</span>
                Maps
              </a>
            </div>
            <button onClick={() => router.push('/map')} className="w-full py-2 flex items-center justify-center">
              <span className="text-on-surface-variant/60 font-semibold text-sm hover:text-on-surface transition-colors cursor-pointer">Cancel Route</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
