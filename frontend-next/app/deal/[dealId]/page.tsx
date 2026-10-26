import type { Metadata } from "next";
import DealPageClient from "./DealPageClient";
import { buildApiUrl } from "@/lib/config/api";
import { SITE_NAME, absoluteUrl } from "@/lib/seo";
import { safeImage, type OfferRecord } from "@/lib/offer-display";
type Props = {
  params: Promise<{ dealId: string }>;
  searchParams: Promise<{ kind?: string }>;
};
async function loadOffer(
  id: string,
  kind?: string,
): Promise<OfferRecord | null> {
  const resource = kind === "bank" ? "bank-offers" : "promotions";
  let response = await fetch(
    buildApiUrl(`${resource}/${encodeURIComponent(id)}`),
    { next: { revalidate: 60 } },
  );
  if (response.status === 404 && kind !== "bank")
    response = await fetch(
      buildApiUrl(`bank-offers/${encodeURIComponent(id)}`),
      { next: { revalidate: 60 } },
    );
  return response.ok ? response.json() : null;
}
export async function generateMetadata({
  params,
  searchParams,
}: Props): Promise<Metadata> {
  const { dealId } = await params;
  const { kind } = await searchParams;
  try {
    const deal = await loadOffer(dealId, kind);
    if (!deal) return { title: `Offer | ${SITE_NAME}` };
    const title = deal.title || "Offer";
    const description =
      deal.description?.slice(0, 160) ||
      "Explore this offer and its eligibility conditions on DealFinder.";
    return {
      title,
      description,
      alternates: { canonical: `/deal/${dealId}` },
      openGraph: {
        title,
        description,
        url: absoluteUrl(`/deal/${dealId}`),
        images: deal.image ? [{ url: safeImage(deal.image), alt: title }] : [],
      },
    };
  } catch {
    return { title: `Offer | ${SITE_NAME}` };
  }
}
export default async function DealPage({ params, searchParams }: Props) {
  const { dealId } = await params;
  const { kind } = await searchParams;
  return (
    <DealPageClient
      dealId={dealId}
      kind={kind === "bank" ? "bank" : undefined}
    />
  );
}
