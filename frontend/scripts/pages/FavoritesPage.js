function FavoritesPage() {
  const { useState, useEffect } = React;
  const { Link } = ReactRouterDOM;

  const [favorites, setFavorites] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Load favorites from backend when component mounts
    loadFavorites();
  }, []);

  const loadFavorites = async () => {
    setLoading(true);
    try {
      const userData = localStorage.getItem('dealFinderUser');
      if (!userData) {
        setFavorites([]);
        setLoading(false);
        return;
      }
      const user = JSON.parse(userData);
      const favoritesData = await window.API.Users.getFavorites(user._id);
      // Ensure each favorite has 'id' property (from _id if needed)
      const formatted = favoritesData.map(p => ({ ...p, id: p.id || p._id }));
      setFavorites(formatted);
    } catch (err) {
      setFavorites([]);
      console.error('Failed to load favorites:', err);
    }
    setLoading(false);
  };

  const handleFavoriteToggle = async (promotionId, isFavorite) => {
    // Remove from favorites via backend, then update the list
    if (!isFavorite) {
      try {
        const userData = localStorage.getItem('dealFinderUser');
        if (!userData) return;
        const user = JSON.parse(userData);
        await window.API.Users.removeFavorite(user._id, promotionId);
        setFavorites((prevFavorites) =>
          prevFavorites.filter((promo) => promo.id !== promotionId)
        );
      } catch (err) {
        console.error('Failed to remove favorite:', err);
      }
    }
  };

  return (
    <div className="page-container" data-id="0jao1pr1z" data-path="scripts/pages/FavoritesPage.js">
      <div className="container py-8" data-id="dpg293xp3" data-path="scripts/pages/FavoritesPage.js">
        <h1 className="text-2xl md:text-3xl font-bold mb-6 flex items-center" data-id="jv8290sz1" data-path="scripts/pages/FavoritesPage.js">
          <i className="fas fa-heart mr-3 text-red-500" data-id="csyvjyd2h" data-path="scripts/pages/FavoritesPage.js"></i>
          My Favorite Deals
        </h1>
        
        {loading ?
        <div className="flex justify-center py-12" data-id="rlmpfkc8n" data-path="scripts/pages/FavoritesPage.js">
            <i className="fas fa-spinner fa-spin text-3xl text-primary-color" data-id="a4b6w5654" data-path="scripts/pages/FavoritesPage.js"></i>
          </div> :
        favorites.length > 0 ?
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6 mt-6" data-id="m8pd1a6jr" data-path="scripts/pages/FavoritesPage.js">
            {favorites.map((promotion) =>
          <PromotionCard
            key={promotion.id}
            promotion={promotion}
            onFavoriteToggle={handleFavoriteToggle} />

          )}
          </div> :

        <div className="text-center py-12 flex flex-col items-center justify-center" data-id="ldvllqagh" data-path="scripts/pages/FavoritesPage.js">
            <img src="https://cdn.jsdelivr.net/gh/edent/SuperTinyIcons/images/svg/empty-box.svg" alt="No favorites" className="w-24 h-24 mb-4 opacity-80" />
            <i className="far fa-heart text-5xl text-gray-300 mb-4"></i>
            <h2 className="text-xl font-semibold mb-2" data-id="s9rktchpy" data-path="scripts/pages/FavoritesPage.js">No favorite deals yet</h2>
            <p className="text-gray-500 mb-4" data-id="dcegvodia" data-path="scripts/pages/FavoritesPage.js">
              Start adding deals to your favorites by clicking the heart icon on any promotion
            </p>
            <Link to="/categories/all" className="btn btn-primary flex items-center gap-2">
              <i className="fas fa-search"></i> Browse All Deals
            </Link>
          </div>
        }
      </div>
    </div>);

}