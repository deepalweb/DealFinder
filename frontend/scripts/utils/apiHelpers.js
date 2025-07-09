// API Helper functions for making requests to the backend

// Base API URL - Use absolute URL for Azure deployment
const isAzure = window.location.hostname.includes('azurewebsites.net');
const isDrstores = window.location.hostname.includes('drstores.lk');
const API_BASE_URL = isAzure
  ? 'https://dealfinder-h0hnh3emahabaahw.southindia-01.azurewebsites.net/api/'
  : isDrstores
    ? 'https://dealfinder-h0hnh3emahabaahw.southindia-01.azurewebsites.net/api/'
    : 'http://localhost:8080/api/';

console.log('Using API base URL:', API_BASE_URL);
window.API_BASE_URL = API_BASE_URL; // Expose for other scripts like authHelpers

// Generic fetch function with error handling
async function fetchAPI(endpoint, options = {}, retries = 2) {
  try {
    // Prepare options for production environment
    if (isAzure || isDrstores) {
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
    
    // Add Authorization header with JWT if available
    let token = window.Auth && window.Auth.getAuthToken ? window.Auth.getAuthToken() : null;

    if (token && window.Auth.isTokenExpired(token)) {
      console.log('Access token expired, attempting to refresh...');
      try {
        const newToken = await window.Auth.refreshAccessToken(); // Call refreshAccessToken once
        if (newToken) {
          token = newToken; // Use the new token for the current request
          console.log('Access token obtained via refresh for current request.');
        } else {
          // refreshAccessToken returned null, meaning it handled logout and redirection.
          // Stop further execution of this fetchAPI call.
          console.warn('fetchAPI: Token refresh failed and was handled by refreshAccessToken. Aborting current API request.');
          return Promise.reject(new Error('Token refresh failed; user redirected.'));
        }
      } catch (refreshError) {
        // This catch block might be redundant if refreshAccessToken handles all its own errors
        // and guarantees redirection. However, as a safeguard:
        console.error('fetchAPI: Unexpected error during token refresh process. Error:', refreshError);
        if (window.Auth && typeof window.Auth.logoutUser === 'function' && localStorage.getItem('dealFinderUser')) {
            window.Auth.logoutUser();
        }
        if (window.location.pathname !== '/login') { // Avoid redirect loops if already on login
            window.location.href = '/login?error=fetch_refresh_exception';
        }
        return Promise.reject(new Error('Critical token refresh error; user redirected.'));
      }
    }

    if (!options.headers) options.headers = {};
    if (token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }
    
    console.log(`API Request: ${API_BASE_URL}${endpoint}`);
    
    // Create an AbortController for timeout - with a longer timeout (30 seconds)
    const controller = new AbortController();
    const timeoutId = setTimeout(() => {
      console.log(`Request timeout for ${endpoint} after 30 seconds`);
      controller.abort();
    }, 30000); // 30 second timeout
    
    try {
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
    } finally {
      // Ensure timeout is cleared even if there's an error
      clearTimeout(timeoutId);
    }
  } catch (error) {
    console.error('API Request Error:', error);
    
    // Retry logic for network errors or timeouts
    if (retries > 0 && (
      error.name === 'AbortError' || 
      error.message.includes('network') || 
      error.message.includes('failed to fetch')
    )) {
      console.log(`Retrying request to ${endpoint}, ${retries} attempts left`);
      // Add a small delay before retrying
      await new Promise(resolve => setTimeout(resolve, 1000));
      return await fetchAPI(endpoint, options, retries - 1);
    }
    
    throw error;
  }
}

// Promotion API functions with fallback to local data
const PromotionAPI = {
  // Get all promotions
  getAll: async () => {
    try {
      return await fetchAPI('promotions');
    } catch (error) {
      console.warn('Failed to fetch promotions from API, using local data');
      // Return empty array to allow the app to use local data
      return [];
    }
  },
  
  // Get a promotion by ID
  getById: async (id) => {
    try {
      return await fetchAPI(`promotions/${id}`);
    } catch (error) {
      console.warn(`Failed to fetch promotion ${id}, using local data if available`);
      throw error;
    }
  },
  
  // Get promotions by merchant ID
  getByMerchant: async (merchantId) => {
    try {
      return await fetchAPI(`promotions/merchant/${merchantId}`);
    } catch (error) {
      console.warn(`Failed to fetch promotions for merchant ${merchantId}, using local data if available`);
      return [];
    }
  },

  // Get nearby promotions
  getNearby: async (latitude, longitude, radius) => {
    try {
      let endpoint = `promotions/nearby?latitude=${latitude}&longitude=${longitude}`;
      if (radius) {
        endpoint += `&radius=${radius}`;
      }
      return await fetchAPI(endpoint);
    } catch (error) {
      console.warn(`Failed to fetch nearby promotions for lat: ${latitude}, lon: ${longitude}`);
      // Decide on fallback behavior, e.g., return empty array or rethrow
      return []; // Or throw error;
    }
  },

  // Get all promotions for Admin view (includes filters, all statuses)
  adminGetAll: (filters = {}) => {
    // Construct query string from filters object
    const queryParams = new URLSearchParams(filters).toString();
    return fetchAPI(`admin/promotions${queryParams ? `?${queryParams}` : ''}`);
  },
  
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
  }),
  
  // Promotion click analytics
  recordClick: (promotionId, data) => fetchAPI(`promotions/${promotionId}/click`, {
    method: 'POST',
    body: JSON.stringify(data)
  }),
  getAnalyticsByMerchant: (merchantId) => fetchAPI(`promotions/analytics/merchant/${merchantId}`),
  getAnalyticsByPromotion: (promotionId) => fetchAPI(`promotions/${promotionId}/analytics`)
};

