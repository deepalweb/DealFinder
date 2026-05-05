import type { Metadata } from 'next';
import './globals.css';
import { AuthProvider } from '@/contexts/AuthContext';
import { Toaster } from 'react-hot-toast';
import Header from '@/components/layout/Header';
import Footer from '@/components/layout/Footer';
import ConditionalLayout from '@/components/layout/ConditionalLayout';
import {
  DEFAULT_DESCRIPTION,
  DEFAULT_OG_IMAGE,
  DEFAULT_TITLE,
  SITE_NAME,
  SITE_URL,
} from '@/lib/seo';

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: {
    default: DEFAULT_TITLE,
    template: `%s | ${SITE_NAME}`,
  },
  description: DEFAULT_DESCRIPTION,
  applicationName: SITE_NAME,
  keywords: 'deals, discounts, promotions, Sri Lanka, shopping, offers, coupons, sales',
  alternates: {
    canonical: '/',
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-image-preview': 'large',
      'max-snippet': -1,
      'max-video-preview': -1,
    },
  },
  openGraph: {
    title: DEFAULT_TITLE,
    description: DEFAULT_DESCRIPTION,
    url: SITE_URL,
    siteName: SITE_NAME,
    locale: 'en_LK',
    type: 'website',
    images: [
      {
        url: DEFAULT_OG_IMAGE,
        width: 512,
        height: 512,
        alt: `${SITE_NAME} app icon`,
      },
    ],
  },
  twitter: {
    card: 'summary_large_image',
    title: DEFAULT_TITLE,
    description: DEFAULT_DESCRIPTION,
    images: [DEFAULT_OG_IMAGE],
  },
  category: 'shopping',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" />
      </head>
      <body suppressHydrationWarning>
        <AuthProvider>
          <ConditionalLayout>{children}</ConditionalLayout>
          <Toaster position="bottom-right" toastOptions={{
            style: { borderRadius: '0.75rem', fontFamily: 'Inter, sans-serif', fontSize: '0.875rem' },
            success: { style: { background: '#dcfce7', color: '#166534' } },
            error: { style: { background: '#fee2e2', color: '#991b1b' } },
          }} />
        </AuthProvider>
      </body>
    </html>
  );
}
