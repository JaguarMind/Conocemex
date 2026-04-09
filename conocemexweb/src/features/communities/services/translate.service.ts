import { DEEPL_LANG_MAP } from '../models/community.types';

const DEEPL_URL = 'https://api-free.deepl.com/v2/translate';
const DEEPL_KEY = process.env.NEXT_PUBLIC_DEEPL_API_KEY ?? '';
const cache = new Map<string, string>();

export async function translateText(text: string, targetLang: string): Promise<string> {
  const deeplLang = DEEPL_LANG_MAP[targetLang] ?? 'EN';
  const key = `${text}|${deeplLang}`;

  if (cache.has(key)) return cache.get(key)!;
  if (!DEEPL_KEY) return text;

  try {
    const res = await fetch(DEEPL_URL, {
      method: 'POST',
      headers: {
        'Authorization': `DeepL-Auth-Key ${DEEPL_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ text: [text], target_lang: deeplLang }),
    });

    const data = await res.json();
    const translated = data.translations?.[0]?.text ?? text;
    cache.set(key, translated);
    return translated;
  } catch {
    return text;
  }
}
