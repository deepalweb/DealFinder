import type { MetadataRoute } from 'next';
import { buildApiUrl } from '@/lib/config/api';
import {
  DEAL_CATEGORIES,
  PUBLIC_ROUTES,
  SITE_URL,
  absoluteUrl,
} from '@/lib/seo';

type Promotion = {
  _id?: string;
  updatedAt?: string;
  createdAt?: string;
};

type Merchant = {
  _id?: string;
  updatedAt?: string;
  createdAt?: string;
};

async function getPromotions(): Promise<Promotion[]> {
  try {
    const response = await fetch(buildApiUrl('promotions?limit=200'), {
      next: { revalidate: 3600 },
    });
    if (!response.ok) return [];
    return (await response.json()) as Promotion[];
  } catch {
    return [];
  }
}

async function getMerchants(): Promise<Merchant[]> {
  try {
    const response = await fetch(buildApiUrl('merchants'), {
      next: { revalidate: 3600 },
    });
    if (!response.ok) return [];
    return (await response.json()) as Merchant[];
  } catch {
    return [];
  }
}

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const [promotions, merchants] = await Promise.all([getPromotions(), getMerchants()]);

  const staticRoutes: MetadataRoute.Sitemap = PUBLIC_ROUTES.map((route) => ({
    url: absoluteUrl(route),
    lastModified: new Date(),
    changeFrequency: route === '/' ? 'hourly' : 'weekly',
    priority: route === '/' ? 1 : 0.7,
  }));

  const categoryRoutes: MetadataRoute.Sitemap = DEAL_CATEGORIES.map((category) => ({
    url: absoluteUrl(`/categories/${category}`),
    lastModified: new Date(),
    changeFrequency: 'daily',
    priority: 0.8,
  }));

  const dealRoutes: MetadataRoute.Sitemap = promotions
    .filter((promotion) => promotion._id)
    .map((promotion) => ({
      url: `${SITE_URL}/deal/${promotion._id}`,
      lastModified: new Date(
        promotion.updatedAt || promotion.createdAt || Date.now()
      ),
      changeFrequency: 'daily' as const,
      priority: 0.9,
    }));

  const merchantRoutes: MetadataRoute.Sitemap = merchants
    .filter((merchant) => merchant._id)
    .map((merchant) => ({
      url: `${SITE_URL}/merchants/${merchant._id}`,
      lastModified: new Date(
        merchant.updatedAt || merchant.createdAt || Date.now()
      ),
      changeFrequency: 'weekly' as const,
      priority: 0.8,
    }));

  return [...staticRoutes, ...categoryRoutes, ...dealRoutes, ...merchantRoutes];
}
