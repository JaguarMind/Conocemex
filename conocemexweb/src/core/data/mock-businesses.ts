import type { Business } from '@/features/map/models/map.types';

export const MOCK_BUSINESSES: Business[] = [
  {
    id: '1',
    name: 'Tacos El Güero',
    description: { es: 'Los mejores tacos al pastor del centro', en: 'Best tacos al pastor downtown' },
    category: 'restaurant',
    coordinates: { latitude: 19.4320, longitude: -99.1330 },
    imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuAZ0i4bNe7pJenur8sKWzLnmATEj5Xp9jGBwt_Oe5k0ml2HOLdLIfFbTaGUSFF_c6D8ecVtkw8aZRgdLjXT4Krqa9TQEMcno6rjFlYDgAqCDpcH7Vd3_RTsF4yh5hVmJsuG80b4ZOpTBdFmXRnQLyoYs2DU28gykXUYNOsqCCWwsgLnQ0ocgJnnx1rTGdiaqplQdhKBXwnH-uExTVousl4nJ_ZbiH4EHfRVdaGtUwlWW3J6qgZPmbcH51bVPfWIkHIXu86dD49rbq7y',
    rating: 4.8,
    isOpen: true,
  },
  {
    id: '2',
    name: 'Artesanías Oaxaca',
    description: { es: 'Artesanías tradicionales oaxaqueñas', en: 'Traditional Oaxacan crafts' },
    category: 'crafts',
    coordinates: { latitude: 19.4340, longitude: -99.1370 },
    rating: 4.5,
    isOpen: true,
  },
  {
    id: '3',
    name: 'Hotel Casa Azul',
    description: { es: 'Hospedaje boutique en el centro histórico', en: 'Boutique hotel in historic center' },
    category: 'lodging',
    coordinates: { latitude: 19.4280, longitude: -99.1290 },
    rating: 4.7,
    isOpen: true,
  },
  {
    id: '4',
    name: 'Cantina La Nacional',
    description: { es: 'Cantina tradicional con música en vivo', en: 'Traditional cantina with live music' },
    category: 'entertainment',
    coordinates: { latitude: 19.4350, longitude: -99.1310 },
    rating: 4.3,
    isOpen: false,
  },
  {
    id: '5',
    name: 'Mercado Roma',
    description: { es: 'Mercado gourmet en la Roma Norte', en: 'Gourmet market in Roma Norte' },
    category: 'shopping',
    coordinates: { latitude: 19.4190, longitude: -99.1620 },
    rating: 4.6,
    isOpen: true,
  },
  {
    id: '6',
    name: 'Café de Olla Abuela',
    description: { es: 'Café tradicional mexicano', en: 'Traditional Mexican coffee' },
    category: 'restaurant',
    coordinates: { latitude: 19.4305, longitude: -99.1355 },
    rating: 4.9,
    isOpen: true,
  },
  {
    id: '7',
    name: 'Galería Arte Popular',
    description: { es: 'Arte popular mexicano contemporáneo', en: 'Contemporary Mexican folk art' },
    category: 'entertainment',
    coordinates: { latitude: 19.4360, longitude: -99.1345 },
    rating: 4.4,
    isOpen: true,
  },
];

export function getBusinessById(id: string) {
  return MOCK_BUSINESSES.find((b) => b.id === id) ?? null;
}
