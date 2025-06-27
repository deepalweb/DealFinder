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
  window.dispatchEvent(new CustomEvent('authStateChange'));
}

// Logout user
function logoutUser() {
  localStorage.removeItem('dealFinderUser');
  window.dispatchEvent(new CustomEvent('authStateChange'));
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
async function refreshAccessToken(refreshToken) {
  try {
    const response = await fetch('/api/users/refresh-token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken })
    });
    if (!response.ok) throw new Error('Failed to refresh token');
    const data = await response.json();
    return data.token;
  } catch (error) {
    return null;
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