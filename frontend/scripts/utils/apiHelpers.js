// API Helper functions for making requests to the backend

// Base API URL
const API_BASE_URL = '/api';

// Generic fetch function with error handling
async function fetchAPI(endpoint, options = {}) {
  try {
    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...options.headers
      }
    });
    
    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.message || `API Error: ${response.status}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error('API Request Error:', error);
    throw error;
  }
}

// Promotion API functions
const PromotionAPI = {
  // Get all promotions
  getAll: () => fetchAPI('/promotions'),
  
  // Get a promotion by ID
  getById: (id) => fetchAPI(`/promotions/${id}`),
  
  // Get promotions by merchant ID
  getByMerchant: (merchantId) => fetchAPI(`/promotions/merchant/${merchantId}`),
  
  // Create a new promotion
  create: (promotionData) => fetchAPI('/promotions', {
    method: 'POST',
    body: JSON.stringify(promotionData)
  }),
  
  // Update a promotion
  update: (id, promotionData) => fetchAPI(`/promotions/${id}`, {
    method: 'PUT',
    body: JSON.stringify(promotionData)
  }),
  
  // Delete a promotion
  delete: (id) => fetchAPI(`/promotions/${id}`, {
    method: 'DELETE'
  })
};

// Merchant API functions
const MerchantAPI = {
  // Get all merchants
  getAll: () => fetchAPI('/merchants'),
  
  // Get merchant by ID
  getById: (id) => fetchAPI(`/merchants/${id}`),
  
  // Get merchant dashboard data
  getDashboard: (id) => fetchAPI(`/merchants/${id}/dashboard`),
  
  // Update merchant profile
  update: (id, merchantData) => fetchAPI(`/merchants/${id}`, {
    method: 'PUT',
    body: JSON.stringify(merchantData)
  })
};

// User API functions
const UserAPI = {
  // Register a new user
  register: (userData) => fetchAPI('/users/register', {
    method: 'POST',
    body: JSON.stringify(userData)
  }),
  
  // Login user
  login: (credentials) => fetchAPI('/users/login', {
    method: 'POST',
    body: JSON.stringify(credentials)
  }),
  
  // Get user profile
  getProfile: (id) => fetchAPI(`/users/${id}`),
  
  // Update user profile
  updateProfile: (id, userData) => fetchAPI(`/users/${id}`, {
    method: 'PUT',
    body: JSON.stringify(userData)
  }),
  
  // Add promotion to favorites
  addFavorite: (userId, promotionId) => fetchAPI(`/users/${userId}/favorites`, {
    method: 'POST',
    body: JSON.stringify({ promotionId })
  }),
  
  // Remove promotion from favorites
  removeFavorite: (userId, promotionId) => fetchAPI(`/users/${userId}/favorites/${promotionId}`, {
    method: 'DELETE'
  }),
  
  // Get user's favorite promotions
  getFavorites: (userId) => fetchAPI(`/users/${userId}/favorites`)
};

// Export all API helpers
window.API = {
  Promotions: PromotionAPI,
  Merchants: MerchantAPI,
  Users: UserAPI
};