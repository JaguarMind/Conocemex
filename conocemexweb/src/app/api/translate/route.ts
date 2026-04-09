import { NextRequest, NextResponse } from 'next/server';

const DEEPL_URL = 'https://api-free.deepl.com/v2/translate';
const DEEPL_KEY = 'cbffd6a1-4a8e-4028-b78f-12b443e9b86b:fx';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { text, target_lang } = body;

    if (!text || !target_lang) {
      return NextResponse.json({ error: 'Missing text or target_lang' }, { status: 400 });
    }

    const texts = Array.isArray(text) ? text : [text];

    const res = await fetch(DEEPL_URL, {
      method: 'POST',
      headers: {
        'Authorization': `DeepL-Auth-Key ${DEEPL_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ text: texts, target_lang }),
    });

    const data = await res.json();

    if (!res.ok) {
      return NextResponse.json({ error: data.message ?? 'DeepL error' }, { status: res.status });
    }

    return NextResponse.json(data);
  } catch (error) {
    return NextResponse.json({ error: 'Translation failed' }, { status: 500 });
  }
}
