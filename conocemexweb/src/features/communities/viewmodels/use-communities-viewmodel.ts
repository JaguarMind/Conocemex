'use client';

import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/core/hooks/use-auth';
import { communityService } from '../services/community.service';
import type { Community } from '../models/community.types';

export function useCommunitiesViewModel() {
  const { user } = useAuth();
  const [communities, setCommunities] = useState<Community[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [joinCode, setJoinCode] = useState('');
  const [isJoining, setIsJoining] = useState(false);
  const [showCreate, setShowCreate] = useState(false);
  const [showJoin, setShowJoin] = useState(false);
  const [createName, setCreateName] = useState('');
  const [createDesc, setCreateDesc] = useState('');
  const [isCreating, setIsCreating] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    if (!user?.id) return;
    setIsLoading(true);
    const data = await communityService.getMyCommunities(user.id);
    setCommunities(data);
    setIsLoading(false);
  }, [user?.id]);

  useEffect(() => { load(); }, [load]);

  const createCommunity = useCallback(async () => {
    if (!user?.id || !createName.trim()) return;
    setIsCreating(true);
    setError(null);
    const community = await communityService.createCommunity(user.id, createName.trim(), createDesc.trim() || undefined);
    if (community) {
      setCommunities((prev) => [community, ...prev]);
      setShowCreate(false);
      setCreateName('');
      setCreateDesc('');
    }
    setIsCreating(false);
  }, [user?.id, createName, createDesc]);

  const joinByCode = useCallback(async () => {
    if (!user?.id || !joinCode.trim()) return;
    setIsJoining(true);
    setError(null);
    const community = await communityService.joinByCode(user.id, joinCode.trim());
    if (community) {
      setCommunities((prev) => {
        if (prev.find((c) => c.id === community.id)) return prev;
        return [community, ...prev];
      });
      setShowJoin(false);
      setJoinCode('');
    } else {
      setError('Invalid invite code');
    }
    setIsJoining(false);
  }, [user?.id, joinCode]);

  const leaveCommunity = useCallback(async (communityId: string) => {
    if (!user?.id) return;
    await communityService.leaveCommunity(user.id, communityId);
    setCommunities((prev) => prev.filter((c) => c.id !== communityId));
  }, [user?.id]);

  return {
    communities, isLoading, error,
    joinCode, setJoinCode, isJoining, showJoin, setShowJoin, joinByCode,
    showCreate, setShowCreate, createName, setCreateName, createDesc, setCreateDesc, isCreating, createCommunity,
    leaveCommunity, refresh: load,
  };
}
