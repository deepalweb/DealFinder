function FavoritesPage() {
  const { useState, useEffect } = React;
  const { Link } = ReactRouterDOM;

  const [favorites, setFavorites] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Load favorites when component mounts
    loadFavorites();
  }, []);

  const loadFavorites = () => {
    setLoading(true);
    const favoritesData = getFavoritePromotions();
    setFavorites(favoritesData);
    setLoading(false);
  };

  const handleFavoriteToggle = (promotionId, isFavorite) => {
    // If removed from favorites, update the list
    if (!isFavorite) {
      setFavorites((prevFavorites) =>
      prevFavorites.filter((promo) => promo.id !== promotionId)
      );
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

        <div className="text-center py-12" data-id="ldvllqagh" data-path="scripts/pages/FavoritesPage.js">
            <i className="far fa-heart text-5xl text-gray-300 mb-4" data-id="s27gee2a5" data-path="scripts/pages/FavoritesPage.js"></i>
            <h2 className="text-xl font-semibold mb-2" data-id="s9rktchpy" data-path="scripts/pages/FavoritesPage.js">No favorite deals yet</h2>
            <p className="text-gray-500 mb-4" data-id="dcegvodia" data-path="scripts/pages/FavoritesPage.js">
              Start adding deals to your favorites by clicking the heart icon on any promotion
            </p>
            <Link to="/categories/all" className="btn btn-primary">
              Browse All Deals
            </Link>
          </div>
        }
      </div>
    </div>);

}