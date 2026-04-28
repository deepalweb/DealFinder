export type PromotionImageSource = {
  image?: string | null;
  imageUrl?: string | null;
  imageDataString?: string | null;
  sectionImage?: string | null;
  images?: string[] | null;
};

export function getPromotionImage(
  promotion?: PromotionImageSource | null,
  fallback = 'https://placehold.co/400x180?text=No+Image&bg=f3f4f6&textcolor=6b7280'
) {
  return (
    promotion?.sectionImage ||
    promotion?.image ||
    promotion?.imageUrl ||
    promotion?.imageDataString ||
    (Array.isArray(promotion?.images) ? promotion!.images!.find((image) => Boolean(image)) : null) ||
    fallback
  );
}

export function hasPromotionImage(promotion?: PromotionImageSource | null) {
  return Boolean(getPromotionImage(promotion, ''));
}
