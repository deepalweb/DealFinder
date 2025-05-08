// API Helper functions for making requests to the backend

// Base API URL - Use absolute URL for Azure deployment
const isProduction = window.location.hostname.includes('azurewebsites.net');
const API_BASE_URL = isProduction 
  ? 'https://dealfinder-h0hnh3emahabaahw.southindia-01.azurewebsites.net/api/'
  : '/api/';

console.log('Using API base URL:', API_BASE_URL);

// Generic fetch function with error handling
async function fetchAPI(endpoint, options = {}, retries = 2) {
  try {
    // Prepare options for production environment
    if (isProduction) {
      options = {
        ...options,
        mode: 'cors',
        headers: {
          'Content-Type': 'application/json',
          'Origin': window.location.origin,
          ...options.headers
        }
      };
    }
    
    console.log(`API Request: ${API_BASE_URL}${endpoint}`);
    
    // Create an AbortController for timeout
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 10000); // 10 second timeout
    
    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      ...options,
      signal: controller.signal,
      headers: {
        'Content-Type': 'application/json',
        ...options.headers
      },
      // Add credentials to handle cookies properly
      credentials: 'include'
    });
    
    // Clear the timeout since the request completed
    clearTimeout(timeoutId);
    
    if (!response.ok) {
      console.error(`API Error: ${response.status} for ${endpoint}`);
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.message || `API Error: ${response.status}`);
    }
    
    const data = await response.json();
    console.log(`API Response for ${endpoint}:`, { dataLength: Array.isArray(data) ? data.length : 'object' });
    return data;
  } catch (error) {
    console.error('API Request Error:', error);
    
    // Retry logic for network errors or timeouts
    if (retries > 0 && (
      error.name === 'AbortError' || 
      error.message.includes('network') || 
      error.message.includes('failed to fetch')
    )) {
      console.log(`Retrying request to ${endpoint}, ${retries} attempts left`);
      return await fetchAPI(endpoint, options, retries - 1);
    }
    
    throw error;
  }
}

// Promotion API functions
const PromotionAPI = {
  // Get all promotions
  getAll: () => fetchAPI('promotions'),
  
  // Get a promotion by ID
  getById: (id) => fetchAPI(`promotions/${id}`),
  
  // Get promotions by merchant ID
  getByMerchant: (merchantId) => fetchAPI(`promotions/merchant/${merchantId}`),
  
  // Create a new promotion
  create: (promotionData) => fetchAPI('promotions', {
    method: 'POST',
    body: JSON.stringify(promotionData)
  }),
  
  // Update a promotion
  update: (id, promotionData) => fetchAPI(`promotions/${id}`, {
    method: 'PUT',
    body: JSON.stringify(promotionData)
  }),
  
  // Delete a promotion
  delete: (id) => fetchAPI(`promotions/${id}`, {
    method: 'DELETE'
  })
};

// Merchant API functions
const MerchantAPI = {
  // Get all merchants
  getAll: () => fetchAPI('merchants'),
  
  // Get merchant by ID
  getById: (id) => fetchAPI(`merchants/${id}`),
  
  // Get merchant dashboard data
  getDashboard: (id) => fetchAPI(`merchants/${id}/dashboard`),
  
  // Update merchant profile
  update: (id, merchantData) => fetchAPI(`merchants/${id}`, {
    method: 'PUT',
    body: JSON.stringify(merchantData)
  })
};

// User API functions
const UserAPI = {
  // Register a new user
  register: (userData) => fetchAPI('users/register', {
    method: 'POST',
    body: JSON.stringify(userData)
  }),
  
  // Login user
  login: (credentials) => fetchAPI('users/login', {
    method: 'POST',
    body: JSON.stringify(credentials)
  }),
  
  // Get user profile
  getProfile: (id) => fetchAPI(`users/${id}`),
  
  // Update user profile
  updateProfile: (id, userData) => fetchAPI(`users/${id}`, {
    method: 'PUT',
    body: JSON.stringify(userData)
  }),
  
  // Add promotion to favorites
  addFavorite: (userId, promotionId) => fetchAPI(`users/${userId}/favorites`, {
    method: 'POST',
    body: JSON.stringify({ promotionId })
  }),
  
  // Remove promotion from favorites
  removeFavorite: (userId, promotionId) => fetchAPI(`users/${userId}/favorites/${promotionId}`, {
    method: 'DELETE'
  }),
  
  // Get user's favorite promotions
  getFavorites: (userId) => fetchAPI(`users/${userId}/favorites`)
};

// Export all API helpers
window.API = {
  Promotions: PromotionAPI,
  Merchants: MerchantAPI,
  Users: UserAPI
};
