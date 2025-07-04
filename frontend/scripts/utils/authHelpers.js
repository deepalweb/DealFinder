// Authentication helper functions

// Check if user is logged in
function isLoggedIn() {
  return localStorage.getItem('dealFinderUser') !== null;
}

// Get current user data
function getCurrentUser() {
  const userData = localStorage.getItem('dealFinderUser');
  if (!userData) return null;
  
  try {
    return JSON.parse(userData);
  } catch (error) {
    console.error('Error parsing user data:', error);
    return null;
  }
}

// Check if user is a merchant
function isMerchant() {
  const user = getCurrentUser();
  return user && user.role === 'merchant';
}

// Check if user is an admin
function isAdmin() {
  const user = getCurrentUser();
  return user && user.role === 'admin';
}

// Login user (store in localStorage)
function loginUser(userData) {
  localStorage.setItem('dealFinderUser', JSON.stringify(userData));
}

// Logout user
async function logoutUser() {
  const currentUser = getCurrentUser(); // Get user before clearing localStorage
  const refreshToken = currentUser && currentUser.refreshToken ? currentUser.refreshToken : null;

  // Always clear local storage immediately for responsiveness
  localStorage.removeItem('dealFinderUser');
  console.log('User logged out from client-side. Local storage cleared.');

  if (refreshToken && window.API_BASE_URL) {
    try {
      console.log('Attempting to invalidate refresh token on backend...');
      const response = await fetch(`${window.API_BASE_URL}users/logout`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refreshToken })
      });
      if (response.ok) {
        console.log('Refresh token invalidated on backend successfully.');
      } else {
        const errorData = await response.json().catch(() => ({}));
        console.warn('Failed to invalidate refresh token on backend:', response.status, errorData.message);
      }
    } catch (error) {
      console.error('Error calling backend logout:', error);
    }
  } else if (!refreshToken) {
    console.warn('No refresh token found, skipping backend logout call.');
  } else if (!window.API_BASE_URL) {
    console.error('API_BASE_URL not defined, skipping backend logout call.');
  }
  // Note: Redirection after logout is typically handled by the calling context,
  // e.g., if (logoutUser()) window.location.href = '/login';
}

// Register and login
async function registerAndLogin(userData) {
  try {
    // Register user
    const newUser = await window.API.Users.register(userData);
    
    // Login user
    loginUser(newUser);
    
    return newUser;
  } catch (error) {
    console.error('Registration error:', error);
    throw error;
  }
}

// Login with credentials
async function loginWithCredentials(email, password) {
  try {
    // Login via API
    const userData = await window.API.Users.login({ email, password });
    
    // Store user data
    loginUser(userData);
    
    return userData;
  } catch (error) {
    console.error('Login error:', error);
    throw error;
  }
}

// Update user profile
async function updateUserProfile(userId, userData) {
  try {
    // Update via API
    const updatedUser = await window.API.Users.updateProfile(userId, userData);
    
    // Update stored user data
    const currentUser = getCurrentUser();
    if (currentUser && currentUser._id === userId) {
      loginUser({...currentUser, ...updatedUser});
    }
    
    return updatedUser;
  } catch (error) {
    console.error('Profile update error:', error);
    throw error;
  }
}

// Get JWT token from localStorage (if available)
function getAuthToken() {
  const user = getCurrentUser();
  return user && user.token ? user.token : null;
}

// Check if JWT token is expired
function isTokenExpired(token) {
  if (!token) return true;
  try {
    const payload = JSON.parse(atob(token.split('.')[1]));
    return payload.exp * 1000 < Date.now();
  } catch (e) {
    return true;
  }
}

// Get a new access token using refresh token
async function refreshAccessToken() {
  const currentUser = getCurrentUser();
  const refreshToken = currentUser && currentUser.refreshToken ? currentUser.refreshToken : null;

  if (!window.API_BASE_URL) {
    console.error("API_BASE_URL is not defined. Ensure apiHelpers.js is loaded before authHelpers.js and then authHelpers.js.");
    // Cannot proceed without API_BASE_URL, this is a critical setup error.
    // Forcing logout/redirect might be too aggressive if other parts of app could work.
    // However, auth is critical. For now, let's assume this implies a broken state.
    if (isLoggedIn()) logoutUser(); // Attempt to clear session
    window.location.href = '/login?error=config_error'; // Redirect with error
    return null; // Signal failure
  }

  if (!refreshToken) {
    console.warn('No refresh token found. Redirecting to login.');
    if (isLoggedIn()) logoutUser(); // Clear any partial session if exists
    window.location.href = '/login?error=no_refresh_token';
    return null; // Signal failure
  }

  try {
    const response = await fetch(`${window.API_BASE_URL}users/refresh-token`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken })
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({ message: 'Failed to parse error response from refresh token endpoint.' }));
      console.error('Failed to refresh token:', response.status, errorData.message);
      // Regardless of specific error, if refresh fails, treat as session expiry.
      logoutUser(); // This will clear dealFinderUser from localStorage
      window.location.href = `/login?error=refresh_failed&status=${response.status}`; // Redirect to login
      return null; // Signal failure
    }

    const data = await response.json();
    const newAccessToken = data.token;

    if (newAccessToken && currentUser) {
      const updatedUserData = { ...currentUser, token: newAccessToken };
      loginUser(updatedUserData); // loginUser updates localStorage
      console.log('Access token refreshed successfully via refreshAccessToken.');
      return newAccessToken;
    } else {
      // This case should ideally not be reached if response.ok and data.token is present
      console.error('Refresh token endpoint responded OK but no new access token was provided.');
      logoutUser();
      window.location.href = '/login?error=refresh_no_token';
      return null; // Signal failure
    }
  } catch (error) {
    // This catches network errors or issues with fetch itself
    console.error('Network or other critical error during refreshAccessToken:', error);
    logoutUser(); // Ensure user is logged out
    window.location.href = '/login?error=refresh_network_error';
    return null; // Signal failure
  }
}

// Export auth functions to window object for global access
window.Auth = {
  isLoggedIn,
  getCurrentUser,
  isMerchant,
  isAdmin,
  loginUser,
  logoutUser,
  registerAndLogin,
  loginWithCredentials,
  updateUserProfile,
  getAuthToken,
  isTokenExpired,
  refreshAccessToken,
};