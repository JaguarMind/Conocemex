'use client';

import { useTranslation } from 'react-i18next';

export function RouteGeneratorView() {
  const { t } = useTranslation();

  // TODO: Connect useRouteViewModel when Figma views arrive
  return (
    <div className="flex items-center justify-center min-h-[60vh]">
      <div className="text-center text-gray-400">
        <p className="text-lg font-medium">{t('nav.routes')}</p>
        <p className="text-sm mt-1">Route generator placeholder</p>
      </div>
    </div>
  );
}
