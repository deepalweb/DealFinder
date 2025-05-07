function MerchantListPage() {
  const { useState, useEffect } = React;
  const { Link } = ReactRouterDOM;

  const [merchants, setMerchants] = useState([]);
  const [filteredMerchants, setFilteredMerchants] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [error, setError] = useState(null);

  useEffect(() => {
    // Fetch merchants from API
    const fetchMerchants = async () => {
      try {
        setLoading(true);
        
        // Try to fetch merchants from API
        let merchantsData = [];
        try {
          merchantsData = await window.API.Merchants.getAll();
          console.log("Merchants from API:", merchantsData);
        } catch (apiError) {
          console.error("Error fetching merchants from API:", apiError);
          // If API fails, fall back to mock data
          merchantsData = [];
        }
        
        // If no merchants from API or API failed, use mock data
        if (!merchantsData || merchantsData.length === 0) {
          console.log("Using mock merchant data");
          merchantsData = [
            {
              id: 1,
              name: "Fashion Nova",
              logo: "https://images.unsplash.com/photo-1607083206968-13611e3d76db?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=300&q=80",
              category: "fashion",
              description: "Fast fashion retail company offering trendy clothes and accessories.",
              activeDeals: 5,
              followers: 15750
            },
            {
              id: 2,
              name: "TechGiant",
              logo: "https://images.unsplash.com/photo-1550009158-9ebf69173e03?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=300&q=80",
              category: "electronics",
              description: "Your one-stop shop for all electronics needs from smartphones to laptops.",
              activeDeals: 3,
              followers: 12300
            },
            {
              id: 3,
              name: "TravelEasy",
              logo: "https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=300&q=80",
              category: "travel",
              description: "Book flights, hotels, and vacation packages at discounted rates.",
              activeDeals: 2,
              followers: 8450
            },
            {
              id: 4,
              name: "Wellness Market",
              logo: "https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=300&q=80",
              category: "health",
              description: "Premium health and wellness products for a better lifestyle.",
              activeDeals: 4,
              followers: 6200
            },
            {
              id: 5,
              name: "GameStop",
              logo: "https://images.unsplash.com/photo-1593118247619-e2d6f056869e?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=300&q=80",
              category: "entertainment",
              description: "Video games, consoles, and gaming accessories for all platforms.",
              activeDeals: 3,
              followers: 9800
            },
            {
              id: 6,
              name: "Read More Books",
              logo: "https://images.unsplash.com/photo-1543002588-bfa74002ed7e?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=300&q=80",
              category: "entertainment",
              description: "Huge selection of books, from bestsellers to rare finds.",
              activeDeals: 2,
              followers: 4700
            },
            {
              id: 7,
              name: "HomeFix",
              logo: "https://images.unsplash.com/photo-1522444195799-478538b28823?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3MTg3MTl8MHwxfHNlYXJjaHwxfHxBJTIwcGhvdG8lMjBvZiUyMGElMjBob21lJTIwaW1wcm92ZW1lbnQlMjBwcm9qZWN0JTJDJTIwc2hvd2Nhc2luZyUyMHRvb2xzJTIwYW5kJTIwbWF0ZXJpYWxzLnxlbnwwfHx8fDE3NDYyNTI3MTd8MA&ixlib=rb-4.0.3&q=80&w=200$w=300",
              category: "home",
              description: "Everything you need for home improvement and renovation projects.",
              activeDeals: 3,
              followers: 7300
            },
            {
              id: 8,
              name: "PetLovers",
              logo: "https://images.unsplash.com/photo-1601758124277-f0086d5ab050?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=300&q=80",
              category: "pets",
              description: "Premium pet supplies, food, toys, and accessories for all animals.",
              activeDeals: 2,
              followers: 5600
            },
            {
              id: 9,
              name: "Urban Eats",
              logo: "https://images.unsplash.com/photo-1482275548304-a58859dc31b7?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=300&q=80",
              category: "food",
              description: "Delicious meals from various cuisines, delivered straight to your door.",
              activeDeals: 4,
              followers: 8200
            },
            {
              id: 10,
              name: "FitLife Gym",
              logo: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=300&q=80",
              category: "health",
              description: "State-of-the-art fitness centers with personal training and classes.",
              activeDeals: 2,
              followers: 6100
            }
          ];
        }
        
        // Check for real merchants from database
        const realMerchants = await window.API.Merchants.getAll().catch(() => []);
        
        // Combine real merchants with mock data if needed
        if (realMerchants && realMerchants.length > 0) {
          // Format real merchants to match the expected structure
          const formattedRealMerchants = realMerchants.map(merchant => ({
            id: merchant._id,
            name: merchant.name,
            // Use a default image based on the first letter of the merchant name
            logo: merchant.logo || `https://ui-avatars.com/api/?name=${encodeURIComponent(merchant.name)}&background=random&size=300`,
            category: merchant.category || "other",
            description: merchant.profile || `${merchant.name} offers great deals and promotions.`,
            activeDeals: merchant.promotions?.length || 0,
            followers: merchant.followers || Math.floor(Math.random() * 10000)
          }));
          
          // Add real merchants to the list
          merchantsData = [...formattedRealMerchants, ...merchantsData];
        }

        setMerchants(merchantsData);
        setFilteredMerchants(merchantsData);
      } catch (err) {
        console.error("Error in merchant fetch:", err);
        setError("Failed to load merchants. Please try again later.");
      } finally {
        setLoading(false);
      }
    };

    fetchMerchants();
  }, []);

  useEffect(() => {
    // Filter merchants based on search term and category
    let results = [...merchants];

    if (searchTerm) {
      const term = searchTerm.toLowerCase();
      results = results.filter((merchant) =>
      merchant.name.toLowerCase().includes(term) ||
      (merchant.description && merchant.description.toLowerCase().includes(term))
      );
    }

    if (selectedCategory !== 'all') {
      results = results.filter((merchant) => merchant.category === selectedCategory);
    }

    setFilteredMerchants(results);
  }, [searchTerm, selectedCategory, merchants]);

  const handleSearch = (e) => {
    setSearchTerm(e.target.value);
  };

  const handleCategoryChange = (category) => {
    setSelectedCategory(category);
  };

  if (loading) {
    return (
      <div className="page-container">
        <div className="container py-8 text-center">
          <i className="fas fa-spinner fa-spin text-3xl text-primary-color"></i>
        </div>
      </div>);
  }

  if (error) {
    return (
      <div className="page-container">
        <div className="container py-8 text-center">
          <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
            <p>{error}</p>
            <button 
              className="mt-4 btn btn-primary"
              onClick={() => window.location.reload()}>
              Try Again
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="page-container">
      <div className="bg-primary-color py-12 mb-8">
        <div className="container">
          <div className="text-center text-white mb-8">
            <h1 className="text-3xl md:text-4xl font-bold mb-4">
              Discover Your Favorite Stores
            </h1>
            <p className="text-lg max-w-2xl mx-auto">
              Follow your favorite merchants to get personalized deal recommendations and notifications about their latest promotions.
            </p>
          </div>
          
          <div className="max-w-md mx-auto">
            <div className="relative">
              <input
                type="text"
                placeholder="Search for stores..."
                className="w-full px-4 py-3 pl-10 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-dark"
                value={searchTerm}
                onChange={handleSearch} />
              <i className="fas fa-search absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"></i>
            </div>
          </div>
        </div>
      </div>
      
      <div className="container pb-8">
        <div className="mb-6 overflow-x-auto">
          <div className="flex space-x-2">
            <button
              className={`px-4 py-2 rounded-full ${
              selectedCategory === 'all' ?
              'bg-primary-color text-white' :
              'bg-white text-gray-700 border border-gray-300 hover:bg-gray-100'}`
              }
              onClick={() => handleCategoryChange('all')}>
              All Categories
            </button>
            
            {categories.slice(1).map((category) =>
            <button
              key={category.id}
              className={`px-4 py-2 rounded-full flex items-center ${
              selectedCategory === category.id ?
              'bg-primary-color text-white' :
              'bg-white text-gray-700 border border-gray-300 hover:bg-gray-100'}`
              }
              onClick={() => handleCategoryChange(category.id)}>
                <i className={`fas ${category.icon} mr-2`}></i>
                {category.name}
              </button>
            )}
          </div>
        </div>
        
        {filteredMerchants.length === 0 ?
        <div className="text-center py-10">
            <i className="fas fa-store text-gray-300 text-5xl mb-4"></i>
            <h2 className="text-xl font-semibold mb-2">No merchants found</h2>
            <p className="text-gray-500">Try a different search term or category</p>
          </div> :

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {filteredMerchants.map((merchant) =>
          <div key={merchant.id} className="bg-white rounded-lg shadow-md overflow-hidden">
                <div className="p-4">
                  <div className="flex items-center mb-4">
                    <div className="w-16 h-16 bg-gray-200 rounded-full overflow-hidden mr-4 flex-shrink-0">
                      <img
                        src={merchant.logo}
                        alt={merchant.name}
                        className="w-full h-full object-cover"
                        onError={(e) => {
                          e.target.onerror = null;
                          e.target.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(merchant.name)}&background=random&size=300`;
                        }} 
                      />
                    </div>
                    <div>
                      <h2 className="text-xl font-semibold">{merchant.name}</h2>
                      <div className="flex items-center text-sm text-gray-600">
                        <i className={`fas fa-${merchant.category === 'fashion' ? 'tshirt' : merchant.category === 'electronics' ? 'laptop' : merchant.category === 'travel' ? 'plane' : merchant.category === 'health' ? 'heart-pulse' : merchant.category === 'entertainment' ? 'gamepad' : merchant.category === 'home' ? 'home' : merchant.category === 'pets' ? 'paw' : merchant.category === 'food' ? 'utensils' : 'store'} mr-1`}></i>
                        {merchant.category ? (merchant.category.charAt(0).toUpperCase() + merchant.category.slice(1)) : 'Other'}
                        <span className="mx-2">•</span>
                        <span>{(merchant.followers || 0).toLocaleString()} followers</span>
                      </div>
                    </div>
                  </div>
                  
                  <p className="text-gray-600 text-sm mb-4">
                    {merchant.description || `${merchant.name} offers great deals and promotions.`}
                  </p>
                  
                  <div className="flex justify-between items-center">
                    <span className="text-sm font-medium text-primary-color">
                      {merchant.activeDeals || 0} active deals
                    </span>
                    
                    <Link
                      to={`/merchants/${merchant.id}`}
                      className="btn btn-primary text-sm py-1">
                      Visit Store
                    </Link>
                  </div>
                </div>
              </div>
          )}
          </div>
        }
      </div>
    </div>);
}