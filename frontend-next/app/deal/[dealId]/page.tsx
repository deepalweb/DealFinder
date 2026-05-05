import type { Metadata } from 'next';
import DealPageClient from './DealPageClient';
import { buildApiUrl } from '@/lib/config/api';
import { SITE_NAME, SITE_URL, absoluteUrl } from '@/lib/seo';

export async function generateMetadata({ params }: { params: Promise<{ dealId: string }> }): Promise<Metadata> {
  try {
    const { dealId } = await params;
    const res = await fetch(buildApiUrl(`promotions/${dealId}`), {
      next: { revalidate: 3600 },
    });
    if (!res.ok) throw new Error('Not found');
    const deal = await res.json();

    const merchantName = typeof deal.merchant === 'object' ? deal.merchant?.name : deal.merchant || 'DealFinder';
    const title = `${deal.title} — ${deal.discount} OFF | ${merchantName}`;
    const description = deal.description?.slice(0, 160) || `Get ${deal.discount} off with code ${deal.code} at ${merchantName}. Valid until ${new Date(deal.endDate).toLocaleDateString()}.`;

    return {
      title,
      description,
      alternates: {
        canonical: `/deal/${dealId}`,
      },
      openGraph: {
        title,
        description,
        url: `${SITE_URL}/deal/${dealId}`,
        images: deal.image ? [{ url: deal.image, width: 1200, height: 630, alt: deal.title }] : [],
        type: 'website',
      },
      twitter: {
        card: 'summary_large_image',
        title,
        description,
        images: deal.image ? [deal.image] : [],
      },
    };
  } catch {
    return {
      title: `Deal | ${SITE_NAME}`,
      description: 'Discover amazing discounts and promotions on DealFinder.',
    };
  }
}

export default async function DealPage({ params }: { params: Promise<{ dealId: string }> }) {
  const { dealId } = await params;
  let structuredData: Record<string, unknown> | null = null;

  try {
    const res = await fetch(buildApiUrl(`promotions/${dealId}`), {
      next: { revalidate: 3600 },
    });

    if (res.ok) {
      const deal = await res.json();
      const merchantName =
        typeof deal.merchant === 'object'
          ? deal.merchant?.name || SITE_NAME
          : deal.merchant || SITE_NAME;

      structuredData = {
        '@context': 'https://schema.org',
        '@type': 'Product',
        name: deal.title,
        description: deal.description,
        image: deal.images?.length ? deal.images : deal.image ? [deal.image] : [],
        brand: {
          '@type': 'Brand',
          name: merchantName,
        },
        offers: {
          '@type': 'Offer',
          priceCurrency:
            (typeof deal.merchant === 'object' && deal.merchant?.currency) || 'LKR',
          price: deal.discountedPrice ?? deal.originalPrice ?? undefined,
          availability: 'https://schema.org/InStock',
          url: absoluteUrl(`/deal/${dealId}`),
          priceValidUntil: deal.endDate,
        },
      };
    }
  } catch {}

  return (
    <>
      {structuredData ? (
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(structuredData) }}
        />
      ) : null}
      <DealPageClient dealId={dealId} />
    </>
  );
}
