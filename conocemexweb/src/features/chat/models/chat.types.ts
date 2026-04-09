export interface ChatMessage {
  id: string;
  chat_id: string;
  sender_id: string;
  original_text: string;
  translated_text: string | null;
  original_language: string;
  target_language: string;
  created_at: string;
}

export interface ChatRoom {
  id: string;
  tourist_id: string;
  business_id: string;
  business_name: string;
  tourist_language: string;
  business_language: string;
  status: 'pending' | 'active' | 'closed';
  created_at: string;
}

export interface ChatSetupState {
  businessId: string;
  businessName: string;
  selectedLanguage: string;
  firstMessage: string;
  isSubmitting: boolean;
  error: string | null;
}

export interface ChatViewState {
  chatRoom: ChatRoom | null;
  messages: ChatMessage[];
  newMessage: string;
  isSending: boolean;
  isLoading: boolean;
  error: string | null;
}

export const CHAT_LANGUAGES = [
  { code: 'en', label: 'English (US)', flag: '🇺🇸' },
  { code: 'es', label: 'Español', flag: '🇲🇽' },
  { code: 'pt', label: 'Português', flag: '🇧🇷' },
  { code: 'fr', label: 'Français', flag: '🇫🇷' },
];
