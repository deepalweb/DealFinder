import React from 'react';
import { Deal } from '../types';

interface DealCardProps {
  deal: Deal;
}

const DealCard: React.FC<DealCardProps> = ({ deal }) => {
  return (
    <div className="bg-white rounded-lg shadow-md overflow-hidden">
      <img src={deal.image} alt={deal.title} className="w-full h-48 object-cover" />
      <div className="p-4">
        <h3 className="font-bold text-lg">{deal.title}</h3>
        <p className="text-gray-600">{deal.merchant}</p>
        <div className="flex justify-between items-center mt-4">
          <span className="text-lg font-bold text-primary-color">${deal.price}</span>
          <span className="text-sm text-gray-500 line-through">${deal.oldPrice}</span>
          <span className="text-sm font-bold text-red-500">{deal.discount}% OFF</span>
        </div>
      </div>
    </div>
  );
};

export default DealCard;
