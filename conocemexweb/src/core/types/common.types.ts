export interface Coordinates {
  latitude: number;
  longitude: number;
}

export type Locale = 'es' | 'en';

export type BusinessCategory =
  | 'restaurant'
  | 'crafts'
  | 'lodging'
  | 'entertainment'
  | 'shopping'
  | 'services';

export interface SelectOption {
  label: string;
  value: string;
}
