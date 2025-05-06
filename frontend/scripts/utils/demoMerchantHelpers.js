// Helper functions for demo merchant functionality
window.DemoMerchantHelpers = {
  // Get demo promotions from localStorage or create defaults
  getDemoPromotions: function() {
    try {
      const stored = localStorage.getItem('demoMerchantPromotions');
      if (stored) {
        return JSON.parse(stored);
      }
      
      // Default promotions if none exist
      const defaultPromotions = [
        {
          _id: 'demo1',
          title: "Demo Promotion - 30% Off All Products",
          description: "This is a demo promotion. In a real app, this would be fetched from the database.",
          discount: "30%",
          code: "DEMO30",
          category: "electronics",
          startDate: new Date().toISOString(),
          endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
          status: "active",
          image: "https://images.unsplash.com/photo-1498049794561-7780e7231661?q=80&w=2670&auto=format&fit=crop",
          merchant: 'demo456'
        },
        {
          _id: 'demo2',
          title: "Demo Flash Sale - Buy One Get One Free",
          description: "Another demo promotion. You can add, edit, and delete these for testing purposes.",
          discount: "BOGO",
          code: "DEMOBOGO",
          category: "fashion",
          startDate: new Date().toISOString(),
          endDate: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
          status: "expired",
          image: "https://images.unsplash.com/photo-1519389950473-47ba0277781c?q=80&w=2670&auto=format&fit=crop",
          merchant: 'demo456'
        }
      ];
      
      // Save default promotions
      localStorage.setItem('demoMerchantPromotions', JSON.stringify(defaultPromotions));
      return defaultPromotions;
    } catch (error) {
      console.error('Error getting demo promotions:', error);
      return [];
    }
  },
  
  // Save demo promotions to localStorage
  saveDemoPromotions: function(promotions) {
    try {
      localStorage.setItem('demoMerchantPromotions', JSON.stringify(promotions));
      return true;
    } catch (error) {
      console.error('Error saving demo promotions:', error);
      return false;
    }
  }
};