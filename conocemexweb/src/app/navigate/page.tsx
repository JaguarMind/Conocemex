import { Suspense } from 'react';
import { RouteNavigationView } from '@/features/route-generator/views/route-navigation-view';

export default function NavigatePage() {
  return (
    <Suspense fallback={<div className="flex items-center justify-center h-screen">Loading...</div>}>
      <RouteNavigationView />
    </Suspense>
  );
}
