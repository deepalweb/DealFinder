function MerchantListPage() {
  const { useState, useEffect } = React;
  const { Link } = ReactRouterDOM;

  const [merchants, setMerchants] = useState([]);
  const [filteredMerchants, setFilteredMerchants] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');

  useEffect(() => {
    // Simulate fetching merchant data
    // In a real app, this would be an API call
    setTimeout(() => {
      const mockMerchants = [
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
      }];


      setMerchants(mockMerchants);
      setFilteredMerchants(mockMerchants);
      setLoading(false);
    }, 700);
  }, []);

  useEffect(() => {
    // Filter merchants based on search term and category
    let results = [...merchants];

    if (searchTerm) {
      const term = searchTerm.toLowerCase();
      results = results.filter((merchant) =>
      merchant.name.toLowerCase().includes(term) ||
      merchant.description.toLowerCase().includes(term)
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
      <div className="page-container" data-id="qcbyr5fda" data-path="scripts/pages/MerchantListPage.js">
        <div className="container py-8 text-center" data-id="hz4sgrz2t" data-path="scripts/pages/MerchantListPage.js">
          <i className="fas fa-spinner fa-spin text-3xl text-primary-color" data-id="gbbouhvzu" data-path="scripts/pages/MerchantListPage.js"></i>
        </div>
      </div>);

  }

  return (
    <div className="page-container" data-id="eg7zpi75k" data-path="scripts/pages/MerchantListPage.js">
      <div className="bg-primary-color py-12 mb-8" data-id="qztvhin94" data-path="scripts/pages/MerchantListPage.js">
        <div className="container" data-id="z11yjlank" data-path="scripts/pages/MerchantListPage.js">
          <div className="text-center text-white mb-8" data-id="ewgr04b6l" data-path="scripts/pages/MerchantListPage.js">
            <h1 className="text-3xl md:text-4xl font-bold mb-4" data-id="ndkyt2twh" data-path="scripts/pages/MerchantListPage.js">
              Discover Your Favorite Stores
            </h1>
            <p className="text-lg max-w-2xl mx-auto" data-id="7cq45ihqn" data-path="scripts/pages/MerchantListPage.js">
              Follow your favorite merchants to get personalized deal recommendations and notifications about their latest promotions.
            </p>
          </div>
          
          <div className="max-w-md mx-auto" data-id="zas37uhtk" data-path="scripts/pages/MerchantListPage.js">
            <div className="relative" data-id="5i3mcmogu" data-path="scripts/pages/MerchantListPage.js">
              <input
                type="text"
                placeholder="Search for stores..."
                className="w-full px-4 py-3 pl-10 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-dark"
                value={searchTerm}
                onChange={handleSearch} data-id="k3zdj45cc" data-path="scripts/pages/MerchantListPage.js" />

              <i className="fas fa-search absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" data-id="h855ufuii" data-path="scripts/pages/MerchantListPage.js"></i>
            </div>
          </div>
        </div>
      </div>
      
      <div className="container pb-8" data-id="agzk7b4wt" data-path="scripts/pages/MerchantListPage.js">
        <div className="mb-6 overflow-x-auto" data-id="h6gjoekue" data-path="scripts/pages/MerchantListPage.js">
          <div className="flex space-x-2" data-id="lfaeqvi7u" data-path="scripts/pages/MerchantListPage.js">
            <button
              className={`px-4 py-2 rounded-full ${
              selectedCategory === 'all' ?
              'bg-primary-color text-white' :
              'bg-white text-gray-700 border border-gray-300 hover:bg-gray-100'}`
              }
              onClick={() => handleCategoryChange('all')} data-id="8axxjjdbh" data-path="scripts/pages/MerchantListPage.js">

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
              onClick={() => handleCategoryChange(category.id)} data-id="9503ag4bq" data-path="scripts/pages/MerchantListPage.js">

                <i className={`fas ${category.icon} mr-2`} data-id="jxlwqopsf" data-path="scripts/pages/MerchantListPage.js"></i>
                {category.name}
              </button>
            )}
          </div>
        </div>
        
        {filteredMerchants.length === 0 ?
        <div className="text-center py-10" data-id="m44te6gm3" data-path="scripts/pages/MerchantListPage.js">
            <i className="fas fa-store text-gray-300 text-5xl mb-4" data-id="0zo6ym68q" data-path="scripts/pages/MerchantListPage.js"></i>
            <h2 className="text-xl font-semibold mb-2" data-id="9swp8bkty" data-path="scripts/pages/MerchantListPage.js">No merchants found</h2>
            <p className="text-gray-500" data-id="fhkyaez6v" data-path="scripts/pages/MerchantListPage.js">Try a different search term or category</p>
          </div> :

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6" data-id="cxjzt1yni" data-path="scripts/pages/MerchantListPage.js">
            {filteredMerchants.map((merchant) =>
          <div key={merchant.id} className="bg-white rounded-lg shadow-md overflow-hidden" data-id="xx4t4asz0" data-path="scripts/pages/MerchantListPage.js">
                <div className="p-4" data-id="id7kxwmr9" data-path="scripts/pages/MerchantListPage.js">
                  <div className="flex items-center mb-4" data-id="rsi3t0a6d" data-path="scripts/pages/MerchantListPage.js">
                    <div className="w-16 h-16 bg-gray-200 rounded-full overflow-hidden mr-4 flex-shrink-0" data-id="mlc1usnq6" data-path="scripts/pages/MerchantListPage.js">
                      <img
                    src={merchant.logo}
                    alt={merchant.name}
                    className="w-full h-full object-cover" data-id="k2tw5yys2" data-path="scripts/pages/MerchantListPage.js" />

                    </div>
                    <div data-id="qjh55t7y8" data-path="scripts/pages/MerchantListPage.js">
                      <h2 className="text-xl font-semibold" data-id="1uk14xf1e" data-path="scripts/pages/MerchantListPage.js">{merchant.name}</h2>
                      <div className="flex items-center text-sm text-gray-600" data-id="ua2vhbc5i" data-path="scripts/pages/MerchantListPage.js">
                        <i className={`fas fa-${merchant.category === 'fashion' ? 'tshirt' : merchant.category === 'electronics' ? 'laptop' : merchant.category === 'travel' ? 'plane' : merchant.category === 'health' ? 'heart-pulse' : merchant.category === 'entertainment' ? 'gamepad' : merchant.category === 'home' ? 'home' : merchant.category === 'pets' ? 'paw' : merchant.category === 'food' ? 'utensils' : 'graduation-cap'} mr-1`} data-id="3vteq4pao" data-path="scripts/pages/MerchantListPage.js"></i>
                        {merchant.category.charAt(0).toUpperCase() + merchant.category.slice(1)}
                        <span className="mx-2" data-id="tfzu1qy3c" data-path="scripts/pages/MerchantListPage.js">•</span>
                        <span data-id="mnn34ox55" data-path="scripts/pages/MerchantListPage.js">{merchant.followers.toLocaleString()} followers</span>
                      </div>
                    </div>
                  </div>
                  
                  <p className="text-gray-600 text-sm mb-4" data-id="k82mn7mbm" data-path="scripts/pages/MerchantListPage.js">
                    {merchant.description}
                  </p>
                  
                  <div className="flex justify-between items-center" data-id="vaofvwm3l" data-path="scripts/pages/MerchantListPage.js">
                    <span className="text-sm font-medium text-primary-color" data-id="18nhxuekp" data-path="scripts/pages/MerchantListPage.js">
                      {merchant.activeDeals} active deals
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