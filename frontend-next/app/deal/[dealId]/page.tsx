import type { Metadata } from 'next';
import DealPageClient from './DealPageClient';

const API = process.env.BACKEND_URL
  ? `${process.env.BACKEND_URL}/api`
  : 'http://localhost:8080/api';

export async function generateMetadata({ params }: { params: Promise<{ dealId: string }> }): Promise<Metadata> {
  try {
    const { dealId } = await params;
    const res = await fetch(`${API}/promotions/${dealId}`, { next: { revalidate: 3600 } });
    if (!res.ok) throw new Error('Not found');
    const deal = await res.json();

    const merchantName = typeof deal.merchant === 'object' ? deal.merchant?.name : deal.merchant || 'DealFinder';
    const title = `${deal.title} — ${deal.discount} OFF | ${merchantName}`;
    const description = deal.description?.slice(0, 160) || `Get ${deal.discount} off with code ${deal.code} at ${merchantName}. Valid until ${new Date(deal.endDate).toLocaleDateString()}.`;

    return {
      title,
      description,
      openGraph: {
        title,
        description,
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
      title: 'Deal | DealFinder',
      description: 'Discover amazing discounts and promotions on DealFinder.',
    };
  }
}

export default async function DealPage({ params }: { params: Promise<{ dealId: string }> }) {
  const { dealId } = await params;
  return <DealPageClient dealId={dealId} />;
}
