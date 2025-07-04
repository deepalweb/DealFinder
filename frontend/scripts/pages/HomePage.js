function HomePage() {
  const { useState, useEffect } = React;
  const { useNavigate } = ReactRouterDOM;
  const navigate = useNavigate();

  const [featuredPromotions, setFeaturedPromotions] = useState([]);
  const [allLatestPromotions, setAllLatestPromotions] = useState([]); // Store all latest promotions
  const [visibleLatestCount, setVisibleLatestCount] = useState(12); // Number of latest promotions to show
  const [searchResults, setSearchResults] = useState([]);
  const [isSearching, setIsSearching] = useState(false);

  useEffect(() => {
    // Refresh promotions data to include any new promotions from API and demo merchant
    const loadPromotions = async () => {
      try {
        // Get all promotions including API and demo data
        const allPromotions = await window.getPromotionsData();
        window.promotionsData = allPromotions;
        
        // Get featured promotions
        const featured = allPromotions.filter((promo) => promo.featured);
        setFeaturedPromotions(featured);
    
        // Get latest promotions (sorted by createdAt) - store all, display a slice
        const sortedLatest = [...allPromotions]
          .filter(p => !p.featured) // Optionally, ensure latest are not also featured if you want distinct sections
          .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
        setAllLatestPromotions(sortedLatest);
      } catch (error) {
        console.error('Error loading promotions:', error);
      }
    };
    
    loadPromotions();
  }, []);

  const handleSearch = (searchTerm) => {
    if (!searchTerm.trim()) {
      setIsSearching(false);
      return;
    }

    setIsSearching(true);
    const filtered = filterPromotions(promotionsData, { searchTerm });
    setSearchResults(filtered);
  };

  const handleCategorySelect = (categoryId) => {
    navigate(`/categories/${categoryId}`);
  };

  return (
    <div className="page-container" data-id="qr1isgxv2" data-path="scripts/pages/HomePage.js">
      <div className="bg-primary-color py-12 mb-8" data-id="lcqp3eg1n" data-path="scripts/pages/HomePage.js">
        <div className="container" data-id="xbo5chikh" data-path="scripts/pages/HomePage.js">
          <div className="text-center text-white mb-8" data-id="8np7h59n8" data-path="scripts/pages/HomePage.js">
            <h1 className="text-3xl md:text-4xl font-bold mb-4" data-id="dd76akxua" data-path="scripts/pages/HomePage.js">
              Discover Amazing Discounts & Promotions
            </h1>
            <p className="text-lg max-w-2xl mx-auto" data-id="xm59tdm3e" data-path="scripts/pages/HomePage.js">
              Find the best deals from your favorite stores all in one place. Save big with exclusive coupons and offers.
            </p>
          </div>
          
          <SearchBar onSearch={handleSearch} />
        </div>
      </div>
      
      <div className="container" data-id="zi6w10sj5" data-path="scripts/pages/HomePage.js">
        <CategoryList
          selectedCategory="all"
          onCategoryChange={handleCategorySelect} />

        
        {isSearching ?
        <div className="mb-8" data-id="e8v7d46gn" data-path="scripts/pages/HomePage.js">
            <h2 className="section-title" data-id="atxgtlgx2" data-path="scripts/pages/HomePage.js">
              <i className="fas fa-search" data-id="fru1knv79" data-path="scripts/pages/HomePage.js"></i> Search Results
            </h2>
            
            {searchResults.length > 0 ?
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6" data-id="6gw38lo3e" data-path="scripts/pages/HomePage.js">
                {searchResults.map((promotion) =>
                  <div key={promotion.id}>
                    <div onClick={() => window.location.href = `/deal/${promotion.id || promotion._id}`}
                      className="cursor-pointer">
                      <PromotionCard promotion={promotion} />
                    </div>
                  </div>
                )}
              </div> :

          <div className="text-center py-8" data-id="ckbgklt24" data-path="scripts/pages/HomePage.js">
                <i className="fas fa-search text-4xl text-gray-300 mb-4" data-id="sxp6mldys" data-path="scripts/pages/HomePage.js"></i>
                <h3 className="text-xl font-semibold mb-2" data-id="3dvuveqem" data-path="scripts/pages/HomePage.js">No results found</h3>
                <p data-id="nbd8exw7g" data-path="scripts/pages/HomePage.js">Try different keywords or browse categories below</p>
              </div>
          }
          </div> :

        <>
            {/* Featured Promotions */}
            <div className="mb-12" data-id="3ok9i2rxg" data-path="scripts/pages/HomePage.js">
              <h2 className="section-title" data-id="a3hqpzbo7" data-path="scripts/pages/HomePage.js">
                <i className="fas fa-star" data-id="fg4syc1as" data-path="scripts/pages/HomePage.js"></i> Featured Deals
              </h2>
              
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6" data-id="peyc4yr8a" data-path="scripts/pages/HomePage.js">
                {featuredPromotions.map((promotion) =>
                  <div key={promotion.id}>
                    <div onClick={() => window.location.href = `/deal/${promotion.id || promotion._id}`}
                      className="cursor-pointer">
                      <PromotionCard promotion={promotion} />
                    </div>
                  </div>
                )}
              </div>
            </div>
            
            {/* Latest Promotions */}
            <div className="mb-12" data-id="behh4hrrs" data-path="scripts/pages/HomePage.js">
              <h2 className="section-title" data-id="szx2k581z" data-path="scripts/pages/HomePage.js">
                <i className="fas fa-clock" data-id="5ou8kaf2q" data-path="scripts/pages/HomePage.js"></i> Latest Deals
              </h2>
              
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6" data-id="4bl781b6h" data-path="scripts/pages/HomePage.js">
                {allLatestPromotions.slice(0, visibleLatestCount).map((promotion) =>
                  <div key={promotion.id || promotion._id}>
                    <div onClick={() => window.location.href = `/deal/${promotion.id || promotion._id}`}
                      className="cursor-pointer">
                      <PromotionCard promotion={promotion} />
                    </div>
                  </div>
                )}
              </div>
              {allLatestPromotions.length > visibleLatestCount && (
                <div className="text-center mt-8">
                  <button
                    onClick={() => setVisibleLatestCount(prevCount => prevCount + 12)}
                    className="btn btn-primary hover:bg-primary-dark"
                  >
                    Show More Deals
                  </button>
                </div>
              )}
            </div>
          </>
        }
      </div>
    </div>);

}