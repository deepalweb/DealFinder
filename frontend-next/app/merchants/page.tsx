import type { Metadata } from 'next';
import MerchantsPageClient from './MerchantsPageClient';
import { DEFAULT_OG_IMAGE, SITE_NAME, absoluteUrl } from '@/lib/seo';

export const metadata: Metadata = {
  title: 'Merchants and Stores in Sri Lanka',
  description:
    'Browse Sri Lankan merchants, compare active deals, and discover stores with the strongest live promotions on DealFinder.',
  alternates: {
    canonical: absoluteUrl('/merchants'),
  },
  openGraph: {
    title: `Merchants and Stores | ${SITE_NAME}`,
    description:
      'Browse Sri Lankan merchants, compare active deals, and discover stores with the strongest live promotions on DealFinder.',
    url: absoluteUrl('/merchants'),
    type: 'website',
    images: [DEFAULT_OG_IMAGE],
  },
  twitter: {
    card: 'summary_large_image',
    title: `Merchants and Stores | ${SITE_NAME}`,
    description:
      'Browse Sri Lankan merchants, compare active deals, and discover stores with the strongest live promotions on DealFinder.',
    images: [DEFAULT_OG_IMAGE],
  },
};

export default function MerchantsPage() {
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
    ],
  };

  const collectionJsonLd = {
    '@context': 'https://schema.org',
    '@type': 'CollectionPage',
    name: 'DealFinder Merchants',
    description:
      'Browse Sri Lankan merchants, compare active deals, and discover stores with the strongest live promotions on DealFinder.',
    url: absoluteUrl('/merchants'),
    isPartOf: {
      '@type': 'WebSite',
      name: SITE_NAME,
      url: absoluteUrl('/'),
    },
  };

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbJsonLd) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(collectionJsonLd) }}
      />
      <MerchantsPageClient />
    </>
  );
}
