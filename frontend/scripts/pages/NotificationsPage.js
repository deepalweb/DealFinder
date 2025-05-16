function NotificationsPage() {
  const { useState, useEffect } = React;
  const { useNavigate } = ReactRouterDOM;
  const navigate = useNavigate();

  const [user, setUser] = useState(null);
  const [notifications, setNotifications] = useState([]);
  const [recommendations, setRecommendations] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Check if user is logged in
    const userData = localStorage.getItem('dealFinderUser');

    if (!userData) {
      navigate('/login');
      return;
    }

    setUser(JSON.parse(userData));

    // Load notifications
    // In a real app, this would fetch from an API
    const storedNotifications = JSON.parse(localStorage.getItem('dealFinderNotifications') || '[]');
    setNotifications(storedNotifications);

    // Generate deal recommendations
    setRecommendations(generateDealRecommendations());

    // Simulate checking for expiring deals
    checkExpiringDeals();

    setLoading(false);
  }, []);

  const handleSavePreferences = (preferences) => {
    if (updateUserPreferences({ notifications: preferences })) {
      alert('Notification settings updated successfully');
    }
  };

  if (loading) {
    return (
      <div className="page-container" data-id="6kb6ezha2" data-path="scripts/pages/NotificationsPage.js">
        <div className="container py-8 text-center" data-id="ot9rmxxib" data-path="scripts/pages/NotificationsPage.js">
          <i className="fas fa-spinner fa-spin text-3xl text-primary-color" data-id="a0gkv5wj7" data-path="scripts/pages/NotificationsPage.js"></i>
        </div>
      </div>);

  }

  return (
    <div className="page-container" data-id="ovtchswfu" data-path="scripts/pages/NotificationsPage.js">
      <div className="container py-8" data-id="q99edinbg" data-path="scripts/pages/NotificationsPage.js">
        <h1 className="text-2xl md:text-3xl font-bold mb-6 flex items-center" data-id="n2ox6kqnq" data-path="scripts/pages/NotificationsPage.js">
          <i className="fas fa-bell mr-3 text-primary-color" data-id="g2ejydpy4" data-path="scripts/pages/NotificationsPage.js"></i>
          Notifications & Recommendations
        </h1>
        
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6" data-id="rt5p1bj8z" data-path="scripts/pages/NotificationsPage.js">
          {/* Notification Settings Column */}
          <div className="lg:col-span-1" data-id="2eptoqvek" data-path="scripts/pages/NotificationsPage.js">
            <div className="bg-white rounded-lg shadow-md p-5 mb-6" data-id="2cxe3e4tj" data-path="scripts/pages/NotificationsPage.js">
              <h2 className="text-xl font-bold mb-4" data-id="l342qe0na" data-path="scripts/pages/NotificationsPage.js">Notification Settings</h2>
              
              <NotificationSettingsForm
                user={user}
                onSave={handleSavePreferences} />

            </div>
          </div>
          
          {/* Notifications & Recommendations Column */}
          <div className="lg:col-span-2" data-id="m0ydwkzj5" data-path="scripts/pages/NotificationsPage.js">
            {/* Recommendations */}
            <div className="bg-white rounded-lg shadow-md p-5 mb-6" data-id="ksa43r675" data-path="scripts/pages/NotificationsPage.js">
              <h2 className="text-xl font-bold mb-4" data-id="du0znzcif" data-path="scripts/pages/NotificationsPage.js">
                <i className="fas fa-lightbulb text-yellow-500 mr-2" data-id="9zlndrdp7" data-path="scripts/pages/NotificationsPage.js"></i>
                Recommended For You
              </h2>
              
              {recommendations.length > 0 ?
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4" data-id="fnb1uy9lk" data-path="scripts/pages/NotificationsPage.js">
                  {recommendations.map((promotion) =>
                <div key={promotion.id} className="border rounded-lg p-3 hover:shadow-md transition-shadow" data-id="ooljsnhu4" data-path="scripts/pages/NotificationsPage.js">
                      <div className="flex items-start" data-id="mm6w79o1v" data-path="scripts/pages/NotificationsPage.js">
                        <div className="flex-shrink-0 w-16 h-16 bg-gray-200 rounded overflow-hidden mr-3" data-id="6jgf76ftd" data-path="scripts/pages/NotificationsPage.js">
                          {promotion.image &&
                      <img
                        src={promotion.image}
                        alt={promotion.title}
                        className="w-full h-full object-cover" data-id="my7jbuk8b" data-path="scripts/pages/NotificationsPage.js" />

                      }
                        </div>
                        
                        <div className="flex-1" data-id="w6zesuwct" data-path="scripts/pages/NotificationsPage.js">
                          <h3 className="font-semibold text-sm" data-id="03znade0w" data-path="scripts/pages/NotificationsPage.js">{promotion.title}</h3>
                          <p className="text-sm text-gray-600" data-id="n40n18kol" data-path="scripts/pages/NotificationsPage.js">{promotion.merchant}</p>
                          <div className="flex items-center mt-1" data-id="myez021x2" data-path="scripts/pages/NotificationsPage.js">
                            <span className="inline-block bg-red-100 text-red-800 text-xs px-2 py-1 rounded" data-id="mis7h4w6z" data-path="scripts/pages/NotificationsPage.js">
                              {promotion.discount} OFF
                            </span>
                            <button
                          className="ml-2 text-xs text-primary-color hover:underline"
                          onClick={() => {
                            addToFavorites(promotion);
                            // Remove from recommendations
                            setRecommendations((prev) =>
                            prev.filter((p) => p.id !== promotion.id)
                            );
                          }} data-id="88hdmecdx" data-path="scripts/pages/NotificationsPage.js">

                              Save Deal
                            </button>
                          </div>
                        </div>
                      </div>
                    </div>
                )}
                </div> :

              <div className="text-center py-6" data-id="zg9i8c7re" data-path="scripts/pages/NotificationsPage.js">
                  <i className="fas fa-search text-gray-300 text-4xl mb-2" data-id="eu7glp27v" data-path="scripts/pages/NotificationsPage.js"></i>
                  <p className="text-gray-500" data-id="3hsre6wh7" data-path="scripts/pages/NotificationsPage.js">No recommendations available yet</p>
                  <p className="text-sm text-gray-400 mt-1" data-id="t67f9j867" data-path="scripts/pages/NotificationsPage.js">Save some deals to get personalized recommendations</p>
                </div>
              }
            </div>
            
            {/* Notifications */}
            <div className="bg-white rounded-lg shadow-md p-5" data-id="hk0drfchq" data-path="scripts/pages/NotificationsPage.js">
              <h2 className="text-xl font-bold mb-4" data-id="8l83bb3jf" data-path="scripts/pages/NotificationsPage.js">
                <i className="fas fa-inbox text-primary-color mr-2" data-id="7vh2gd2zb" data-path="scripts/pages/NotificationsPage.js"></i>
                Your Notifications
              </h2>
              
              {notifications.length > 0 ?
              <div className="divide-y" data-id="4ymty3mdx" data-path="scripts/pages/NotificationsPage.js">
                  {notifications.map((notification) =>
                <div key={notification.id} className="py-3" data-id="5zjgws9fg" data-path="scripts/pages/NotificationsPage.js">
                      <div className="flex justify-between items-start" data-id="hypaso0am" data-path="scripts/pages/NotificationsPage.js">
                        <h3 className="font-semibold" data-id="bp2qawz3c" data-path="scripts/pages/NotificationsPage.js">{notification.subject}</h3>
                        <span className="text-xs text-gray-500" data-id="0k6p563z2" data-path="scripts/pages/NotificationsPage.js">
                          {new Date(notification.createdAt).toLocaleDateString()}
                        </span>
                      </div>
                      <p className="text-sm text-gray-600 mt-1 whitespace-pre-line" data-id="7qyp1t9ej" data-path="scripts/pages/NotificationsPage.js">
                        {notification.message}
                      </p>
                    </div>
                )}
                </div> :

              <div className="text-center py-6" data-id="fwe4jbs5b" data-path="scripts/pages/NotificationsPage.js">
                  <i className="fas fa-bell-slash text-gray-300 text-4xl mb-2" data-id="ximyiak52" data-path="scripts/pages/NotificationsPage.js"></i>
                  <p className="text-gray-500" data-id="8bmuwvq9z" data-path="scripts/pages/NotificationsPage.js">No notifications yet</p>
                </div>
              }
            </div>
          </div>
        </div>
      </div>
    </div>);

}

