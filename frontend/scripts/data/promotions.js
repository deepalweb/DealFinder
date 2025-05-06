// Get promotions data from multiple sources
window.getPromotionsData = async function() {
  // Start with the default mock promotions
  let allPromotions = [
    {
      id: 1,
      title: "Summer Sale - Extra 20% Off All Items",
      merchant: "Fashion Nova",
      description: "Take an extra 20% off all summer collection items. Perfect for updating your wardrobe for the season.",
      discount: "20%",
      code: "SUMMER20",
      category: "fashion",
      startDate: "2023-06-01",
      endDate: "2023-08-31",
      image: "https://images.unsplash.com/photo-1607083206968-13611e3d76db?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=2215&q=80",
      url: "https://example.com/fashion-sale",
      featured: true
    },
    {
      id: 2,
      title: "Tech Tuesday - $50 Off Electronics",
      merchant: "TechGiant",
      description: "Every Tuesday, save $50 on purchases over $200 on all electronics, including smartphones, laptops, and smart home devices.",
      discount: "$50",
      code: "TECH50",
      category: "electronics",
      startDate: "2023-05-15",
      endDate: "2023-12-31",
      image: "https://images.unsplash.com/photo-1550009158-9ebf69173e03?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1201&q=80",
      featured: true
    },
    {
      id: 3,
      title: "Weekend Getaway - 30% Off Hotel Bookings",
      merchant: "TravelEasy",
      description: "Plan your next weekend escape with 30% off hotel bookings. Valid for stays from Friday to Sunday.",
      discount: "30%",
      code: "WEEKEND30",
      category: "travel",
      startDate: "2023-06-10",
      endDate: "2023-09-30",
      image: "https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1470&q=80",
      featured: false
    },
    {
      id: 4,
      title: "Healthy Savings - Buy One, Get One Free",
      merchant: "Wellness Market",
      description: "Buy any vitamin or supplement and get another of equal or lesser value free. Stock up on your wellness essentials.",
      discount: "BOGO",
      code: "BOGO2023",
      category: "health",
      startDate: "2023-07-01",
      endDate: "2023-07-31",
      image: "https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1471&q=80",
      featured: false
    },
    {
      id: 5,
      title: "Game On - 25% Off All Video Games",
      merchant: "GameStop",
      description: "Level up your gaming experience with 25% off all video games, including new releases and pre-orders.",
      discount: "25%",
      code: "GAMEON25",
      category: "entertainment",
      startDate: "2023-06-15",
      endDate: "2023-07-15",
      image: "https://images.unsplash.com/photo-1593118247619-e2d6f056869e?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1170&q=80",
      url: "https://example.com/game-deals",
      featured: true
    },
    {
      id: 6,
      title: "Book Lovers' Delight - 40% Off Second Book",
      merchant: "Read More Books",
      description: "Buy any book and get 40% off your second purchase. Perfect for stocking up your summer reading list.",
      discount: "40%",
      code: "BOOKWORM40",
      category: "entertainment",
      startDate: "2023-07-01",
      endDate: "2023-08-31",
      image: "https://images.unsplash.com/photo-1543002588-bfa74002ed7e?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1330&q=80",
      featured: false
    },
    {
      id: 7,
      title: "Home Improvement - $100 Off $500+ Purchase",
      merchant: "HomeFix",
      description: "Renovating your space? Save $100 when you spend $500 or more on home improvement products.",
      discount: "$100",
      code: "IMPROVE100",
      category: "home",
      startDate: "2023-06-01",
      endDate: "2023-08-15",
      image: "https://images.unsplash.com/photo-1556908250-2389c363d1cb?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1172&q=80",
      featured: false
    },
    {
      id: 8,
      title: "Pet Parents Special - 15% Off All Pet Supplies",
      merchant: "PetLovers",
      description: "Treat your furry friends with 15% off all pet supplies, including food, toys, and accessories.",
      discount: "15%",
      code: "PETLOVE15",
      category: "pets",
      startDate: "2023-07-10",
      endDate: "2023-07-20",
      image: "https://images.unsplash.com/photo-1601758124277-f0086d5ab050?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1176&q=80",
      featured: false
    },
    {
      id: 9,
      title: "New Restaurant Opening - 50% Off First Order",
      merchant: "Urban Eats",
      description: "Celebrate our grand opening with 50% off your first order. Try our signature dishes at a special introductory price.",
      discount: "50%",
      code: "WELCOME50",
      category: "food",
      startDate: "2023-07-15",
      endDate: "2023-08-15",
      image: "https://images.unsplash.com/photo-1482275548304-a58859dc31b7?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1174&q=80",
      url: "https://example.com/restaurant-deal",
      featured: true
    },
    {
      id: 10,
      title: "Fitness Flash Sale - 35% Off Gym Memberships",
      merchant: "FitLife Gym",
      description: "Get in shape with our flash sale! 35% off all new gym memberships, plus a free personal training session.",
      discount: "35%",
      code: "FITFLASH35",
      category: "health",
      startDate: "2023-07-05",
      endDate: "2023-07-07",
      image: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1170&q=80",
      featured: false
    },
    {
      id: 11,
      title: "Back to School - 10% Off School Supplies",
      merchant: "Office Depot",
      description: "Prepare for the new school year with 10% off all school supplies, including notebooks, pens, and backpacks.",
      discount: "10%",
      code: "SCHOOL10",
      category: "education",
      startDate: "2023-08-01",
      endDate: "2023-09-15",
      image: "https://images.unsplash.com/photo-1497633762265-9d179a990aa6?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3MTg3MTl8MHwxfHNlYXJjaHwxfHxBJTIwY29sbGVjdGlvbiUyMG9mJTIwc2Nob29sJTIwc3VwcGxpZXMlMjBpbmNsdWRpbmclMjBub3RlYm9va3MlMkMlMjBwZW5zJTJDJTIwYW5kJTIwYSUyMGJhY2twYWNrJTJDJTIwYXJyYW5nZWQlMjBvbiUyMGElMjBkZXNrLnxlbnwwfHx8fDE3NDYyNTE3Mzh8MA&ixlib=rb-4.0.3&q=80&w=200$w=1074",
      featured: false
    },
    {
      id: 12,
      title: "Anniversary Sale - 45% Off Everything",
      merchant: "HomeStyle",
      description: "Celebrating 10 years with our biggest sale ever! 45% off all home decor, furniture, and kitchen items.",
      discount: "45%",
      code: "DECADE45",
      category: "home",
      startDate: "2023-07-10",
      endDate: "2023-07-15",
      image: "https://images.unsplash.com/photo-1515378791036-0648a3ef77b2?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1170&q=80",
      featured: true
    }
  ];
  
  try {
    // Try to fetch promotions from the API
    const apiPromotions = await window.API.Promotions.getAll().catch(err => {
      console.log('Could not fetch promotions from API, using local data only');
      return [];
    });
    
    if (apiPromotions && apiPromotions.length > 0) {
      // Format API promotions to match the structure expected by the app
      const formattedApiPromotions = apiPromotions.map(promo => {
        return {
          id: promo._id,
          title: promo.title,
          merchant: promo.merchant ? promo.merchant.name || "Unknown Merchant" : "Unknown Merchant",
          description: promo.description,
          discount: promo.discount,
          code: promo.code,
          category: promo.category,
          startDate: promo.startDate,
          endDate: promo.endDate,
          image: promo.image,
          url: promo.url,
          featured: promo.status === 'active' // Make active promotions featured
        };
      });
      
      // Add API promotions to the list
      allPromotions = [...allPromotions, ...formattedApiPromotions];
    }
  } catch (error) {
    console.error('Error fetching promotions from API:', error);
  }
  
  // Check if there are any demo merchant promotions
  try {
    if (window.DemoMerchantHelpers) {
      const demoPromotions = window.DemoMerchantHelpers.getDemoPromotions() || [];
      
      // Convert demo promotions to match the format of the default promotions
      const formattedDemoPromotions = demoPromotions.map(promo => {
        return {
          id: promo._id,
          title: promo.title,
          merchant: "Demo Merchant Shop",
          description: promo.description,
          discount: promo.discount,
          code: promo.code,
          category: promo.category,
          startDate: promo.startDate,
          endDate: promo.endDate,
          image: promo.image,
          url: promo.url,
          featured: promo.status === 'active' // Make active promotions featured
        };
      });
      
      // Add demo promotions to the list
      allPromotions = [...allPromotions, ...formattedDemoPromotions];
    }
  } catch (error) {
    console.error('Error loading demo promotions:', error);
  }
  
  return allPromotions;
};

// Initialize promotionsData with default promotions
window.promotionsData = [
  // Default promotions will be replaced when getPromotionsData() is called
];