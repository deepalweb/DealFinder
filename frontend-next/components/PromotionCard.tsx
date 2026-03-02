import Link from 'next/link';
import { Promotion } from '@/types';

export default function PromotionCard({ promotion }: { promotion: Promotion }) {
  const isExpiringSoon = () => {
    const diff = new Date(promotion.validUntil).getTime() - Date.now();
    return diff > 0 && diff < 3 * 24 * 60 * 60 * 1000;
  };

  return (
    <Link href={`/deals/${promotion._id}`}>
      <div className="bg-white rounded-xl shadow hover:shadow-md transition overflow-hidden cursor-pointer h-full">
        {promotion.imageUrl && (
          <img src={promotion.imageUrl} alt={promotion.title} className="w-full h-40 object-cover" />
        )}
        <div className="p-4">
          <div className="flex items-start justify-between gap-2 mb-2">
            <h3 className="font-semibold text-gray-800 text-sm leading-tight line-clamp-2">{promotion.title}</h3>
            {promotion.discountPercentage > 0 && (
              <span className="bg-red-500 text-white text-xs font-bold px-2 py-1 rounded-full shrink-0">
                -{promotion.discountPercentage}%
              </span>
            )}
          </div>
          <p className="text-xs text-gray-500 line-clamp-2 mb-3">{promotion.description}</p>
          <div className="flex items-center justify-between text-xs text-gray-400">
            <span>{promotion.city}</span>
            {isExpiringSoon() && (
              <span className="text-orange-500 font-medium">Ending soon</span>
            )}
          </div>
        </div>
      </div>
    </Link>
  );
}
