import type { BusinessCategory } from '@/core/types/common.types';

export type TravelCompanion = 'solo' | 'family' | 'couple' | 'friends';
export type DietaryRestriction = 'none' | 'vegetarian' | 'vegan' | 'gluten_free' | 'halal' | 'kosher';
export type BudgetRange = 'low' | 'medium' | 'high';

export interface InterestOption {
  id: string;
  label: string;
  emoji: string;
  category: BusinessCategory;
}

export interface OnboardingData {
  companion: TravelCompanion | null;
  nationality: string;
  language: string;
  dietaryRestriction: DietaryRestriction;
  budgetRange: BudgetRange;
  interests: string[];
}

export interface OnboardingViewState {
  step: number;
  data: OnboardingData;
  isSubmitting: boolean;
  error: string | null;
}

export const COMPANION_OPTIONS: { id: TravelCompanion; label: string }[] = [
  { id: 'solo', label: 'Solo' },
  { id: 'family', label: 'Family' },
  { id: 'couple', label: 'Couple' },
  { id: 'friends', label: 'Friends' },
];

export const INTEREST_OPTIONS: InterestOption[] = [
  { id: 'street-food', label: 'Street Food', emoji: '🌮', category: 'restaurant' },
  { id: 'culture', label: 'Culture', emoji: '🏛️', category: 'entertainment' },
  { id: 'local-crafts', label: 'Local Crafts', emoji: '🏺', category: 'crafts' },
  { id: 'nightlife', label: 'Nightlife', emoji: '🍻', category: 'entertainment' },
  { id: 'shopping', label: 'Shopping', emoji: '👕', category: 'shopping' },
];

export const NATIONALITY_OPTIONS = [
  'United States', 'Canada', 'Mexico', 'Brazil', 'United Kingdom',
  'France', 'Germany', 'Spain', 'Italy', 'Argentina', 'Colombia',
  'Japan', 'South Korea', 'Australia', 'Other',
];

export const LANGUAGE_OPTIONS = [
  { code: 'es', label: 'Español', flag: '🇲🇽' },
  { code: 'en', label: 'English', flag: '🇺🇸' },
  { code: 'pt', label: 'Português', flag: '🇧🇷' },
  { code: 'fr', label: 'Français', flag: '🇫🇷' },
];

export const DIETARY_OPTIONS: { id: DietaryRestriction; label: string; emoji: string }[] = [
  { id: 'none', label: 'No restrictions', emoji: '🍽️' },
  { id: 'vegetarian', label: 'Vegetarian', emoji: '🥬' },
  { id: 'vegan', label: 'Vegan', emoji: '🌱' },
  { id: 'gluten_free', label: 'Gluten Free', emoji: '🌾' },
  { id: 'halal', label: 'Halal', emoji: '🥩' },
  { id: 'kosher', label: 'Kosher', emoji: '✡️' },
];

export const BUDGET_OPTIONS: { id: BudgetRange; label: string; emoji: string; desc: string }[] = [
  { id: 'low', label: 'Budget', emoji: '💰', desc: 'Street food & local spots' },
  { id: 'medium', label: 'Moderate', emoji: '💰💰', desc: 'Casual dining & experiences' },
  { id: 'high', label: 'Premium', emoji: '💰💰💰', desc: 'Fine dining & VIP' },
];
