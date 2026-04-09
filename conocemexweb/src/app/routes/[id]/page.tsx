'use client';

import { useParams } from 'next/navigation';
import { RouteDetailView } from '@/features/routes/views/route-detail-view';

export default function RouteDetailPage() {
  const params = useParams();
  const routeId = params.id as string;
  return <RouteDetailView routeId={routeId} />;
}
