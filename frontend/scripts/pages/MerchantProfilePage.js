function MerchantProfilePage() {
  const { useState, useEffect } = React;
  const { useParams, Link } = ReactRouterDOM;

  const [merchant, setMerchant] = useState(null);
  const [promotions, setPromotions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('active');
  const [isFollowing, setIsFollowing] = useState(false);

  const { merchantId } = useParams();

  useEffect(() => {
    // Simulate fetching merchant data
    // In a real app, this would be an API call
    setTimeout(() => {
      const mockMerchant = {
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

      // Get promotions related to this merchant
      const merchantPromotions = promotionsData.filter((promo) =>
      promo.merchant.toLowerCase() === mockMerchant.name.toLowerCase()
      );

      // Check if user is following this merchant
      const followedMerchants = JSON.parse(localStorage.getItem('dealFinderFollowing') || '[]');
      const isFollowed = followedMerchants.some((m) => m.id === parseInt(merchantId));

      setMerchant(mockMerchant);
      setPromotions(merchantPromotions);
      setIsFollowing(isFollowed);
      setLoading(false);
    }, 700);
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
      <div className="page-container" data-id="p00sa84t1" data-path="scripts/pages/MerchantProfilePage.js">
        <div className="container py-8 text-center" data-id="g0q5wae2s" data-path="scripts/pages/MerchantProfilePage.js">
          <i className="fas fa-spinner fa-spin text-3xl text-primary-color" data-id="cs4ep0nna" data-path="scripts/pages/MerchantProfilePage.js"></i>
        </div>
      </div>);

  }

  return (
    <div className="page-container" data-id="uw3s6lwwc" data-path="scripts/pages/MerchantProfilePage.js">
      {/* Merchant Banner */}
      <div
        className="h-48 md:h-64 bg-center bg-cover"
        style={{ backgroundImage: `url(${merchant.banner})` }} data-id="9d5iz9xwl" data-path="scripts/pages/MerchantProfilePage.js">

        <div className="container h-full flex items-end" data-id="vskce2frt" data-path="scripts/pages/MerchantProfilePage.js">
          <div className="bg-white bg-opacity-90 p-4 mb-4 rounded-lg shadow-md max-w-3xl" data-id="bbhd0a6ia" data-path="scripts/pages/MerchantProfilePage.js">
            <div className="flex items-center" data-id="e1crnl1a9" data-path="scripts/pages/MerchantProfilePage.js">
              <img
                src={merchant.logo}
                alt={merchant.name}
                className="w-16 h-16 md:w-20 md:h-20 rounded-full border-4 border-white shadow-sm object-cover" data-id="bf5sokv6q" data-path="scripts/pages/MerchantProfilePage.js" />

              <div className="ml-4" data-id="9ne8ouz0r" data-path="scripts/pages/MerchantProfilePage.js">
                <h1 className="text-2xl md:text-3xl font-bold" data-id="8vbizqoa6" data-path="scripts/pages/MerchantProfilePage.js">{merchant.name}</h1>
                <div className="flex items-center text-sm text-gray-600" data-id="9imkvdtw5" data-path="scripts/pages/MerchantProfilePage.js">
                  <i className={`fas fa-${merchant.category === 'fashion' ? 'tshirt' : merchant.category === 'electronics' ? 'laptop' : 'home'} mr-1`} data-id="r3pgysbuk" data-path="scripts/pages/MerchantProfilePage.js"></i>
                  {merchant.category.charAt(0).toUpperCase() + merchant.category.slice(1)}
                  <span className="mx-2" data-id="0l5nty2gj" data-path="scripts/pages/MerchantProfilePage.js">•</span>
                  <span data-id="4240qsyzf" data-path="scripts/pages/MerchantProfilePage.js">{merchant.followers.toLocaleString()} followers</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <div className="container py-6" data-id="pr2z2w51z" data-path="scripts/pages/MerchantProfilePage.js">
        <div className="flex flex-col md:flex-row md:items-start gap-6" data-id="bnwhdlh9t" data-path="scripts/pages/MerchantProfilePage.js">
          {/* Sidebar */}
          <div className="md:w-1/3 lg:w-1/4" data-id="fdd9zc7lx" data-path="scripts/pages/MerchantProfilePage.js">
            <div className="bg-white rounded-lg shadow-md p-5 mb-6" data-id="njtp7j6ko" data-path="scripts/pages/MerchantProfilePage.js">
              <button
                onClick={handleFollowToggle}
                className={`w-full py-2 px-4 rounded-md mb-4 flex items-center justify-center ${
                isFollowing ?
                'bg-gray-100 text-gray-800 border border-gray-300 hover:bg-gray-200' :
                'bg-primary-color text-white hover:bg-primary-dark'}`
                } data-id="2bbzdp5iz" data-path="scripts/pages/MerchantProfilePage.js">

                <i className={`${isFollowing ? 'fas fa-user-check' : 'fas fa-user-plus'} mr-2`} data-id="w2jaol36w" data-path="scripts/pages/MerchantProfilePage.js"></i>
                {isFollowing ? 'Following' : 'Follow'}
              </button>
              
              <div className="mb-4" data-id="cl0dpot46" data-path="scripts/pages/MerchantProfilePage.js">
                <h3 className="font-semibold mb-2" data-id="9gq6ul6r3" data-path="scripts/pages/MerchantProfilePage.js">About</h3>
                <p className="text-sm text-gray-600" data-id="ynylkcccq" data-path="scripts/pages/MerchantProfilePage.js">{merchant.description}</p>
              </div>
              
              <div className="mb-4" data-id="3igvzyhwp" data-path="scripts/pages/MerchantProfilePage.js">
                <h3 className="font-semibold mb-2" data-id="la1pg4hra" data-path="scripts/pages/MerchantProfilePage.js">Website</h3>
                <a
                  href={merchant.website}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-sm text-primary-color hover:underline flex items-center" data-id="93nwpu75k" data-path="scripts/pages/MerchantProfilePage.js">

                  <i className="fas fa-external-link-alt mr-1" data-id="9ffgo4gci" data-path="scripts/pages/MerchantProfilePage.js"></i> Visit Website
                </a>
              </div>
              
              <div data-id="xk4f4ru83" data-path="scripts/pages/MerchantProfilePage.js">
                <h3 className="font-semibold mb-2" data-id="2als3ehd6" data-path="scripts/pages/MerchantProfilePage.js">Social Media</h3>
                <div className="flex space-x-2" data-id="j881j9dw2" data-path="scripts/pages/MerchantProfilePage.js">
                  {merchant.socialMedia.facebook &&
                  <a
                    href={`https://facebook.com/${merchant.socialMedia.facebook}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-blue-600 hover:text-blue-800" data-id="ngr18tl3w" data-path="scripts/pages/MerchantProfilePage.js">

                      <i className="fab fa-facebook-square text-xl" data-id="2mkmor6e0" data-path="scripts/pages/MerchantProfilePage.js"></i>
                    </a>
                  }
                  {merchant.socialMedia.instagram &&
                  <a
                    href={`https://instagram.com/${merchant.socialMedia.instagram}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-pink-600 hover:text-pink-800" data-id="c4ldyilvo" data-path="scripts/pages/MerchantProfilePage.js">

                      <i className="fab fa-instagram text-xl" data-id="rbo6kdvtv" data-path="scripts/pages/MerchantProfilePage.js"></i>
                    </a>
                  }
                  {merchant.socialMedia.twitter &&
                  <a
                    href={`https://twitter.com/${merchant.socialMedia.twitter}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-blue-400 hover:text-blue-600" data-id="13wxnrbr9" data-path="scripts/pages/MerchantProfilePage.js">

                      <i className="fab fa-twitter text-xl" data-id="0hm0hy53p" data-path="scripts/pages/MerchantProfilePage.js"></i>
                    </a>
                  }
                </div>
              </div>
            </div>
          </div>
          
          {/* Main Content */}
          <div className="md:w-2/3 lg:w-3/4" data-id="r5ngtda3n" data-path="scripts/pages/MerchantProfilePage.js">
            <div className="bg-white rounded-lg shadow-md p-5" data-id="82nsnvzym" data-path="scripts/pages/MerchantProfilePage.js">
              <div className="flex border-b mb-4" data-id="vhj7jrryd" data-path="scripts/pages/MerchantProfilePage.js">
                <button
                  className={`py-2 px-4 font-medium ${activeTab === 'active' ? 'text-primary-color border-b-2 border-primary-color' : 'text-gray-500'}`}
                  onClick={() => setActiveTab('active')} data-id="n3qate0a1" data-path="scripts/pages/MerchantProfilePage.js">

                  Active Deals
                </button>
                <button
                  className={`py-2 px-4 font-medium ${activeTab === 'expired' ? 'text-primary-color border-b-2 border-primary-color' : 'text-gray-500'}`}
                  onClick={() => setActiveTab('expired')} data-id="g8gg4gujl" data-path="scripts/pages/MerchantProfilePage.js">

                  Past Deals
                </button>
                <button
                  className={`py-2 px-4 font-medium ${activeTab === 'all' ? 'text-primary-color border-b-2 border-primary-color' : 'text-gray-500'}`}
                  onClick={() => setActiveTab('all')} data-id="bj4nwsbpa" data-path="scripts/pages/MerchantProfilePage.js">

                  All Deals
                </button>
              </div>
              
              {filteredPromotions.length === 0 ?
              <div className="text-center py-10" data-id="2c8l67ysl" data-path="scripts/pages/MerchantProfilePage.js">
                  <i className="fas fa-tag text-gray-300 text-5xl mb-4" data-id="ho3zgxist" data-path="scripts/pages/MerchantProfilePage.js"></i>
                  <p className="text-gray-500" data-id="ezmie3ftb" data-path="scripts/pages/MerchantProfilePage.js">No {activeTab !== 'all' ? activeTab : ''} deals available</p>
                </div> :

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4" data-id="fh458uifj" data-path="scripts/pages/MerchantProfilePage.js">
                  {filteredPromotions.map((promotion) =>
                <PromotionCard key={promotion.id} promotion={promotion} />
                )}
                </div>
              }
            </div>
          </div>
        </div>
      </div>
    </div>);

}