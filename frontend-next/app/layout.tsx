import type { Metadata } from 'next';
import './globals.css';
import { AuthProvider } from '@/contexts/AuthContext';
import { Toaster } from 'react-hot-toast';
import Header from '@/components/layout/Header';
import Footer from '@/components/layout/Footer';
import ConditionalLayout from '@/components/layout/ConditionalLayout';

export const metadata: Metadata = {
  title: 'DealFinder - Sri Lanka\'s Smartest Way to Find Deals',
  description: 'Discover exclusive discounts from top stores near you. Smart search, real-time updates, personalized recommendations. Find the best deals in Sri Lanka.',
  keywords: 'deals, discounts, promotions, Sri Lanka, shopping, offers, coupons, sales',
  openGraph: {
    title: 'DealFinder - Sri Lanka\'s Smartest Way to Find Deals',
    description: 'Discover exclusive discounts from top stores near you with smart search and real-time updates.',
    url: 'https://dealfinderlk.com',
    siteName: 'DealFinder',
    locale: 'en_LK',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'DealFinder - Find the Best Deals in Sri Lanka',
    description: 'Smart deal discovery with location search, real-time updates, and personalized recommendations.',
  },
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
