import type { Metadata } from 'next';
import CategoryPageClient from './CategoryPageClient';
import {
  DEFAULT_OG_IMAGE,
  SITE_NAME,
  absoluteUrl,
  getCategorySeo,
} from '@/lib/seo';

type CategoryPageProps = {
  params: Promise<{ categoryId: string }>;
};

function getCategoryPath(categoryId: string) {
  return `/categories/${categoryId}`;
}

export async function generateMetadata({
  params,
}: CategoryPageProps): Promise<Metadata> {
  const { categoryId } = await params;
  const category = getCategorySeo(categoryId);
  const canonical = absoluteUrl(getCategoryPath(categoryId));

  return {
    title: `${category.name} in Sri Lanka`,
    description: category.description,
    alternates: {
      canonical,
    },
    openGraph: {
      title: `${category.name} | ${SITE_NAME}`,
      description: category.description,
      url: canonical,
      type: 'website',
      images: [DEFAULT_OG_IMAGE],
    },
    twitter: {
      card: 'summary_large_image',
      title: `${category.name} | ${SITE_NAME}`,
      description: category.description,
      images: [DEFAULT_OG_IMAGE],
    },
  };
}

export default async function CategoryPage({ params }: CategoryPageProps) {
  const { categoryId } = await params;
  const category = getCategorySeo(categoryId);
  const canonical = absoluteUrl(getCategoryPath(categoryId));
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
        name: 'Categories',
        item: absoluteUrl('/categories/all'),
      },
      {
        '@type': 'ListItem',
        position: 3,
        name: category.name,
        item: canonical,
      },
    ],
  };

  const collectionJsonLd = {
    '@context': 'https://schema.org',
    '@type': 'CollectionPage',
    name: category.name,
    description: category.description,
    url: canonical,
    isPartOf: {
      '@type': 'WebSite',
      name: SITE_NAME,
      url: absoluteUrl('/'),
    },
    about: {
      '@type': 'Thing',
      name: category.name,
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
      <CategoryPageClient />
    </>
  );
}
