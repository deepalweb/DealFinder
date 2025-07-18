// Notification Helper Functions

// Get user's notification settings from the user object
function getUserNotificationSettings() {
  const currentUser = getCurrentUser();

  // If there's a user and they have settings, return them
  if (currentUser && currentUser.notificationSettings) {
    return currentUser.notificationSettings;
  }

  // Default settings if user or settings are not found
  return {
    expiringDeals: true,
    recommendations: true,
    favoriteStores: true,
  };
}

// Queue an email notification
async function queueEmailNotification(userEmail, subject, message, templateName = 'default') {
  // In a real app, this would send a request to the backend to queue an email
  // For now, we'll simulate by storing in localStorage

  try {
    const notifications = JSON.parse(localStorage.getItem('dealFinderNotifications') || '[]');

    notifications.push({
      id: Date.now(),
      userEmail,
      subject,
      message,
      templateName,
      status: 'queued',
      createdAt: new Date().toISOString()
    });

    localStorage.setItem('dealFinderNotifications', JSON.stringify(notifications));

    // Also send a push notification
    const user = getCurrentUser();
    if (user && user.pushSubscription) {
      await sendPushNotification(user.pushSubscription, subject, message);
    }

    return true;
  } catch (error) {
    console.error('Error queueing notification:', error);
    return false;
  }
}

// Send a push notification
async function sendPushNotification(subscription, title, body) {
    try {
        const user = getCurrentUser();
        if (user) {
            await fetch('/api/push/notify', {
                method: 'POST',
                body: JSON.stringify({ subscription, title, body, userId: user.id }),
                headers: {
                    'Content-Type': 'application/json'
                }
            });
        }
    } catch (error) {
        console.error('Error sending push notification:', error);
    }
}

// Helper to get merchant name from string or object
function getMerchantName(merchant) {
  if (!merchant) return '';
  if (typeof merchant === 'string') return merchant;
  if (typeof merchant === 'object' && merchant.name) return merchant.name;
  return '';
}

// Check for deals about to expire and send notifications
async function checkExpiringDeals() {
  try {
    // Get current user and their saved promotions
    const currentUser = getCurrentUser();
    if (!currentUser) return;

    // Check notification preferences
    const notifSettings = getUserNotificationSettings();
    if (!notifSettings?.expiringDeals) return;

    // Get user's favorite promotions
    const favorites = await window.API.Users.getFavorites(currentUser._id);

    // Find promotions expiring in the next 2 days
    const twoDaysFromNow = new Date();
    twoDaysFromNow.setDate(twoDaysFromNow.getDate() + 2);

    const expiringDeals = favorites.filter((promo) => {
      const endDate = new Date(promo.endDate);
      return endDate <= twoDaysFromNow && endDate >= new Date();
    });

    // Queue notifications for each expiring deal
    expiringDeals.forEach((deal) => {
      const daysLeft = calculateDaysRemaining(deal.endDate);
      const dayText = daysLeft === 0 ? 'today' : daysLeft === 1 ? 'tomorrow' : `in ${daysLeft} days`;

      queueEmailNotification(
        currentUser.email,
        `Deal Expiring Soon: ${deal.title}`,
        `Your saved deal "${deal.title}" from ${deal.merchant} is expiring ${dayText}. Don't miss out on the ${deal.discount} discount! Use code: ${deal.code}`,
        'deal-expiring'
      );
    });

    return expiringDeals.length;
  } catch (error) {
    console.error('Error checking expiring deals:', error);
    return 0;
  }
}

