'use client';

import { useState, useCallback, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { routesService } from '../services/routes.service';
import type { StopDraft, RouteType } from '../models/routes.types';

export function useCreateRoute() {
  const router = useRouter();
  const [name, setName] = useState('');
  const [type, setType] = useState<RouteType>('mixta');
  const [stops, setStops] = useState<StopDraft[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [searchResults, setSearchResults] = useState<StopDraft[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const [isCreating, setIsCreating] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Debounced search
  const search = useCallback((query: string) => {
    setSearchQuery(query);
    if (!query.trim()) { setSearchResults([]); return; }

    if (timerRef.current) clearTimeout(timerRef.current);
    timerRef.current = setTimeout(async () => {
      setIsSearching(true);
      const results = await routesService.searchBusinesses(query);
      setSearchResults(results.map((b) => ({
        businessId: b.id,
        businessName: b.name,
        imageUrl: b.cover_image_url,
        categorySlug: (b.category as { slug: string } | null)?.slug ?? 'services',
        lat: b.latitude,
        lng: b.longitude,
        estimatedTimeMin: null,
      })));
      setIsSearching(false);
    }, 300);
  }, []);

  const addStop = useCallback((stop: StopDraft) => {
    if (stops.find((s) => s.businessId === stop.businessId)) return;
    setStops((prev) => [...prev, stop]);
    setSearchQuery('');
    setSearchResults([]);
  }, [stops]);

  const removeStop = useCallback((businessId: string) => {
    setStops((prev) => prev.filter((s) => s.businessId !== businessId));
  }, []);

  const moveStop = useCallback((index: number, direction: 'up' | 'down') => {
    setStops((prev) => {
      const arr = [...prev];
      const newIndex = direction === 'up' ? index - 1 : index + 1;
      if (newIndex < 0 || newIndex >= arr.length) return prev;
      [arr[index], arr[newIndex]] = [arr[newIndex], arr[index]];
      return arr;
    });
  }, []);

  const setStopTime = useCallback((index: number, minutes: number | null) => {
    setStops((prev) => prev.map((s, i) => i === index ? { ...s, estimatedTimeMin: minutes } : s));
  }, []);

  const createRoute = useCallback(async () => {
    if (!name.trim()) { setError('Enter a route name'); return; }
    if (stops.length < 2) { setError('Add at least 2 stops'); return; }

    setIsCreating(true);
    setError(null);

    const totalTime = stops.reduce((sum, s) => sum + (s.estimatedTimeMin ?? 15), 0);

    const route = await routesService.createRoute({
      name: name.trim(),
      type,
      totalTimeMin: totalTime,
      stops: stops.map((s) => ({ businessId: s.businessId, estimatedTimeMin: s.estimatedTimeMin ?? undefined })),
    });

    if (route) {
      router.push(`/routes/${route.id}`);
    } else {
      setError('Failed to create route');
      setIsCreating(false);
    }
  }, [name, type, stops, router]);

  return {
    name, setName, type, setType,
    stops, addStop, removeStop, moveStop, setStopTime,
    searchQuery, search, searchResults, isSearching,
    isCreating, error, createRoute,
  };
}
