import { PromotionAPI } from '@/lib/api';
import { Promotion } from '@/types';
import PromotionCard from '@/components/PromotionCard';
import Header from '@/components/Header';
import Link from 'next/link';

export const revalidate = 60;

export default async function HomePage() {
  let promotions: Promotion[] = [];
  try {
    promotions = await PromotionAPI.getAll();
  } catch {}

  const featured = promotions.filter((p) => p.featured);
  const latest = [...promotions].sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()).slice(0, 8);

  return (
    <>
      <Header />
      <main>
        {/* Hero */}
        <section className="bg-indigo-600 text-white py-16 px-4 text-center">
          <h1 className="text-4xl md:text-5xl font-bold mb-4">Find the Best Deals in Sri Lanka</h1>
          <p className="text-lg text-indigo-200 mb-8 max-w-xl mx-auto">
            Discover exclusive discounts and promotions from top brands near you.
          </p>
          <Link href="/categories" className="bg-white text-indigo-600 font-bold px-6 py-3 rounded-full hover:bg-indigo-50 transition">
            Browse Deals
          </Link>
        </section>

        <div className="max-w-7xl mx-auto px-4 py-12 space-y-12">
          {/* Featured */}
          {featured.length > 0 && (
            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-6">🔥 Featured Deals</h2>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                {featured.map((p) => <PromotionCard key={p._id} promotion={p} />)}
              </div>
            </section>
          )}

          {/* Latest */}
          <section>
            <h2 className="text-2xl font-bold text-gray-800 mb-6">🕐 Latest Deals</h2>
            {latest.length > 0 ? (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
                {latest.map((p) => <PromotionCard key={p._id} promotion={p} />)}
              </div>
            ) : (
              <p className="text-gray-500">No deals available yet.</p>
            )}
          </section>
        </div>
      </main>
    </>
  );
}
