'use client';

import { APIProvider, Map } from '@vis.gl/react-google-maps';
import { env } from '@/core/config/env';
import type { ReactNode } from 'react';

interface MapContainerProps {
  center?: { lat: number; lng: number };
  zoom?: number;
  className?: string;
  children?: ReactNode;
}

const DEFAULT_CENTER = { lat: 19.4326, lng: -99.1332 }; // CDMX Zocalo
const DEFAULT_ZOOM = 15;

export function MapContainer({
  center = DEFAULT_CENTER,
  zoom = DEFAULT_ZOOM,
  className = 'h-full w-full',
  children,
}: MapContainerProps) {
  if (!env.GOOGLE_MAPS_KEY) {
    return (
      <div className={`${className} bg-surface-container-low flex items-center justify-center`}>
        <p className="text-on-surface-variant text-sm">Google Maps API Key required</p>
      </div>
    );
  }

  return (
    <APIProvider apiKey={env.GOOGLE_MAPS_KEY}>
      <Map
        defaultCenter={center}
        defaultZoom={zoom}
        className={className}
        gestureHandling="greedy"
        disableDefaultUI={false}
        zoomControl={true}
        mapTypeControl={false}
        streetViewControl={false}
        fullscreenControl={false}
        mapId="DEMO_MAP_ID"
      >
        {children}
      </Map>
    </APIProvider>
  );
}
