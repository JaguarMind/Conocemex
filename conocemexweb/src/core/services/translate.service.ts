const cache = new Map<string, string>();

const LANG_MAP: Record<string, string> = {
  es: 'ES',
  en: 'EN',
  fr: 'FR',
  pt: 'PT-BR',
};

export async function translateText(text: string, targetLang: string): Promise<string> {
  const deeplLang = LANG_MAP[targetLang] ?? 'EN';
  const key = `${text}|${deeplLang}`;

  if (cache.has(key)) return cache.get(key)!;

  try {
    const res = await fetch('/api/translate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text, target_lang: deeplLang }),
    });

    const data = await res.json();
    if (!res.ok) {
      console.error('[Translate] API error:', data);
      return text;
    }

    const translated = data.translations?.[0]?.text ?? text;
    cache.set(key, translated);
    return translated;
  } catch (err) {
    console.error('[Translate] Failed:', err);
    return text;
  }
}

export async function translateBatch(texts: string[], targetLang: string): Promise<string[]> {
  const deeplLang = LANG_MAP[targetLang] ?? 'EN';

  const uncached: { index: number; text: string }[] = [];
  const results = texts.map((text, i) => {
    const cacheKey = `${text}|${deeplLang}`;
    if (cache.has(cacheKey)) return cache.get(cacheKey)!;
    uncached.push({ index: i, text });
    return text;
  });

  if (uncached.length === 0) return results;

  try {
    const res = await fetch('/api/translate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text: uncached.map((u) => u.text), target_lang: deeplLang }),
    });

    const data = await res.json();
    const translations = data.translations as { text: string }[];

    translations?.forEach((t, i) => {
      const original = uncached[i];
      cache.set(`${original.text}|${deeplLang}`, t.text);
      results[original.index] = t.text;
    });
  } catch {
    // Return originals on failure
  }

  return results;
}
