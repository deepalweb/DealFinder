function HomePage() {
  const { useState, useEffect } = React;
  const { useNavigate } = ReactRouterDOM;
  const navigate = useNavigate();

  const [featuredPromotions, setFeaturedPromotions] = useState([]);
  const [latestPromotions, setLatestPromotions] = useState([]);
  const [searchResults, setSearchResults] = useState([]);
  const [isSearching, setIsSearching] = useState(false);
  const [nearbyDeals, setNearbyDeals] = useState([]);
  const [userLocation, setUserLocation] = useState(null);
  const [locationError, setLocationError] = useState(null);
  const [loadingNearby, setLoadingNearby] = useState(false);

  useEffect(() => {
    // Load standard promotions (featured, latest)
    const loadStandardPromotions = async () => {
      try {
        const allPromotions = await window.getPromotionsData(); // This function might need adjustment if it's purely local
        window.promotionsData = allPromotions; // Assuming this is used by search
        
        const featured = allPromotions.filter((promo) => promo.featured);
        setFeaturedPromotions(featured);
    
        const latest = [...allPromotions]
          .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
          .slice(0, 8);
        setLatestPromotions(latest);
      } catch (error) {
        console.error('Error loading standard promotions:', error);
      }
    };

    // Fetch user location and then nearby deals
    const fetchUserLocationAndNearbyDeals = async () => {
      setLoadingNearby(true);
      setLocationError(null);
      if (!navigator.geolocation) {
        setLocationError('Geolocation is not supported by your browser.');
        setLoadingNearby(false);
        return;
      }

      navigator.geolocation.getCurrentPosition(
        async (position) => {
          const { latitude, longitude } = position.coords;
          setUserLocation({ latitude, longitude });
          try {
            // Default radius 10km, can be adjusted
            const deals = await window.API.Promotions.getNearby(latitude, longitude, 10);
            setNearbyDeals(deals);
          } catch (error) {
            console.error('Error fetching nearby deals:', error);
            setLocationError('Could not fetch nearby deals.');
          } finally {
            setLoadingNearby(false);
          }
        },
        (error) => {
          console.error('Error getting user location:', error);
          switch (error.code) {
            case error.PERMISSION_DENIED:
              setLocationError('Location permission denied. Nearby deals cannot be shown.');
              break;
            case error.POSITION_UNAVAILABLE:
              setLocationError('Location information is unavailable.');
              break;
            case error.TIMEOUT:
              setLocationError('The request to get user location timed out.');
              break;
            default:
              setLocationError('An unknown error occurred while fetching location.');
              break;
          }
          setLoadingNearby(false);
        }
      );
    };
    
    loadStandardPromotions();
    fetchUserLocationAndNearbyDeals();
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
            
            {/* Nearby Deals Section */}
            {(userLocation || locationError || loadingNearby) && (
            <div className="mb-12" data-id="nearbyDealsSection">
              <h2 className="section-title" data-id="nearbyTitle">
                <i className="fas fa-map-marker-alt" data-id="nearbyIcon"></i> Nearby Deals
                {userLocation && <span className="text-sm text-gray-500 ml-2">(Based on your location)</span>}
              </h2>
              {loadingNearby && (
                <div className="text-center py-8" data-id="nearbyLoading">
                  <i className="fas fa-spinner fa-spin text-3xl text-primary-color"></i>
                  <p className="mt-2">Finding deals near you...</p>
                </div>
              )}
              {locationError && !loadingNearby && (
                <div className="text-center py-8 bg-red-50 border border-red-200 rounded-md p-4" data-id="nearbyError">
                  <i className="fas fa-exclamation-triangle text-3xl text-red-500 mb-3"></i>
                  <p className="text-red-700">{locationError}</p>
                  {locationError.includes("permission denied") && (
                     <p className="text-sm text-gray-600 mt-2">Please enable location services in your browser settings to see nearby deals.</p>
                  )}
                </div>
              )}
              {!loadingNearby && !locationError && userLocation && nearbyDeals.length === 0 && (
                <div className="text-center py-8" data-id="noNearbyDeals">
                  <i className="fas fa-store-slash text-4xl text-gray-300 mb-4"></i>
                  <p>No deals found near your current location.</p>
                  <p className="text-sm text-gray-500">Try expanding your search or check back later.</p>
                </div>
              )}
              {!loadingNearby && !locationError && userLocation && nearbyDeals.length > 0 && (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6" data-id="nearbyGrid">
                  {nearbyDeals.map((promotion) => (
                    <div key={promotion._id || promotion.id}>
                      <div onClick={() => window.location.href = `/deal/${promotion._id || promotion.id}`}
                        className="cursor-pointer">
                        <PromotionCard promotion={promotion} />
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
            )}

            {/* Latest Promotions */}
            <div className="mb-12" data-id="behh4hrrs" data-path="scripts/pages/HomePage.js">
              <h2 className="section-title" data-id="szx2k581z" data-path="scripts/pages/HomePage.js">
                <i className="fas fa-clock" data-id="5ou8kaf2q" data-path="scripts/pages/HomePage.js"></i> Latest Deals
              </h2>
              
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6" data-id="4bl781b6h" data-path="scripts/pages/HomePage.js">
                {latestPromotions.map((promotion) =>
                  <div key={promotion.id}>
                    <div onClick={() => window.location.href = `/deal/${promotion.id || promotion._id}`}
                      className="cursor-pointer">
                      <PromotionCard promotion={promotion} />
                    </div>
                  </div>
                )}
              </div>
            </div>
          </>
        }
      </div>
    </div>);

}