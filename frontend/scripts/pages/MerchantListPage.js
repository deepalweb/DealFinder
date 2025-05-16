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
        // Only fetch merchants from API
        let merchantsData = await window.API.Merchants.getAll();
        if (!Array.isArray(merchantsData)) {
          console.warn('Expected array of merchants, got:', merchantsData);
          merchantsData = [];
        }
        merchantsData = merchantsData.map(m => ({ ...m, id: m._id }));
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

  // Utility to get a safe logo image (base64, URL, or fallback)
  function getSafeLogo(logo, name) {
    if (logo && typeof logo === 'string') {
      if (logo.startsWith('data:image')) return logo;
      if (logo.startsWith('http')) return logo;
    }
    return `https://ui-avatars.com/api/?name=${encodeURIComponent(name || 'M')}&background=random&size=300`;
  }

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

  // Defensive: ensure all merchants have an 'id' property for React keys
  const safeFilteredMerchants = filteredMerchants.map(m => ({ ...m, id: m.id || m._id }));

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
            {safeFilteredMerchants.map((merchant) =>
          <div key={merchant.id} className="bg-white rounded-lg shadow-md overflow-hidden">
                <div className="p-4">
                  <div className="flex items-center mb-4">
                    <div className="w-16 h-16 bg-gray-200 rounded-full overflow-hidden mr-4 flex-shrink-0">
                      <img
                        src={getSafeLogo(merchant.logo, merchant.name)}
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
                        <span>{typeof merchant.followers === 'number' ? merchant.followers.toLocaleString() : '0'} followers</span>
                      </div>
                    </div>
                  </div>
                  
                  <p className="text-gray-600 text-sm mb-4">
                    {merchant.description || `${merchant.name} offers great deals and promotions.`}
                  </p>
                  
                  <div className="flex justify-between items-center">
                    <span className="text-sm font-medium text-primary-color">
                      {typeof merchant.activeDeals === 'number' ? merchant.activeDeals : 0} active deals
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