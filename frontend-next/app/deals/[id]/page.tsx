import { PromotionAPI } from '@/lib/api';
import { Promotion } from '@/types';
import Header from '@/components/Header';
import { notFound } from 'next/navigation';

export async function generateMetadata({ params }: { params: { id: string } }) {
  try {
    const deal: Promotion = await PromotionAPI.getById(params.id);
    return { title: `${deal.title} | DealFinder`, description: deal.description };
  } catch {
    return { title: 'Deal | DealFinder' };
  }
}

export default async function DealPage({ params }: { params: { id: string } }) {
  let deal: Promotion;
  try {
    deal = await PromotionAPI.getById(params.id);
  } catch {
    notFound();
  }

  return (
    <>
      <Header />
      <main className="max-w-3xl mx-auto px-4 py-10">
        {deal.imageUrl && (
          <img src={deal.imageUrl} alt={deal.title} className="w-full h-64 object-cover rounded-xl mb-6" />
        )}
        <div className="flex items-start justify-between gap-4 mb-4">
          <h1 className="text-3xl font-bold text-gray-800">{deal.title}</h1>
          {deal.discountPercentage > 0 && (
            <span className="bg-red-500 text-white text-xl font-bold px-4 py-2 rounded-full shrink-0">
              -{deal.discountPercentage}%
            </span>
          )}
        </div>
        <p className="text-gray-600 mb-6">{deal.description}</p>
        <div className="grid grid-cols-2 gap-4 text-sm text-gray-500">
          <div><span className="font-medium text-gray-700">Category:</span> {deal.category}</div>
          <div><span className="font-medium text-gray-700">City:</span> {deal.city}</div>
          <div><span className="font-medium text-gray-700">Valid From:</span> {new Date(deal.validFrom).toLocaleDateString()}</div>
          <div><span className="font-medium text-gray-700">Valid Until:</span> {new Date(deal.validUntil).toLocaleDateString()}</div>
        </div>
      </main>
    </>
  );
}
