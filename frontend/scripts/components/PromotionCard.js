function PromotionCard({ promotion, onFavoriteToggle }) {
  const { useState, useEffect } = React;
  const daysRemaining = calculateDaysRemaining(promotion.endDate);
  const daysText = getDaysText(daysRemaining);
  const [isFavorite, setIsFavorite] = useState(false);

  // Check if promotion is in favorites on component mount
  useEffect(() => {
    // Check favorite status from parent or backend
    async function checkFavorite() {
      try {
        const userData = localStorage.getItem('dealFinderUser');
        if (!userData) {
          setIsFavorite(false);
          return;
        }
        const user = JSON.parse(userData);
        const favorites = await window.API.Users.getFavorites(user._id);
        setIsFavorite(favorites.some(fav => (fav.id || fav._id) === (promotion.id || promotion._id)));
      } catch {
        setIsFavorite(false);
      }
    }
    checkFavorite();
  }, [promotion.id, promotion._id]);

  const handleCopyCode = (event) => {
    event.preventDefault();
    copyToClipboard(promotion.code);
  };

  const handleFavoriteToggle = async (event) => {
    event.preventDefault();
    event.stopPropagation();
    const userData = localStorage.getItem('dealFinderUser');
    if (!userData) return;
    const user = JSON.parse(userData);
    const newFavoriteStatus = !isFavorite;
    try {
      if (newFavoriteStatus) {
        await window.API.Users.addFavorite(user._id, promotion.id || promotion._id);
      } else {
        await window.API.Users.removeFavorite(user._id, promotion.id || promotion._id);
      }
      setIsFavorite(newFavoriteStatus);
      if (onFavoriteToggle) {
        onFavoriteToggle(promotion.id, newFavoriteStatus);
      }
    } catch (err) {
      console.error('Failed to update favorite:', err);
    }
  };

  // Helper to get merchant name safely
  function getMerchantName(merchant) {
    if (!merchant) return '';
    if (typeof merchant === 'string') return merchant;
    if (typeof merchant === 'object' && merchant.name) return merchant.name;
    return '';
  }

  const handleCardClick = (event) => {
    // Don't redirect if the click is on the favorite button or copy button
    if (event.target.closest('button')) return;

    // If promotion has URL, navigate to it
    if (promotion.url) {
      // Track this click for analytics before redirecting
      const promoId = promotion.id || promotion._id;
      trackPromotionClick(promoId, promotion.title, getMerchantName(promotion.merchant));

      // Open URL in a new tab
      window.open(promotion.url, '_blank', 'noopener,noreferrer');
    }
  };

  return (
    <div
      className={`promotion-card fade-in relative transform transition-all duration-200 hover:scale-105 hover:shadow-2xl ${promotion.url ? 'cursor-pointer hover:shadow-lg transition-shadow' : ''}`}
      onClick={promotion.url ? handleCardClick : undefined} data-id="fvxy2i9nx" data-path="scripts/components/PromotionCard.js"
    >
      {promotion.url && (
        <div className="absolute top-2 right-2 z-10 text-primary-color">
          <i className="fas fa-external-link-alt"></i>
        </div>
      )}
      <button
        className="absolute top-2 left-2 z-10 text-xl p-1 rounded-full bg-white bg-opacity-75 hover:bg-opacity-100 transition-all hover:scale-125 hover:shadow-md"
        onClick={handleFavoriteToggle}
        aria-label={isFavorite ? 'Remove from favorites' : 'Add to favorites'}
      >
        <i className={`${isFavorite ? 'fas text-red-500' : 'far text-gray-600'} fa-heart`}></i>
      </button>
      <div className="relative">
        <img
          src={promotion.image}
          alt={promotion.title}
          className="promo-image rounded-t-lg border-b border-gray-100 group-hover:brightness-95 group-hover:scale-102 transition-transform duration-200" />
        <div className="discount-badge flex items-center gap-1 font-bold text-primary-dark text-sm absolute top-2 right-2">
          <i className="fas fa-percentage mr-1 text-xs"></i>
          {promotion.discount} OFF
        </div>
      </div>
      <div className="p-4">
        <div className="flex justify-between items-center mb-2">
          <p className="promo-merchant flex items-center gap-1">
            <i className="fas fa-store-alt mr-1 text-primary-color"></i>{getMerchantName(promotion.merchant)}
          </p>
          <div className="expiry-tag flex items-center gap-1 bg-gray-100 px-2 py-1 rounded-full text-xs">
            <i className="far fa-clock"></i> {daysText}
          </div>
        </div>
        <h3 className="promo-title flex items-center gap-2 text-lg font-semibold">
          <i className="fas fa-tag text-accent-color"></i>{promotion.title}
        </h3>
        <p className="promo-description mb-4 text-gray-700 flex items-center gap-2 text-sm">
          <i className="fas fa-info-circle text-gray-400"></i>{promotion.description}
        </p>
        <div className="flex justify-between items-center mt-2">
          <div className="flex items-center">
            <span className="text-sm mr-2 flex items-center gap-1">
              <i className="fas fa-ticket-alt text-secondary-color"></i>Code:
            </span>
            <code className="promo-code bg-gray-100 px-2 py-1 rounded-md border border-gray-200 font-mono text-base">{promotion.code}</code>
          </div>
          <button
            onClick={handleCopyCode}
            className="btn btn-primary text-sm flex items-center gap-1 hover:scale-105 hover:shadow-md transition-all group"
            title="Copy code to clipboard"
          >
            <i className="far fa-copy"></i> Copy
          </button>
        </div>
      </div>
    </div>
  );
}
