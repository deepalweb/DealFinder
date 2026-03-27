import type { Metadata } from 'next';
import './globals.css';
import { AuthProvider } from '@/contexts/AuthContext';
import { Toaster } from 'react-hot-toast';
import Header from '@/components/layout/Header';
import Footer from '@/components/layout/Footer';

export const metadata: Metadata = {
  title: 'DealFinder - Discover Amazing Discounts & Promotions',
  description: 'Find the best deals from your favorite stores all in one place.',
  openGraph: {
    title: 'Find Amazing Discounts and Promotions Today!',
    description: 'Access exclusive discounts and promotions online.',
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
          <Header />
          <main className="page-container">{children}</main>
          <Footer />
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