// Notification Settings Form Component
function NotificationSettingsForm({ user, onSave }) {
  const { useState, useEffect } = React;

  const [preferences, setPreferences] = useState({
    email: true,
    expiringDeals: true,
    favoriteStores: true,
    recommendations: true
  });

  useEffect(() => {
    if (user && user.preferences?.notifications) {
      setPreferences(user.preferences.notifications);
    }
  }, [user]);

  const handleChange = (e) => {
    const { name, checked } = e.target;
    setPreferences((prev) => ({
      ...prev,
      [name]: checked
    }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    onSave(preferences);
  };

  return (
    <form onSubmit={handleSubmit} data-id="5u3iawqup" data-path="scripts/pages/NotificationsPage.js">
      <div className="space-y-4" data-id="n11gdc71c" data-path="scripts/pages/NotificationsPage.js">
        <div className="flex items-start" data-id="o274z0ljg" data-path="scripts/pages/NotificationsPage.js">
          <div className="flex items-center h-5" data-id="phrthdfsl" data-path="scripts/pages/NotificationsPage.js">
            <input
              id="email"
              name="email"
              type="checkbox"
              checked={preferences.email}
              onChange={handleChange}
              className="h-4 w-4 text-primary-color focus:ring-primary-color border-gray-300 rounded" data-id="1buaqzen2" data-path="scripts/pages/NotificationsPage.js" />

          </div>
          <div className="ml-3 text-sm" data-id="ccshy5pj7" data-path="scripts/pages/NotificationsPage.js">
            <label htmlFor="email" className="font-medium text-gray-700" data-id="7ed80kgm5" data-path="scripts/pages/NotificationsPage.js">Email Notifications</label>
            <p className="text-gray-500" data-id="amx0180hh" data-path="scripts/pages/NotificationsPage.js">Receive notifications via email</p>
          </div>
        </div>
        
        <div className="flex items-start" data-id="rku47bw0a" data-path="scripts/pages/NotificationsPage.js">
          <div className="flex items-center h-5" data-id="1vlib7k9z" data-path="scripts/pages/NotificationsPage.js">
            <input
              id="expiringDeals"
              name="expiringDeals"
              type="checkbox"
              checked={preferences.expiringDeals}
              onChange={handleChange}
              className="h-4 w-4 text-primary-color focus:ring-primary-color border-gray-300 rounded" data-id="1okw3qw9w" data-path="scripts/pages/NotificationsPage.js" />

          </div>
          <div className="ml-3 text-sm" data-id="7zoiyl4g4" data-path="scripts/pages/NotificationsPage.js">
            <label htmlFor="expiringDeals" className="font-medium text-gray-700" data-id="sozkqwumt" data-path="scripts/pages/NotificationsPage.js">Expiring Deals</label>
            <p className="text-gray-500" data-id="gw9ifdo84" data-path="scripts/pages/NotificationsPage.js">Get notified when your saved deals are about to expire</p>
          </div>
        </div>
        
        <div className="flex items-start" data-id="nluu2p8ir" data-path="scripts/pages/NotificationsPage.js">
          <div className="flex items-center h-5" data-id="no3cme9ue" data-path="scripts/pages/NotificationsPage.js">
            <input
              id="favoriteStores"
              name="favoriteStores"
              type="checkbox"
              checked={preferences.favoriteStores}
              onChange={handleChange}
              className="h-4 w-4 text-primary-color focus:ring-primary-color border-gray-300 rounded" data-id="qqm9fbcp7" data-path="scripts/pages/NotificationsPage.js" />

          </div>
          <div className="ml-3 text-sm" data-id="6chpn0xsl" data-path="scripts/pages/NotificationsPage.js">
            <label htmlFor="favoriteStores" className="font-medium text-gray-700" data-id="vk8gyh2kq" data-path="scripts/pages/NotificationsPage.js">Favorite Stores</label>
            <p className="text-gray-500" data-id="6wmltngcl" data-path="scripts/pages/NotificationsPage.js">Get notified about new deals from your favorite stores</p>
          </div>
        </div>
        
        <div className="flex items-start" data-id="53bd5docd" data-path="scripts/pages/NotificationsPage.js">
          <div className="flex items-center h-5" data-id="9mk5u8ypr" data-path="scripts/pages/NotificationsPage.js">
            <input
              id="recommendations"
              name="recommendations"
              type="checkbox"
              checked={preferences.recommendations}
              onChange={handleChange}
              className="h-4 w-4 text-primary-color focus:ring-primary-color border-gray-300 rounded" data-id="u3425pm8h" data-path="scripts/pages/NotificationsPage.js" />

          </div>
          <div className="ml-3 text-sm" data-id="6xbxs3t0g" data-path="scripts/pages/NotificationsPage.js">
            <label htmlFor="recommendations" className="font-medium text-gray-700" data-id="r1yp3kq1a" data-path="scripts/pages/NotificationsPage.js">Personalized Recommendations</label>
            <p className="text-gray-500" data-id="tj947qjoa" data-path="scripts/pages/NotificationsPage.js">Get recommendations based on your preferences</p>
          </div>
        </div>
      </div>
      
      <div className="mt-6" data-id="i2nke81nq" data-path="scripts/pages/NotificationsPage.js">
        <button type="submit" className="btn btn-primary" data-id="2sgx3zpvk" data-path="scripts/pages/NotificationsPage.js">
          Save Preferences
        </button>
        
        <button
          type="button"
          className="ml-4 text-sm text-primary-color hover:underline"
          onClick={() => {
            // Generate notifications for testing
            sendRecommendationNotifications();
            sendNewMerchantDealNotifications();
            // Force reload to show the new notifications
            window.location.reload();
          }} data-id="pbrvzwxhc" data-path="scripts/pages/NotificationsPage.js">

          Test Notifications
        </button>
      </div>
    </form>);

}