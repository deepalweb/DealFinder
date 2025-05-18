// Helper functions for the application

// Format date for display
function formatDate(dateString) {
  const options = { year: 'numeric', month: 'short', day: 'numeric' };
  return new Date(dateString).toLocaleDateString('en-US', options);
}

// Calculate days remaining until end date
function calculateDaysRemaining(endDate) {
  const end = new Date(endDate);
  const now = new Date();
  const diffTime = end - now;
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  return diffDays;
}

// Get text representation of days remaining
function getDaysText(days) {
  if (days < 0) return 'Expired';
  if (days === 0) return 'Last day';
  if (days === 1) return '1 day left';
  return `${days} days left`;
}

// Copy text to clipboard
function copyToClipboard(text) {
  navigator.clipboard.writeText(text).then(() => {
    // Success copied
    alert('Coupon code copied to clipboard!');
  }, (err) => {
    console.error('Could not copy text: ', err);
  });
}

// Helper to get merchant name from string or object
function getMerchantName(merchant) {
  if (!merchant) return '';
  if (typeof merchant === 'string') return merchant;
  if (typeof merchant === 'object' && merchant.name) return merchant.name;
  return '';
}

// Filter promotions based on criteria
function filterPromotions(promotions, filters) {
  let filteredPromos = [...promotions];

  // Filter by category
  if (filters.category && filters.category !== 'all') {
    filteredPromos = filteredPromos.filter((promo) =>
      promo.category === filters.category);
  }

  // Filter by search term
  if (filters.searchTerm) {
    const searchLower = filters.searchTerm.toLowerCase();
    filteredPromos = filteredPromos.filter((promo) =>
      promo.title.toLowerCase().includes(searchLower) ||
      getMerchantName(promo.merchant).toLowerCase().includes(searchLower) ||
      promo.description.toLowerCase().includes(searchLower)
    );
  }

  // Filter by active promotions
  if (filters.onlyActive) {
    const today = new Date();
    filteredPromos = filteredPromos.filter((promo) =>
      new Date(promo.endDate) >= today);
  }

  return filteredPromos;
}

// Sort promotions by different criteria
function sortPromotions(promotions, sortBy) {
  const today = new Date();

  switch (sortBy) {
    case 'newest':
      // Sort by createdAt if available, fallback to startDate
      return [...promotions].sort((a, b) => {
        const aDate = a.createdAt ? new Date(a.createdAt) : new Date(a.startDate);
        const bDate = b.createdAt ? new Date(b.createdAt) : new Date(b.startDate);
        return bDate - aDate;
      });
    case 'ending-soon':
      return [...promotions].sort((a, b) => {
        // Filter out expired deals
        const aEndDate = new Date(a.endDate);
        const bEndDate = new Date(b.endDate);
        if (aEndDate < today && bEndDate >= today) return 1;
        if (bEndDate < today && aEndDate >= today) return -1;
        if (aEndDate < today && bEndDate < today) return 0;
        return aEndDate - bEndDate;
      });
    case 'discount':
      return [...promotions].sort((a, b) =>
      parseInt(b.discount) - parseInt(a.discount));
    default:
      return promotions;
  }
}

// Favorites management functions (DEPRECATED: Use backend API via window.API.Users instead)
function getFavoritePromotions() {
  console.warn('getFavoritePromotions is deprecated. Use backend API via window.API.Users.getFavorites');
  return [];
}

function addToFavorites(promotion) {
  console.warn('addToFavorites is deprecated. Use backend API via window.API.Users.addFavorite');
  return false;
}

function removeFromFavorites(promotionId) {
  console.warn('removeFromFavorites is deprecated. Use backend API via window.API.Users.removeFavorite');
  return false;
}

function isPromotionFavorite(promotionId) {
  console.warn('isPromotionFavorite is deprecated. Use backend API to check favorite status.');
  return false;
}

// Track promotion clicks for analytics
function trackPromotionClick(promotionId, promotionTitle, merchantName) {
  try {
    const userData = localStorage.getItem('dealFinderUser');
    const userId = userData ? JSON.parse(userData)._id : null;
    window.API.Promotions.recordClick(promotionId, {
      promotionTitle,
      merchantName,
      userId,
      type: 'click'
    });
  } catch (error) {
    console.error('Error tracking promotion click:', error);
  }
}

// Export helper functions to window object for global access
window.Helpers = {
  formatDate,
  calculateDaysRemaining,
  getDaysText,
  copyToClipboard,
  filterPromotions,
  sortPromotions,
  getFavoritePromotions,
  addToFavorites,
  removeFromFavorites,
  isPromotionFavorite,
  trackPromotionClick,
  getMerchantName
};