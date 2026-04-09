import { authService } from '@/core/services/auth.service';
import i18n from '@/core/i18n/config';
import type { DishCard } from '../models/discover.types';

export const discoverService = {
  async getDishes(searchQuery?: string): Promise<DishCard[]> {
    const supabase = authService.client;
    const results: DishCard[] = [];
    const userLang = i18n.language?.substring(0, 2) ?? 'es';

    // Get language UUID for current locale
    const { data: langRow } = await supabase
      .from('languages')
      .select('id')
      .eq('code', userLang)
      .single();

    const { data: esLangRow } = await supabase
      .from('languages')
      .select('id')
      .eq('code', 'es')
      .single();

    const userLangId = langRow?.id;
    const esLangId = esLangRow?.id;

    console.log('[Discover] User lang:', userLang, 'langId:', userLangId, 'esLangId:', esLangId);

    // 1. Fetch offerings
    const { data: offerings } = await supabase
      .from('offerings')
      .select(`
        id, price_mxn, image_url, is_active, type,
        translations:offering_translations(language_id, name, description),
        business:businesses!inner(id, name, cover_image_url, is_verified, category:categories(slug))
      `)
      .eq('is_active', true)
      .limit(30);

    if (offerings) {
      for (const item of offerings) {
        const biz = item.business as unknown as {
          id: string; name: string; cover_image_url: string | null;
          is_verified: boolean; category: { slug: string } | null;
        };

        const translations = item.translations as { language_id: string; name: string }[];

        // Match by language_id
        const userTrans = translations?.find((t) => t.language_id === userLangId);
        const esTrans = translations?.find((t) => t.language_id === esLangId);
        const name = userTrans?.name ?? esTrans?.name ?? translations?.[0]?.name ?? 'Dish';

        results.push({
          id: item.id,
          name,
          businessId: biz?.id ?? '',
          businessName: biz?.name ?? 'Business',
          priceMxn: item.price_mxn,
          imageUrl: item.image_url ?? null,
          distanceM: 0,
          isLocalSpecialty: biz?.is_verified ?? false,
          isFavorite: false,
          categorySlug: biz?.category?.slug ?? 'gastronomia',
        });
      }
    }

    // 2. Fetch businesses without offerings
    const offeringBusinessIds = new Set(results.map((r) => r.businessId));

    const { data: businesses } = await supabase
      .from('businesses')
      .select(`
        id, name, cover_image_url, is_verified,
        category:categories(slug),
        images:business_images(image_url, sort_order),
        translations:business_translations(language_id, description)
      `)
      .eq('is_active', true)
      .limit(100);

    if (businesses) {
      for (const biz of businesses) {
        if (offeringBusinessIds.has(biz.id)) continue;

        const slug = (biz.category as unknown as { slug: string } | null)?.slug ?? 'gastronomia';
        const firstImage = (biz.images as { image_url: string; sort_order: number }[] | null)
          ?.sort((a, b) => a.sort_order - b.sort_order)?.[0]?.image_url;

        // Get translated name if available via business_translations description
        const bizTranslations = biz.translations as { language_id: string; description: string }[] | null;
        const userBizTrans = bizTranslations?.find((t) => t.language_id === userLangId);
        const displayName = userBizTrans ? `${biz.name}` : biz.name;

        results.push({
          id: `biz-${biz.id}`,
          name: displayName,
          businessId: biz.id,
          businessName: biz.name,
          priceMxn: 0,
          imageUrl: firstImage ?? null,
          distanceM: 0,
          isLocalSpecialty: biz.is_verified,
          isFavorite: false,
          categorySlug: slug,
        });
      }
    }

    // 3. Search filter
    if (searchQuery?.trim()) {
      const q = searchQuery.toLowerCase();
      return results.filter(
        (d) => d.name.toLowerCase().includes(q) || d.businessName.toLowerCase().includes(q),
      );
    }

    return results;
  },
};