// Merchant API functions
const MerchantAPI = {
  // Get all merchants
  getAll: async () => {
    try {
      let result = await fetchAPI('merchants');
      if (!Array.isArray(result)) {
        console.warn('MerchantAPI.getAll: Expected array, got:', result);
        return [];
      }
      return result;
    } catch (error) {
      console.warn('Failed to fetch merchants from API, using local data if available');
      return [];
    }
  },
  
  // Get merchant by ID
  getById: (id) => fetchAPI(`merchants/${id}`),
  
  // Get merchant dashboard data
  getDashboard: (id) => fetchAPI(`merchants/${id}/dashboard`),
  
  // Update merchant profile
  update: (id, merchantData) => fetchAPI(`merchants/${id}`, {
    method: 'PUT',
    body: JSON.stringify(merchantData)
  }),

  // Create a new merchant (admin only)
  create: (merchantData) => fetchAPI('merchants', {
    method: 'POST',
    body: JSON.stringify(merchantData)
  }),

  // Delete a merchant (admin only based on backend route protection)
  delete: (id) => fetchAPI(`merchants/${id}`, {
    method: 'DELETE'
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

  // Get all users (for admin)
  getAll: () => fetchAPI('users'),
  
  // Get user profile
  getProfile: (id) => fetchAPI(`users/${id}`),
  
  // Update user profile (for general users updating their own profile)
  updateProfile: (id, userData) => fetchAPI(`users/${id}`, {
    method: 'PUT',
    body: JSON.stringify(userData)
  }),

  // Admin update user (can include role changes)
  adminUpdate: (id, userData) => fetchAPI(`users/${id}`, {
    method: 'PUT',
    body: JSON.stringify(userData) // Backend validates if admin is making the role change
  }),

  // Delete a user (for admin)
  delete: (id) => fetchAPI(`users/${id}`, {
    method: 'DELETE'
  }),

  // Change user password
  changePassword: (userId, passwordData) => fetchAPI(`users/${userId}/change-password`, {
    method: 'POST',
    body: JSON.stringify(passwordData)
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
  getFavorites: (userId) => fetchAPI(`users/${userId}/favorites`),

  // Initialize merchant profile for a user
  initializeMerchantProfile: (merchantData) => fetchAPI('users/initialize-merchant-profile', {
    method: 'POST',
    body: JSON.stringify(merchantData)
  })
};

// Admin specific API functions
const AdminAPI = {
  getDashboardStats: () => fetchAPI('admin/dashboard/stats'),
  // adminGetAllPromotions was already added to PromotionAPI, but could be here too
  // getAllPromotions: (filters = {}) => {
  //   const queryParams = new URLSearchParams(filters).toString();
  //   return fetchAPI(`admin/promotions${queryParams ? `?${queryParams}` : ''}`);
  // },
};

// Export all API helpers
window.API = {
  Promotions: PromotionAPI,
  Merchants: MerchantAPI,
  Users: UserAPI,
  Admin: AdminAPI, // Add Admin API group
};
