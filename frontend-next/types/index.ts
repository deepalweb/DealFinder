export interface Promotion {
  _id: string;
  title: string;
  description: string;
  discountPercentage: number;
  imageUrl?: string;
  category: string;
  city: string;
  validFrom: string;
  validUntil: string;
  featured?: boolean;
  merchant?: Merchant | string;
  createdAt: string;
}

export interface Merchant {
  _id: string;
  name: string;
  logo?: string;
  category: string;
  city: string;
  address?: string;
  phone?: string;
}

export interface User {
  id: string;
  name: string;
  email: string;
  role: 'user' | 'merchant' | 'admin';
  token: string;
  refreshToken?: string;
}
