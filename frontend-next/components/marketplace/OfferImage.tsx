"use client";
import Image from "next/image";
import { useState } from "react";
export default function OfferImage({
  src,
  alt,
  sizes,
  preload = false,
}: {
  src: string;
  alt: string;
  sizes: string;
  preload?: boolean;
}) {
  const [failedSource, setFailedSource] = useState<string | null>(null);
  const image = failedSource === src ? "/assets/offer-placeholder.svg" : src;
  return (
    <Image
      src={image}
      alt={alt}
      fill
      sizes={sizes}
      preload={preload}
      className="object-cover"
      unoptimized={image.startsWith("data:")}
      onError={() => setFailedSource(src)}
    />
  );
}
