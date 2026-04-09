import type { Coordinates } from '@/core/types/common.types';

export const geolocationService = {
  async getCurrentPosition(): Promise<Coordinates> {
    return new Promise((resolve, reject) => {
      if (!navigator.geolocation) {
        reject(new Error('Geolocation is not supported by this browser'));
        return;
      }

      navigator.geolocation.getCurrentPosition(
        (position) => {
          resolve({
            latitude: position.coords.latitude,
            longitude: position.coords.longitude,
          });
        },
        (error) => {
          reject(new Error(error.message));
        },
        { enableHighAccuracy: true, timeout: 10000, maximumAge: 60000 },
      );
    });
  },

  watchPosition(
    onUpdate: (coords: Coordinates) => void,
    onError?: (error: Error) => void,
  ): number | null {
    if (!navigator.geolocation) return null;

    return navigator.geolocation.watchPosition(
      (position) => {
        onUpdate({
          latitude: position.coords.latitude,
          longitude: position.coords.longitude,
        });
      },
      (error) => onError?.(new Error(error.message)),
      { enableHighAccuracy: true },
    );
  },

  clearWatch(watchId: number) {
    navigator.geolocation.clearWatch(watchId);
  },
};
