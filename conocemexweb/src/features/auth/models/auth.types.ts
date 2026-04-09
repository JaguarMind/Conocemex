export interface LoginCredentials {
  email: string;
  password: string;
}

export interface RegisterCredentials {
  fullName: string;
  email: string;
  password: string;
  acceptedTerms: boolean;
}

export interface AuthViewState {
  email: string;
  password: string;
  isLoading: boolean;
  error: string | null;
}

export interface RegisterViewState {
  fullName: string;
  email: string;
  password: string;
  acceptedTerms: boolean;
  isLoading: boolean;
  errors: {
    fullName: string | null;
    email: string | null;
    password: string | null;
    terms: string | null;
    general: string | null;
  };
}
