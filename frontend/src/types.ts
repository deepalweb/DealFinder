export interface Deal {
  id: number;
  title: string;
  description: string;
  price: number;
  oldPrice: number;
  discount: number;
  category: 'food' | 'shopping' | 'entertainment' | 'services';
  image: string;
  merchant: string;
  address: string;
  rating: number;
  reviewCount: number;
  featured: boolean;
}
