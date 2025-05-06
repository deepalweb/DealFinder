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
    promo.merchant.toLowerCase().includes(searchLower) ||
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
      return [...promotions].sort((a, b) =>
      new Date(b.startDate) - new Date(a.startDate));
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

// Favorites management functions
function getFavoritePromotions() {
  try {
    const favorites = localStorage.getItem('dealFinderFavorites');
    return favorites ? JSON.parse(favorites) : [];
  } catch (error) {
    console.error('Error getting favorites:', error);
    return [];
  }
}

function addToFavorites(promotion) {
  try {
    const favorites = getFavoritePromotions();
    // Check if already in favorites
    if (!favorites.some((fav) => fav.id === promotion.id)) {
      const updatedFavorites = [...favorites, promotion];
      localStorage.setItem('dealFinderFavorites', JSON.stringify(updatedFavorites));
      return true;
    }
    return false;
  } catch (error) {
    console.error('Error adding to favorites:', error);
    return false;
  }
}

function removeFromFavorites(promotionId) {
  try {
    const favorites = getFavoritePromotions();
    const updatedFavorites = favorites.filter((promo) => promo.id !== promotionId);
    localStorage.setItem('dealFinderFavorites', JSON.stringify(updatedFavorites));
    return true;
  } catch (error) {
    console.error('Error removing from favorites:', error);
    return false;
  }
}

function isPromotionFavorite(promotionId) {
  try {
    const favorites = getFavoritePromotions();
    return favorites.some((promo) => promo.id === promotionId);
  } catch (error) {
    console.error('Error checking favorite status:', error);
    return false;
  }
}

// Track promotion clicks for analytics
function trackPromotionClick(promotionId, promotionTitle, merchantName) {
  try {
    // Get existing analytics data or initialize empty array
    const analyticsData = localStorage.getItem('dealFinderAnalytics');
    const analytics = analyticsData ? JSON.parse(analyticsData) : [];

    // Add new click event
    analytics.push({
      promotionId,
      promotionTitle,
      merchantName,
      timestamp: new Date().toISOString(),
      type: 'click'
    });

    // Save updated analytics
    localStorage.setItem('dealFinderAnalytics', JSON.stringify(analytics));

    console.log(`Tracked click for promotion: ${promotionTitle}`);
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
  trackPromotionClick
};