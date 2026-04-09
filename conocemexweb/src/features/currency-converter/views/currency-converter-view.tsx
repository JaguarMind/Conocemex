'use client';

import { useTranslation } from 'react-i18next';

export function CurrencyConverterView() {
  const { t } = useTranslation();

  // TODO: Connect useCurrencyViewModel when Figma views arrive
  return (
    <div className="flex items-center justify-center min-h-[60vh]">
      <div className="text-center text-gray-400">
        <p className="text-lg font-medium">{t('nav.converter')}</p>
        <p className="text-sm mt-1">Currency converter placeholder</p>
      </div>
    </div>
  );
}
