import { authService } from '@/core/services/auth.service';

// Map UI interest IDs to Supabase category slugs
const INTEREST_TO_SLUG: Record<string, string> = {
  'street-food': 'gastronomia',
  'culture': 'entretenimiento',
  'local-crafts': 'artesanias',
  'nightlife': 'entretenimiento',
  'shopping': 'compras',
  'tours': 'tours',
  'lodging': 'hospedaje',
  'wellness': 'bienestar',
};

export const surveyService = {
  async submitOnboarding(params: {
    userId: string;
    nationality: string;
    language: string;
    dietaryRestriction: string;
    budgetRange: string;
    interests: string[];
  }): Promise<void> {
    const supabase = authService.client;

    // 1. Update profile
    const { error: profileError } = await supabase
      .from('profiles')
      .update({
        nationality: params.nationality,
        dietary_restriction: params.dietaryRestriction || 'none',
        budget_range: params.budgetRange || 'medium',
        accessibility_need: 'none',
        onboarding_completed: true,
      })
      .eq('id', params.userId);

    if (profileError) {
      console.error('[Onboarding] Profile update error:', profileError);
      throw profileError;
    }

    // 2. Set preferred language
    const { data: lang } = await supabase
      .from('languages')
      .select('id')
      .eq('code', params.language)
      .single();

    if (lang) {
      // Delete existing language preferences first
      await supabase
        .from('profile_languages')
        .delete()
        .eq('profile_id', params.userId);

      await supabase.from('profile_languages').insert({
        profile_id: params.userId,
        language_id: lang.id,
        is_preferred: true,
        proficiency: 'fluent',
      });
    }

    // 3. Set category interests
    const slugs = params.interests
      .map((i) => INTEREST_TO_SLUG[i])
      .filter(Boolean);

    if (slugs.length > 0) {
      const { data: cats } = await supabase
        .from('categories')
        .select('id')
        .in('slug', slugs);

      if (cats && cats.length > 0) {
        // Delete existing interests first
        await supabase
          .from('profile_category_interests')
          .delete()
          .eq('profile_id', params.userId);

        await supabase.from('profile_category_interests').insert(
          cats.map((c) => ({ profile_id: params.userId, category_id: c.id })),
        );
      }
    }
  },
};
