import { Deal } from '../types';

const API_URL = '/api/deals'; // Assuming the backend is running on the same domain

export const getDeals = async (): Promise<Deal[]> => {
  const response = await fetch(API_URL);
  if (!response.ok) {
    throw new Error('Failed to fetch deals');
  }
  const data = await response.json();
  return data;
};
