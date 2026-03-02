const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/api';

async function fetchAPI(endpoint: string, options: RequestInit = {}) {
  const token = typeof window !== 'undefined' ? localStorage.getItem('dealFinderToken') : null;

  const res = await fetch(`${API_BASE_URL}/${endpoint}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
    credentials: 'include',
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.message || `API Error: ${res.status}`);
  }

  return res.json();
}

export const PromotionAPI = {
  getAll: () => fetchAPI('promotions'),
  getById: (id: string) => fetchAPI(`promotions/${id}`),
  getByMerchant: (merchantId: string) => fetchAPI(`promotions/merchant/${merchantId}`),
  getNearby: (lat: number, lng: number, radius = 10) =>
    fetchAPI(`promotions/nearby?latitude=${lat}&longitude=${lng}&radius=${radius}`),
  create: (data: object) => fetchAPI('promotions', { method: 'POST', body: JSON.stringify(data) }),
  update: (id: string, data: object) => fetchAPI(`promotions/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  delete: (id: string) => fetchAPI(`promotions/${id}`, { method: 'DELETE' }),
  recordClick: (id: string, data: object) =>
    fetchAPI(`promotions/${id}/click`, { method: 'POST', body: JSON.stringify(data) }),
  getAnalyticsByMerchant: (merchantId: string) => fetchAPI(`promotions/analytics/merchant/${merchantId}`),
};

export const MerchantAPI = {
  getAll: () => fetchAPI('merchants'),
  getById: (id: string) => fetchAPI(`merchants/${id}`),
  getDashboard: (id: string) => fetchAPI(`merchants/${id}/dashboard`),
  update: (id: string, data: object) => fetchAPI(`merchants/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  create: (data: object) => fetchAPI('merchants', { method: 'POST', body: JSON.stringify(data) }),
  delete: (id: string) => fetchAPI(`merchants/${id}`, { method: 'DELETE' }),
};

export const UserAPI = {
  register: (data: object) => fetchAPI('users/register', { method: 'POST', body: JSON.stringify(data) }),
  login: (data: object) => fetchAPI('users/login', { method: 'POST', body: JSON.stringify(data) }),
  getAll: () => fetchAPI('users'),
  getProfile: (id: string) => fetchAPI(`users/${id}`),
  updateProfile: (id: string, data: object) => fetchAPI(`users/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  delete: (id: string) => fetchAPI(`users/${id}`, { method: 'DELETE' }),
  addFavorite: (userId: string, promotionId: string) =>
    fetchAPI(`users/${userId}/favorites`, { method: 'POST', body: JSON.stringify({ promotionId }) }),
  removeFavorite: (userId: string, promotionId: string) =>
    fetchAPI(`users/${userId}/favorites/${promotionId}`, { method: 'DELETE' }),
  getFavorites: (userId: string) => fetchAPI(`users/${userId}/favorites`),
  googleSignIn: (data: object) => fetchAPI('users/google-signin', { method: 'POST', body: JSON.stringify(data) }),
};

export const AdminAPI = {
  getDashboardStats: () => fetchAPI('admin/dashboard/stats'),
  getAllPromotions: (filters: Record<string, string> = {}) => {
    const q = new URLSearchParams(filters).toString();
    return fetchAPI(`admin/promotions${q ? `?${q}` : ''}`);
  },
};

export const MapsAPI = {
  getAutocomplete: (input: string) => fetchAPI(`maps/autocomplete?input=${encodeURIComponent(input)}`),
  getPlaceDetails: (placeId: string) => fetchAPI(`maps/place-details?place_id=${placeId}`),
};
