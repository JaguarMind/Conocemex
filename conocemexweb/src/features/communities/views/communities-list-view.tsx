'use client';

import { useRouter } from 'next/navigation';
import { useCommunitiesViewModel } from '../viewmodels/use-communities-viewmodel';
import { cn } from '@/core/utils/cn';

export function CommunitiesListView() {
  const router = useRouter();
  const vm = useCommunitiesViewModel();

  return (
    <div className="bg-surface min-h-screen pb-28">
      {/* Header */}
      <header className="fixed top-0 w-full z-50 bg-white/80 backdrop-blur-xl shadow-xl shadow-on-surface/5 flex items-center justify-between px-6 h-16">
        <div className="flex items-center gap-3">
          <button onClick={() => router.back()} className="p-2 hover:bg-surface-container-low rounded-full transition-colors">
            <span className="material-symbols-outlined text-on-surface">arrow_back</span>
          </button>
          <h1 className="font-display text-xl font-bold text-on-surface tracking-tight">Communities</h1>
        </div>
        <button className="p-2 hover:bg-surface-container-low rounded-full transition-colors">
          <span className="material-symbols-outlined text-on-surface">mail</span>
        </button>
      </header>

      <main className="pt-20 px-5">
        {/* Direct Chats placeholder */}
        <section className="mb-6">
          <p className="text-[11px] font-black text-on-surface-variant/50 uppercase tracking-widest mb-3">Direct Chats</p>
          <div className="bg-surface-container-lowest rounded-2xl p-5 shadow-sm text-center">
            <span className="material-symbols-outlined text-3xl text-on-surface-variant/30 mb-2">chat</span>
            <p className="text-on-surface-variant text-sm font-medium">Coming soon</p>
            <p className="text-on-surface-variant/50 text-xs">Client chat requests</p>
          </div>
        </section>

        {/* My Communities */}
        <section>
          <p className="text-[11px] font-black text-on-surface-variant/50 uppercase tracking-widest mb-3">My Communities</p>

          {/* Join by code */}
          <button
            onClick={() => vm.setShowJoin(true)}
            className="w-full bg-surface-container-lowest rounded-2xl p-4 shadow-sm flex items-center gap-4 mb-3 active:scale-[0.98] transition-all"
          >
            <div className="w-10 h-10 bg-primary-container/20 rounded-full flex items-center justify-center">
              <span className="material-symbols-outlined text-primary text-lg">link</span>
            </div>
            <div className="text-left">
              <p className="font-bold text-on-surface text-sm">Join with invite code</p>
              <p className="text-on-surface-variant text-xs">Enter a community code</p>
            </div>
            <span className="material-symbols-outlined text-on-surface-variant/40 ml-auto">chevron_right</span>
          </button>

          {/* Loading */}
          {vm.isLoading && (
            <div className="flex items-center justify-center py-10">
              <div className="w-8 h-8 border-2 border-surface-container border-t-primary-container rounded-full animate-spin" />
            </div>
          )}

          {/* Community list */}
          {!vm.isLoading && vm.communities.map((c) => (
            <button
              key={c.id}
              onClick={() => router.push(`/community/${c.id}?name=${encodeURIComponent(c.name)}`)}
              className="w-full bg-surface-container-lowest rounded-2xl p-4 shadow-sm flex items-center gap-4 mb-3 active:scale-[0.98] transition-all text-left"
            >
              <div className="w-10 h-10 bg-secondary-container/30 rounded-full flex items-center justify-center">
                <span className="material-symbols-outlined text-on-secondary-container text-lg">group</span>
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2">
                  <p className="font-bold text-on-surface text-sm truncate">{c.name}</p>
                  <span className={cn('text-[10px] font-bold px-2 py-0.5 rounded-full uppercase',
                    c.my_role === 'admin' ? 'bg-primary-container/20 text-primary' : 'bg-surface-container text-on-surface-variant')}>
                    {c.my_role}
                  </span>
                </div>
                <p className="text-on-surface-variant text-xs truncate">{c.description ?? 'No description'}</p>
                <p className="text-on-surface-variant/50 text-[10px] mt-0.5">{c.member_count} members</p>
              </div>
              <span className="material-symbols-outlined text-on-surface-variant/40">chevron_right</span>
            </button>
          ))}

          {!vm.isLoading && vm.communities.length === 0 && (
            <div className="text-center py-10">
              <span className="material-symbols-outlined text-4xl text-on-surface-variant/30 mb-2">group_off</span>
              <p className="text-on-surface-variant text-sm">No communities yet</p>
            </div>
          )}
        </section>
      </main>

      {/* FAB — Create Community */}
      <button
        onClick={() => vm.setShowCreate(true)}
        className="fixed bottom-24 right-5 w-14 h-14 bg-primary-container text-on-primary-container rounded-full shadow-xl shadow-primary/20 flex items-center justify-center active:scale-90 transition-all z-40"
      >
        <span className="material-symbols-outlined text-2xl">add</span>
      </button>

      {/* Join Modal */}
      {vm.showJoin && (
        <div className="fixed inset-0 z-60 flex items-center justify-center p-4">
          <div className="fixed inset-0 bg-on-secondary-fixed/40 backdrop-blur-sm" onClick={() => vm.setShowJoin(false)} />
          <div className="relative z-10 w-full max-w-sm rounded-2xl bg-surface-container-lowest p-6 shadow-(--shadow-elevated)">
            <h2 className="text-xl font-display font-bold text-on-surface mb-4">Join Community</h2>
            <input
              value={vm.joinCode}
              onChange={(e) => vm.setJoinCode(e.target.value)}
              placeholder="Enter invite code..."
              className="w-full bg-surface-container-low rounded-xl px-4 py-3 text-on-surface border-none focus:ring-2 focus:ring-primary-container outline-none mb-3"
            />
            {vm.error && <p className="text-tertiary text-xs font-semibold mb-3">{vm.error}</p>}
            <button
              onClick={vm.joinByCode}
              disabled={vm.isJoining || !vm.joinCode.trim()}
              className="w-full bg-primary-container text-on-primary-container py-3 rounded-full font-bold active:scale-95 transition-all disabled:opacity-50"
            >
              {vm.isJoining ? 'Joining...' : 'Join'}
            </button>
          </div>
        </div>
      )}

      {/* Create Modal */}
      {vm.showCreate && (
        <div className="fixed inset-0 z-60 flex items-center justify-center p-4">
          <div className="fixed inset-0 bg-on-secondary-fixed/40 backdrop-blur-sm" onClick={() => vm.setShowCreate(false)} />
          <div className="relative z-10 w-full max-w-sm rounded-2xl bg-surface-container-lowest p-6 shadow-(--shadow-elevated)">
            <h2 className="text-xl font-display font-bold text-on-surface mb-4">Create Community</h2>
            <input
              value={vm.createName}
              onChange={(e) => vm.setCreateName(e.target.value)}
              placeholder="Community name..."
              className="w-full bg-surface-container-low rounded-xl px-4 py-3 text-on-surface border-none focus:ring-2 focus:ring-primary-container outline-none mb-3"
            />
            <textarea
              value={vm.createDesc}
              onChange={(e) => vm.setCreateDesc(e.target.value)}
              placeholder="Description (optional)..."
              className="w-full bg-surface-container-low rounded-xl px-4 py-3 text-on-surface border-none focus:ring-2 focus:ring-primary-container outline-none resize-none mb-3"
              rows={3}
            />
            <button
              onClick={vm.createCommunity}
              disabled={vm.isCreating || !vm.createName.trim()}
              className="w-full bg-primary-container text-on-primary-container py-3 rounded-full font-bold active:scale-95 transition-all disabled:opacity-50"
            >
              {vm.isCreating ? 'Creating...' : 'Create'}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
