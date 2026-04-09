export interface UserProfile {
  id: string;
  email: string;
  displayName: string | null;
  avatarUrl: string | null;
  isAnonymous: boolean;
}

export interface ProfileViewState {
  profile: UserProfile | null;
  isLoading: boolean;
}

export interface ProfileMenuItem {
  icon: string;
  label: string;
  href?: string;
  action?: string;
  destructive?: boolean;
}
