import { BusinessProfileView } from '@/features/business-profile/views/business-profile-view';

export default function BusinessPage({ params }: { params: Promise<{ id: string }> }) {
  return <BusinessProfileView paramsPromise={params} />;
}
