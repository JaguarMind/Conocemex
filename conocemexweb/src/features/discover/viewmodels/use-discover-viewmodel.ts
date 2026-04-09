'use client';

import { useState, useEffect, useCallback, useRef } from 'react';
import { discoverService } from '../services/discover.service';
import type { DishCard, DiscoverFilter } from '../models/discover.types';

export function useDiscoverViewModel() {
  const [dishes, setDishes] = useState<DishCard[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [activeFilter, setActiveFilter] = useState<DiscoverFilter>('all');
  const [isLoading, setIsLoading] = useState(true);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const load = useCallback(async (query?: string) => {
    setIsLoading(true);
    const data = await discoverService.getDishes(query);
    setDishes(data);
    setIsLoading(false);
  }, []);

  // Initial load
  useEffect(() => { load(); }, [load]);

  // Debounced search
  useEffect(() => {
    if (timerRef.current) clearTimeout(timerRef.current);
    timerRef.current = setTimeout(() => load(searchQuery), 300);
    return () => { if (timerRef.current) clearTimeout(timerRef.current); };
  }, [searchQuery, load]);

  const sortedDishes = [...dishes].sort((a, b) => {
    if (activeFilter === 'price') return a.priceMxn - b.priceMxn;
    if (activeFilter === 'distance') return a.distanceM - b.distanceM;
    return 0;
  });

  const toggleFavorite = useCallback((id: string) => {
    setDishes((prev) =>
      prev.map((d) => (d.id === id ? { ...d, isFavorite: !d.isFavorite } : d)),
    );
  }, []);

  return {
    dishes: sortedDishes,
    searchQuery,
    activeFilter,
    isLoading,
    setSearchQuery,
    setActiveFilter,
    toggleFavorite,
  };
}
