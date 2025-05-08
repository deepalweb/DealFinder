function MerchantProfilePage() {
  const { useState, useEffect } = React;
  const { useParams, Link } = ReactRouterDOM;

  const [merchant, setMerchant] = useState(null);
  const [promotions, setPromotions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('active');
  const [isFollowing, setIsFollowing] = useState(false);
  const [error, setError] = useState(null);

  const { merchantId } = useParams();

  useEffect(() => {
    const fetchMerchantData = async () => {
      try {
        setLoading(true);
        
        // Fetch real merchant data from API
        let merchantData = null;
        try {
          merchantData = await window.API.Merchants.getById(merchantId);
          console.log("Merchant data from API:", merchantData);
        } catch (apiError) {
          console.error("Error fetching merchant from API:", apiError);
          setError("Failed to load merchant details. Please try again.");
        }
        
        // If no merchant data from API or API failed, use mock data
        if (!merchantData) {
          console.log("Using mock merchant data");
          merchantData = {
            id: merchantId,
            name: "Fashion Nova",
            logo: "https://images.unsplash.com/photo-1607083206968-13611e3d76db?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=300&q=80",
            banner: "https://images.unsplash.com/photo-1607083206968-13611e3d76db?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1200&q=80",
            description: "Fashion Nova is an American fast fashion retail company. The company operates online and has five brick-and-mortar locations.",
            category: "fashion",
            website: "https://fashionnova.com",
            socialMedia: {
              facebook: "fashionnova",
              instagram: "fashionnova",
              twitter: "fashionnova"
            },
            followers: 15750
          };
        } else {
          // Format API data to match expected structure
          merchantData = {
            id: merchantData._id || merchantId,
            name: merchantData.name || "Unknown Merchant",
            logo: merchantData.logo || `https://ui-avatars.com/api/?name=${encodeURIComponent(merchantData.name || 'M')}&background=random&size=300`,
            banner: merchantData.banner || "https://images.unsplash.com/photo-1557683316-973673baf926?q=80&w=2029&auto=format&fit=crop",
            description: merchantData.profile || `${merchantData.name} offers great deals and promotions.`,
            category: merchantData.category || "other",
            website: merchantData.website || "#",
            socialMedia: merchantData.socialMedia || {
              facebook: "",
              instagram: "",
              twitter: ""
            },
            followers: merchantData.followers || Math.floor(Math.random() * 10000)
          };
        }

        // Get promotions related to this merchant
        let merchantPromotions = [];
        try {
          merchantPromotions = await window.API.Promotions.getByMerchant(merchantId);
          console.log("Promotions from API:", merchantPromotions);
        } catch (promoError) {
          console.error("Error fetching promotions:", promoError);
          // Fall back to mock data
          merchantPromotions = promotionsData.filter((promo) =>
            promo.merchant.toLowerCase() === merchantData.name.toLowerCase()
          );
        }

        // Check if user is following this merchant
        const followedMerchants = JSON.parse(localStorage.getItem('dealFinderFollowing') || '[]');
        const isFollowed = followedMerchants.some((m) => m.id === merchantId);

        setMerchant(merchantData);
        setPromotions(merchantPromotions);
        setIsFollowing(isFollowed);
      } catch (err) {
        console.error("Error in merchant profile:", err);
        setError("Failed to load merchant profile. Please try again.");
      } finally {
        setLoading(false);
      }
    };

    fetchMerchantData();
  }, [merchantId]);

  const handleFollowToggle = () => {
    // Toggle follow status
    const newFollowStatus = !isFollowing;
    setIsFollowing(newFollowStatus);

    // Update local storage
    const followedMerchants = JSON.parse(localStorage.getItem('dealFinderFollowing') || '[]');

    if (newFollowStatus) {
      // Add to following
      if (!followedMerchants.some((m) => m.id === merchant.id)) {
        followedMerchants.push({
          id: merchant.id,
          name: merchant.name,
          logo: merchant.logo,
          category: merchant.category,
          activeDeals: promotions.filter((p) => {
            const endDate = new Date(p.endDate);
            return endDate >= new Date();
          }).length
        });
      }
    } else {
      // Remove from following
      const index = followedMerchants.findIndex((m) => m.id === merchant.id);
      if (index !== -1) {
        followedMerchants.splice(index, 1);
      }
    }

    localStorage.setItem('dealFinderFollowing', JSON.stringify(followedMerchants));
  };

  const filteredPromotions = promotions.filter((promo) => {
    const endDate = new Date(promo.endDate);
    const now = new Date();

    if (activeTab === 'active') {
      return endDate >= now;
    } else if (activeTab === 'expired') {
      return endDate < now;
    }
    return true;
  });

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
      {/* Merchant Banner */}
      <div
        className="h-48 md:h-64 bg-center bg-cover"
        style={{ backgroundImage: `url(${merchant.banner})` }}>

        <div className="container h-full flex items-end">
          <div className="bg-white bg-opacity-90 p-4 mb-4 rounded-lg shadow-md max-w-3xl">
            <div className="flex items-center">
              <img
                src={merchant.logo}
                alt={merchant.name}
                className="w-16 h-16 md:w-20 md:h-20 rounded-full border-4 border-white shadow-sm object-cover"
                onError={(e) => {
                  e.target.onerror = null;
                  e.target.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(merchant.name)}&background=random&size=300`;
                }} />

              <div className="ml-4">
                <h1 className="text-2xl md:text-3xl font-bold">{merchant.name}</h1>
                <div className="flex items-center text-sm text-gray-600">
                  <i className={`fas fa-${merchant.category === 'fashion' ? 'tshirt' : merchant.category === 'electronics' ? 'laptop' : merchant.category === 'travel' ? 'plane' : merchant.category === 'health' ? 'heart-pulse' : merchant.category === 'entertainment' ? 'gamepad' : merchant.category === 'home' ? 'home' : merchant.category === 'pets' ? 'paw' : merchant.category === 'food' ? 'utensils' : 'store'} mr-1`}></i>
                  {merchant.category.charAt(0).toUpperCase() + merchant.category.slice(1)}
                  <span className="mx-2">•</span>
                  <span>{merchant.followers.toLocaleString()} followers</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <div className="container py-6">
        <div className="flex flex-col md:flex-row md:items-start gap-6">
          {/* Sidebar */}
          <div className="md:w-1/3 lg:w-1/4">
            <div className="bg-white rounded-lg shadow-md p-5 mb-6">
              <button
                onClick={handleFollowToggle}
                className={`w-full py-2 px-4 rounded-md mb-4 flex items-center justify-center ${
                isFollowing ?
                'bg-gray-100 text-gray-800 border border-gray-300 hover:bg-gray-200' :
                'bg-primary-color text-white hover:bg-primary-dark'}`
                }>

                <i className={`${isFollowing ? 'fas fa-user-check' : 'fas fa-user-plus'} mr-2`}></i>
                {isFollowing ? 'Following' : 'Follow'}
              </button>
              
              <div className="mb-4">
                <h3 className="font-semibold mb-2">About</h3>
                <p className="text-sm text-gray-600">{merchant.description}</p>
              </div>
              
              {merchant.website && merchant.website !== "#" && (
                <div className="mb-4">
                  <h3 className="font-semibold mb-2">Website</h3>
                  <a
                    href={merchant.website}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-sm text-primary-color hover:underline flex items-center">
                    <i className="fas fa-external-link-alt mr-1"></i> Visit Website
                  </a>
                </div>
              )}
              
              {(merchant.socialMedia && (merchant.socialMedia.facebook || merchant.socialMedia.instagram || merchant.socialMedia.twitter)) && (
                <div>
                  <h3 className="font-semibold mb-2">Social Media</h3>
                  <div className="flex space-x-2">
                    {merchant.socialMedia.facebook && (
                      <a
                        href={`https://facebook.com/${merchant.socialMedia.facebook}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="w-8 h-8 bg-blue-600 text-white rounded-full flex items-center justify-center hover:bg-blue-700">
                        <i className="fab fa-facebook-f"></i>
                      </a>
                    )}
                    
                    {merchant.socialMedia.instagram && (
                      <a
                        href={`https://instagram.com/${merchant.socialMedia.instagram}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="w-8 h-8 bg-gradient-to-r from-purple-500 via-pink-500 to-orange-500 text-white rounded-full flex items-center justify-center hover:from-purple-600 hover:via-pink-600 hover:to-orange-600">
                        <i className="fab fa-instagram"></i>
                      </a>
                    )}
                    
                    {merchant.socialMedia.twitter && (
                      <a
                        href={`https://twitter.com/${merchant.socialMedia.twitter}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="w-8 h-8 bg-blue-400 text-white rounded-full flex items-center justify-center hover:bg-blue-500">
                        <i className="fab fa-twitter"></i>
                      </a>
                    )}
                  </div>
                </div>
              )}
            </div>
          </div>
          
          {/* Main Content */}
          <div className="md:w-2/3 lg:w-3/4">
            <div className="bg-white rounded-lg shadow-md p-5 mb-6">
              <div className="flex border-b border-gray-200 mb-4">
                <button
                  className={`pb-2 px-4 ${activeTab === 'active' ? 'border-b-2 border-primary-color text-primary-color font-medium' : 'text-gray-500 hover:text-gray-700'}`}
                  onClick={() => setActiveTab('active')}>
                  Active Deals
                </button>
                <button
                  className={`pb-2 px-4 ${activeTab === 'expired' ? 'border-b-2 border-primary-color text-primary-color font-medium' : 'text-gray-500 hover:text-gray-700'}`}
                  onClick={() => setActiveTab('expired')}>
                  Expired Deals
                </button>
              </div>
              
              {filteredPromotions.length === 0 ? (
                <div className="text-center py-8">
                  <i className="fas fa-tag text-gray-300 text-5xl mb-4"></i>
                  <p className="text-gray-500">No {activeTab} deals available</p>
                </div>
              ) : (
                <div className="space-y-4">
                  {filteredPromotions.map((promotion) => (
                    <div key={promotion.id} className="border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow">
                      <div className="flex justify-between items-start">
                        <div>
                          <h3 className="font-semibold text-lg">{promotion.title}</h3>
                          <p className="text-sm text-gray-600 mb-2">{promotion.description}</p>
                          
                          <div className="flex items-center text-sm text-gray-500 mb-3">
                            <i className="far fa-calendar-alt mr-1"></i>
                            {new Date(promotion.startDate).toLocaleDateString()} - {new Date(promotion.endDate).toLocaleDateString()}
                          </div>
                          
                          <div className="flex items-center">
                            <div className="promo-code bg-gray-100 border border-gray-300 rounded px-3 py-1 text-sm font-mono mr-3">
                              {promotion.code}
                            </div>
                            <span className="bg-discount-red text-white text-sm px-2 py-1 rounded">
                              {promotion.discount}
                            </span>
                          </div>
                        </div>
                        
                        {promotion.image && (
                          <div className="w-20 h-20 bg-gray-100 rounded overflow-hidden flex-shrink-0">
                            <img
                              src={promotion.image}
                              alt={promotion.title}
                              className="w-full h-full object-cover"
                              onError={(e) => {
                                e.target.onerror = null;
                                e.target.src = "https://via.placeholder.com/80?text=No+Image";
                              }}
                            />
                          </div>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}