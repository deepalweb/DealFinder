import { getApiBase } from '@/lib/config/api';

const API_BASE = getApiBase();

// Simple in-memory cache for GET requests (client-side only)
const cache = new Map<string, { data: any; ts: number }>();
const CACHE_TTL = 2 * 60_000; // 2 minutes

function getCached<T>(key: string): T | null {
  const entry = cache.get(key);
  if (entry && Date.now() - entry.ts < CACHE_TTL) return entry.data as T;
  cache.delete(key);
  return null;
}

function setCached(key: string, data: any) {
  cache.set(key, { data, ts: Date.now() });
}

export function invalidateCache(keyPrefix?: string) {
  if (!keyPrefix) { cache.clear(); return; }
  cache.forEach((_, k) => { if (k.startsWith(keyPrefix)) cache.delete(k); });
}

function getToken(): string | null {
  if (typeof window === 'undefined') return null;
  try {
    const user = localStorage.getItem('dealFinderUser');
    return user ? JSON.parse(user).token : null;
  } catch { return null; }
}

async function fetchAPI<T>(endpoint: string, options: RequestInit = {}, revalidate?: number): Promise<T> {
  const isGet = !options.method || options.method === 'GET';
  const cacheKey = `${endpoint}`;

  // Return cached data for GET requests on the client (skip if cache: no-store)
  if (isGet && typeof window !== 'undefined' && options.cache !== 'no-store') {
    const cached = getCached<T>(cacheKey);
    if (cached) return cached;
  }

  const token = getToken();
  const res = await fetch(`${API_BASE}/${endpoint}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
    ...((!options.method || options.method === 'GET') && typeof window === 'undefined'
      ? { next: { revalidate: revalidate ?? 60 } }
      : { cache: 'no-store' }),
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.message || `API Error: ${res.status}`);
  }
  const data = await res.json();

  // Store in cache for GET requests
  if (isGet && typeof window !== 'undefined' && options.cache !== 'no-store') setCached(cacheKey, data);

  return data;
}

// Promotions
export const PromotionAPI = {
  getAll: (params?: { limit?: number; skip?: number }) => {
    const q = params ? new URLSearchParams(params as any).toString() : '';
    return fetchAPI<any[]>(`promotions${q ? `?${q}` : ''}`);
  },
  getHomepage: () => fetchAPI<{ featured: any[]; latest: any[] }>('promotions/homepage', { cache: 'no-store' }),
  getSections: () => fetchAPI<any>('promotions/sections', { cache: 'no-store' }),
  getSection: (sectionKey: string, params?: Record<string, string | number | undefined>) => {
    const query = new URLSearchParams(
      Object.entries(params || {}).reduce<Record<string, string>>((acc, [key, value]) => {
        if (value !== undefined && value !== null && value !== '') acc[key] = String(value);
        return acc;
      }, {})
    ).toString();
    return fetchAPI<any>(`promotions/sections/${sectionKey}${query ? `?${query}` : ''}`, { cache: 'no-store' });
  },
  getById: (id: string) => fetchAPI<any>(`promotions/${id}`),
  getByMerchant: (merchantId: string) => fetchAPI<any[]>(`promotions/merchant/${merchantId}`),
  getNearby: (lat: number, lon: number, radius = 10) =>
    fetchAPI<any[]>(`promotions/nearby?latitude=${lat}&longitude=${lon}&radius=${radius}`, { cache: 'no-store' }),
  create: (data: any) => fetchAPI<any>('promotions', { method: 'POST', body: JSON.stringify(data) })
    .then(r => { invalidateCache('promotions'); return r; }),
  update: (id: string, data: any) => fetchAPI<any>(`promotions/${id}`, { method: 'PUT', body: JSON.stringify(data) })
    .then(r => { invalidateCache('promotions'); return r; }),
  delete: (id: string) => fetchAPI<any>(`promotions/${id}`, { method: 'DELETE' })
    .then(r => { invalidateCache('promotions'); return r; }),
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
  getAll: () => fetchAPI<any[]>('merchants'), // Now uses 2-minute client cache + 5-minute server cache
  getById: (id: string) => fetchAPI<any>(`merchants/${id}`),
  update: (id: string, data: any) => fetchAPI<any>(`merchants/${id}`, { method: 'PUT', body: JSON.stringify(data) })
    .then(r => { invalidateCache('merchants'); return r; }),
  create: (data: any) => fetchAPI<any>('merchants', { method: 'POST', body: JSON.stringify(data) })
    .then(r => { invalidateCache('merchants'); return r; }),
  delete: (id: string) => fetchAPI<any>(`merchants/${id}`, { method: 'DELETE' })
    .then(r => { invalidateCache('merchants'); return r; }),
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
  getDashboardOverview: () => fetchAPI<any>('admin/dashboard/overview'),
  getDashboardTrends: () => fetchAPI<any>('admin/dashboard/trends'),
  getDashboardAlerts: () => fetchAPI<any>('admin/dashboard/alerts'),
  getAllPromotions: (filters = {}) => {
    const q = new URLSearchParams(filters as any).toString();
    return fetchAPI<any>(`admin/promotions${q ? `?${q}` : ''}`).then((res: any) => Array.isArray(res) ? res : (res?.data || []));
  },
  getSections: () => fetchAPI<any[]>('admin/sections', { cache: 'no-store' }),
  getSectionConflicts: () => fetchAPI<any[]>('admin/sections/conflicts', { cache: 'no-store' }),
  saveSectionAssignment: (data: any) =>
    fetchAPI<any>('admin/sections/assignments', { method: 'POST', body: JSON.stringify(data) })
      .then((res) => { invalidateCache('admin/sections'); invalidateCache('promotions'); return res; }),
  deleteSectionAssignment: (id: string) =>
    fetchAPI<any>(`admin/sections/assignments/${id}`, { method: 'DELETE' })
      .then((res) => { invalidateCache('admin/sections'); invalidateCache('promotions'); return res; }),
  publishSections: () =>
    fetchAPI<any>('admin/sections/publish', { method: 'POST' })
      .then((res) => { invalidateCache('admin/sections'); invalidateCache('promotions'); return res; }),
};

// Notifications
export const NotificationAPI = {
  getAll: (params?: { limit?: number; skip?: number; unreadOnly?: boolean }) => {
    const q = new URLSearchParams(params as any).toString();
    return fetchAPI<any[]>(`notifications${q ? `?${q}` : ''}`);
  },
  getUnreadCount: () => fetchAPI<{ count: number }>('notifications/unread-count', { method: 'GET', cache: 'no-store' }),
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

// Images (Azure Blob Storage)
export const ImageAPI = {
  uploadSingle: async (file: File, folder = 'images'): Promise<string> => {
    const token = getToken();
    const formData = new FormData();
    formData.append('image', file);
    formData.append('folder', folder);

    const res = await fetch(`${API_BASE}/images/upload`, {
      method: 'POST',
      headers: {
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: formData,
    });

    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || `Upload failed: ${res.status}`);
    }

    const data = await res.json();
    return data.imageUrl;
  },

  uploadMultiple: async (files: File[], folder = 'images'): Promise<string[]> => {
    const token = getToken();
    const formData = new FormData();
    files.forEach(file => formData.append('images', file));
    formData.append('folder', folder);

    const res = await fetch(`${API_BASE}/images/upload-multiple`, {
      method: 'POST',
      headers: {
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: formData,
    });

    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.message || `Upload failed: ${res.status}`);
    }

    const data = await res.json();
    return data.imageUrls;
  },

  delete: async (imageUrl: string): Promise<void> => {
    await fetchAPI('images/delete', {
      method: 'DELETE',
      body: JSON.stringify({ imageUrl }),
    });
  },
};
