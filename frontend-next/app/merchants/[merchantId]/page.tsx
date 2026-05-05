import type { Metadata } from 'next';
import MerchantProfilePageClient from './MerchantProfilePageClient';
import { buildApiUrl } from '@/lib/config/api';
import {
  DEFAULT_DESCRIPTION,
  DEFAULT_OG_IMAGE,
  SITE_NAME,
  absoluteUrl,
} from '@/lib/seo';

type Merchant = {
  _id?: string;
  id?: string;
  name?: string;
  description?: string;
  category?: string;
  logo?: string;
  banner?: string;
  website?: string;
  followers?: number;
  activeDeals?: number;
};

type MerchantPageProps = {
  params: Promise<{ merchantId: string }>;
};

function getMerchantPath(merchantId: string) {
  return `/merchants/${merchantId}`;
}

function getSafeImage(merchant?: Merchant | null) {
  if (merchant?.banner && merchant.banner.startsWith('http')) {
    return merchant.banner;
  }

  if (merchant?.logo && merchant.logo.startsWith('http')) {
    return merchant.logo;
  }

  return DEFAULT_OG_IMAGE;
}

function getMerchantDescription(merchant?: Merchant | null) {
  if (merchant?.description?.trim()) {
    return merchant.description.trim();
  }

  if (merchant?.name) {
    const categoryLabel = merchant.category || 'shopping';
    return `Browse live deals, discounts, and merchant updates from ${merchant.name} on DealFinder. Explore ${categoryLabel} offers in Sri Lanka.`;
  }

  return DEFAULT_DESCRIPTION;
}

async function fetchMerchant(merchantId: string) {
  try {
    const response = await fetch(buildApiUrl(`merchants/${merchantId}`), {
      next: { revalidate: 300 },
    });

    if (!response.ok) {
      return null;
    }

    return (await response.json()) as Merchant;
  } catch {
    return null;
  }
}

export async function generateMetadata({
  params,
}: MerchantPageProps): Promise<Metadata> {
  const { merchantId } = await params;
  const merchant = await fetchMerchant(merchantId);
  const canonical = absoluteUrl(getMerchantPath(merchantId));
  const description = getMerchantDescription(merchant);
  const image = getSafeImage(merchant);

  if (!merchant?.name) {
    return {
      title: 'Merchant Deals',
      description: DEFAULT_DESCRIPTION,
      alternates: {
        canonical,
      },
      robots: {
        index: false,
        follow: true,
      },
    };
  }

  return {
    title: `${merchant.name} Deals in Sri Lanka`,
    description,
    alternates: {
      canonical,
    },
    openGraph: {
      title: `${merchant.name} | ${SITE_NAME}`,
      description,
      url: canonical,
      type: 'profile',
      images: [image],
    },
    twitter: {
      card: 'summary_large_image',
      title: `${merchant.name} | ${SITE_NAME}`,
      description,
      images: [image],
    },
  };
}

export default async function MerchantProfilePage({
  params,
}: MerchantPageProps) {
  const { merchantId } = await params;
  const merchant = await fetchMerchant(merchantId);
  const canonical = absoluteUrl(getMerchantPath(merchantId));

  const breadcrumbJsonLd = {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: [
      {
        '@type': 'ListItem',
        position: 1,
        name: 'Home',
        item: absoluteUrl('/'),
      },
      {
        '@type': 'ListItem',
        position: 2,
        name: 'Merchants',
        item: absoluteUrl('/merchants'),
      },
      {
        '@type': 'ListItem',
        position: 3,
        name: merchant?.name || 'Merchant',
        item: canonical,
      },
    ],
  };

  const merchantJsonLd = merchant?.name
    ? {
        '@context': 'https://schema.org',
        '@type': 'Store',
        name: merchant.name,
        description: getMerchantDescription(merchant),
        url: canonical,
        image: getSafeImage(merchant),
        logo: merchant.logo || undefined,
        sameAs: merchant.website ? [merchant.website] : undefined,
        category: merchant.category || undefined,
      }
    : null;

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbJsonLd) }}
      />
      {merchantJsonLd ? (
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(merchantJsonLd) }}
        />
      ) : null}
      <MerchantProfilePageClient />
    </>
  );
}
