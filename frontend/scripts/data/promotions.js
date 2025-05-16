// Get promotions data from multiple sources
window.getPromotionsData = async function() {
  // Only fetch promotions from API
  try {
    const promotions = await window.API.Promotions.getAll();
    return promotions;
  } catch (error) {
    console.error('Error fetching promotions from API:', error);
    return [];
  }
};

// Initialize promotionsData with default promotions
window.promotionsData = [
  // Default promotions will be replaced when getPromotionsData() is called
];