// Generate personalized deal recommendations
async function generateDealRecommendations() {
  try {
    // Get current user
    const currentUser = getCurrentUser();
    if (!currentUser) return [];

    // Check notification preferences
    const notifSettings = getUserNotificationSettings();
    if (!notifSettings?.recommendations) return [];

    // Get user's favorites to analyze preferences
    const favorites = await window.API.Users.getFavorites(currentUser._id);
    if (favorites.length === 0) return [];

    // Extract categories from favorites
    const favoriteCategories = {};
    favorites.forEach((deal) => {
      favoriteCategories[deal.category] = (favoriteCategories[deal.category] || 0) + 1;
    });

    // Sort categories by count
    const topCategories = Object.entries(favoriteCategories).
    sort((a, b) => b[1] - a[1]).
    slice(0, 3).
    map((entry) => entry[0]);

    // Get merchants user follows
    const followedMerchants = getFollowedMerchants();
    const followedMerchantNames = followedMerchants.map((m) => m.name.toLowerCase());

    // Find recommendations from all promotions
    const recommendations = promotionsData
    .map(p => ({ ...p, id: p.id || p._id }))
    .filter((promo) => {
      // Must not be already in favorites
      if (favorites.some((fav) => fav.id === promo.id)) return false;

      // Must be active
      const endDate = new Date(promo.endDate);
      if (endDate < new Date()) return false;

      // Either match a top category or from a followed merchant
      return (
        topCategories.includes(promo.category) ||
        followedMerchantNames.includes(getMerchantName(promo.merchant).toLowerCase())
      );

    });

    // Sort recommendations by relevance
    return recommendations.
    slice(0, 6).
    sort((a, b) => {
      // Followed merchants take precedence
      const aIsFollowed = followedMerchantNames.includes(getMerchantName(a.merchant).toLowerCase());
      const bIsFollowed = followedMerchantNames.includes(getMerchantName(b.merchant).toLowerCase());

      if (aIsFollowed && !bIsFollowed) return -1;
      if (!aIsFollowed && bIsFollowed) return 1;

      // Then check top categories
      const aTopCategoryIndex = topCategories.indexOf(a.category);
      const bTopCategoryIndex = topCategories.indexOf(b.category);

      if (aTopCategoryIndex !== -1 && bTopCategoryIndex !== -1) {
        return aTopCategoryIndex - bTopCategoryIndex;
      }

      if (aTopCategoryIndex !== -1) return -1;
      if (bTopCategoryIndex !== -1) return 1;

      // Finally sort by discount amount
      return parseInt(b.discount) - parseInt(a.discount);
    });
  } catch (error) {
    console.error('Error generating recommendations:', error);
    return [];
  }
}

// Send notification about recommendations
function sendRecommendationNotifications() {
  try {
    const currentUser = getCurrentUser();
    if (!currentUser) return false;

    // Check notification preferences
    const notifSettings = getUserNotificationSettings();
    if (!notifSettings?.recommendations) return false;

    // Get recommendations
    const recommendations = generateDealRecommendations();
    if (recommendations.length === 0) return false;

    // Create notification message with top 3 recommendations
    const topThree = recommendations.slice(0, 3);
    const recommendationText = topThree.map((deal) =>
    `${deal.merchant}: ${deal.title} - ${deal.discount} OFF`
    ).join('\n');

    queueEmailNotification(
      currentUser.email,
      'Deals We Think You\'ll Love',
      `Based on your interests, we've found these deals for you:\n\n${recommendationText}\n\nCheck out your account for more personalized recommendations!`,
      'recommendations'
    );

    return true;
  } catch (error) {
    console.error('Error sending recommendation notifications:', error);
    return false;
  }
}

// Export notification functions to window object for global access
window.Notifications = {
  queueEmailNotification,
  sendPushNotification,
  checkExpiringDeals,
  generateDealRecommendations,
  sendRecommendationNotifications,
  sendNewMerchantDealNotifications,
  getUserNotificationSettings,
};

// Send notification about new deals from followed merchants
function sendNewMerchantDealNotifications() {
  try {
    const currentUser = getCurrentUser();
    if (!currentUser) return false;

    // Check notification preferences
    const notifSettings = getUserNotificationSettings();
    if (!notifSettings?.favoriteStores) return false;

    // Get followed merchants
    const followedMerchants = getFollowedMerchants();
    if (followedMerchants.length === 0) return false;

    const followedMerchantNames = followedMerchants.map((m) => m.name.toLowerCase());

    // Get "new" deals from followed merchants (in a real app, this would check deals added since last notification)
    // For demo purposes, we'll pretend the newest deals are new
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);

    const newDeals = promotionsData.filter((promo) => {
      return (
        followedMerchantNames.includes(promo.merchant.toLowerCase()) &&
        new Date(promo.endDate) > new Date() && // Active deals only
        new Date(promo.startDate) >= yesterday // Pretending these are new
      );
    });

    if (newDeals.length === 0) return false;

    // Group by merchant
    const dealsByMerchant = {};
    newDeals.forEach((deal) => {
      const merchantName = getMerchantName(deal.merchant);
      if (!dealsByMerchant[merchantName]) {
        dealsByMerchant[merchantName] = [];
      }
      dealsByMerchant[merchantName].push(deal);
    });

    // Send notification for each merchant with new deals
    Object.entries(dealsByMerchant).forEach(([merchant, deals]) => {
      const dealsText = deals.map((deal) =>
        `${deal.title} - ${deal.discount} OFF`
      ).join('\n');

      queueEmailNotification(
        currentUser.email,
        `New Deals from ${merchant}`,
        `${merchant} just added ${deals.length} new deal${deals.length > 1 ? 's' : ''}:\n\n${dealsText}\n\nDon't miss out!`,
        'merchant-deals'
      );
    });

    return true;
  } catch (error) {
    console.error('Error sending merchant deal notifications:', error);
    return false;
  }
}