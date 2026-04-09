export interface DashboardStats {
  totalBusinesses: number;
  activationRate: number;
  totalVisits: number;
  averageVisitsPerBusiness: number;
  equityCoefficient: number;
  trainingAdoption: number;
}

export interface ZoneMetrics {
  zone: string;
  businessCount: number;
  visitCount: number;
  equityIndex: number;
}

export interface DashboardViewState {
  stats: DashboardStats | null;
  zones: ZoneMetrics[];
  isLoading: boolean;
  error: string | null;
}
