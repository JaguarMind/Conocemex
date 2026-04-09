'use client';

import { useState, useEffect } from 'react';
import { geolocationService } from '@/core/services/geolocation.service';
import type { Coordinates } from '@/core/types/common.types';

export function useGeolocation() {
  const [coordinates, setCoordinates] = useState<Coordinates | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    geolocationService
      .getCurrentPosition()
      .then((coords) => {
        setCoordinates(coords);
        setIsLoading(false);
      })
      .catch((err: Error) => {
        setError(err.message);
        setIsLoading(false);
      });
  }, []);

  return { coordinates, error, isLoading };
}
