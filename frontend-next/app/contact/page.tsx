import type { Metadata } from 'next';
import ContactPageClient from './ContactPageClient';

export const metadata: Metadata = {
  title: 'Contact DealFinder',
  description:
    'Get in touch with DealFinder for support, partnership enquiries, bug reports, or product feedback.',
  alternates: {
    canonical: '/contact',
  },
  openGraph: {
    title: 'Contact DealFinder',
    description:
      'Get in touch with DealFinder for support, partnership enquiries, bug reports, or product feedback.',
    url: 'https://dealfinderapp.lk/contact',
    type: 'website',
  },
};

export default function ContactPage() {
  return <ContactPageClient />;
}
