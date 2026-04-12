const isDev = typeof window !== 'undefined' && window.location.hostname === 'localhost';

const API_BASE = typeof window === 'undefined'
  ? (process.env.BACKEND_URL || 'http://localhost:8080') + '/api'
  : isDev
    ? 'http://localhost:8080/api'
    : '/api';

function getToken(): string | null {
  if (typeof window === 'undefined') return null;
  try {
    const user = localStorage.getItem('dealFinderUser');
    return user ? JSON.parse(user).token : null;
  } catch { return null; }
}

async function fetchAPI<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
  const token = getToken();
  const res = await fetch(`${API_BASE}/${endpoint}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.message || `API Error: ${res.status}`);
  }
  return res.json();
}

// Promotions
export const PromotionAPI = {
  getAll: () => fetchAPI<any[]>('promotions'),
  getById: (id: string) => fetchAPI<any>(`promotions/${id}`),
  getByMerchant: (merchantId: string) => fetchAPI<any[]>(`promotions/merchant/${merchantId}`),
  getNearby: (lat: number, lon: number, radius = 10) =>
    fetchAPI<any[]>(`promotions/nearby?latitude=${lat}&longitude=${lon}&radius=${radius}`),
  create: (data: any) => fetchAPI<any>('promotions', { method: 'POST', body: JSON.stringify(data) }),
  update: (id: string, data: any) => fetchAPI<any>(`promotions/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  delete: (id: string) => fetchAPI<any>(`promotions/${id}`, { method: 'DELETE' }),
  getAnalyticsByMerchant: (merchantId: string) => fetchAPI<any[]>(`promotions/analytics/merchant/${merchantId}`),
  getAnalyticsByPromotion: (id: string) => fetchAPI<any[]>(`promotions/${id}/analytics`),
  recordClick: (id: string, data: any) => fetchAPI<any>(`promotions/${id}/click`, { method: 'POST', body: JSON.stringify(data) }),
  getComments: (id: string) => fetchAPI<any[]>(`promotions/${id}/comments`),
  addComment: (id: string, data: any) => fetchAPI<any>(`promotions/${id}/comments`, { method: 'POST', body: JSON.stringify(data) }),
  getRatings: (id: string) => fetchAPI<any[]>(`promotions/${id}/ratings`),
  addRating: (id: string, data: any) => fetchAPI<any>(`promotions/${id}/ratings`, { method: 'POST', body: JSON.stringify(data) }),
};

// Merchants
export const MerchantAPI = {
  getAll: () => fetchAPI<any[]>('merchants'),
  getById: (id: string) => fetchAPI<any>(`merchants/${id}`),
  update: (id: string, data: any) => fetchAPI<any>(`merchants/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  create: (data: any) => fetchAPI<any>('merchants', { method: 'POST', body: JSON.stringify(data) }),
  delete: (id: string) => fetchAPI<any>(`merchants/${id}`, { method: 'DELETE' }),
};

// Users
export const UserAPI = {
  register: (data: any) => fetchAPI<any>('users/register', { method: 'POST', body: JSON.stringify(data) }),
  login: (data: any) => fetchAPI<any>('users/login', { method: 'POST', body: JSON.stringify(data) }),
  getProfile: (id: string) => fetchAPI<any>(`users/${id}`),
  updateProfile: (id: string, data: any) => fetchAPI<any>(`users/${id}`, { method: 'PUT', body: JSON.stringify(data) }),
  changePassword: (id: string, data: any) => fetchAPI<any>(`users/${id}/change-password`, { method: 'POST', body: JSON.stringify(data) }),
  getFavorites: (id: string) => fetchAPI<any[]>(`users/${id}/favorites`),
  addFavorite: (id: string, promotionId: string) => fetchAPI<any>(`users/${id}/favorites`, { method: 'POST', body: JSON.stringify({ promotionId }) }),
  removeFavorite: (id: string, promotionId: string) => fetchAPI<any>(`users/${id}/favorites/${promotionId}`, { method: 'DELETE' }),
  googleSignIn: (data: any) => fetchAPI<any>('users/google-signin', { method: 'POST', body: JSON.stringify(data) }),
  getAll: () => fetchAPI<any[]>('users'),
  delete: (id: string) => fetchAPI<any>(`users/${id}`, { method: 'DELETE' }),
};

// Admin
export const AdminAPI = {
  getDashboardStats: () => fetchAPI<any>('admin/dashboard/stats'),
  getAllPromotions: (filters = {}) => {
    const q = new URLSearchParams(filters as any).toString();
    return fetchAPI<any>(`admin/promotions${q ? `?${q}` : ''}`).then((res: any) => Array.isArray(res) ? res : (res?.data || []));
  },
};

// Notifications
export const NotificationAPI = {
  getAll: (params?: { limit?: number; skip?: number; unreadOnly?: boolean }) => {
    const q = new URLSearchParams(params as any).toString();
    return fetchAPI<any[]>(`notifications${q ? `?${q}` : ''}`);
  },
  getUnreadCount: () => fetchAPI<{ count: number }>('notifications/unread-count'),
  markAsRead: (id: string) => fetchAPI<any>(`notifications/${id}/read`, { method: 'PATCH' }),
  delete: (id: string) => fetchAPI<any>(`notifications/${id}`, { method: 'DELETE' }),
  getPreferences: () => fetchAPI<any>('notifications/preferences'),
  updatePreferences: (data: any) => fetchAPI<any>('notifications/preferences', { method: 'PUT', body: JSON.stringify(data) }),
  resetPreferences: () => fetchAPI<any>('notifications/preferences/reset', { method: 'POST' }),
  subscribe: (subscription: any, type: 'web' | 'push' = 'web') => 
    fetchAPI<any>('notifications/subscribe', { method: 'POST', body: JSON.stringify({ subscription, type }) }),
  unsubscribe: (type: 'web' | 'push' = 'web') => 
    fetchAPI<any>('notifications/unsubscribe', { method: 'POST', body: JSON.stringify({ type }) }),
  sendTest: () => fetchAPI<any>('notifications/test', { method: 'POST' }),
};
