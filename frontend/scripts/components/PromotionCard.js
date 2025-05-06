function PromotionCard({ promotion, onFavoriteToggle }) {
  const { useState, useEffect } = React;
  const daysRemaining = calculateDaysRemaining(promotion.endDate);
  const daysText = getDaysText(daysRemaining);
  const [isFavorite, setIsFavorite] = useState(false);

  // Check if promotion is in favorites on component mount
  useEffect(() => {
    setIsFavorite(isPromotionFavorite(promotion.id));
  }, [promotion.id]);

  const handleCopyCode = (event) => {
    event.preventDefault();
    copyToClipboard(promotion.code);
  };

  const handleFavoriteToggle = (event) => {
    event.preventDefault();
    event.stopPropagation();

    const newFavoriteStatus = !isFavorite;
    if (newFavoriteStatus) {
      addToFavorites(promotion);
    } else {
      removeFromFavorites(promotion.id);
    }

    setIsFavorite(newFavoriteStatus);

    // Call the optional callback if provided
    if (onFavoriteToggle) {
      onFavoriteToggle(promotion.id, newFavoriteStatus);
    }
  };

  const handleCardClick = (event) => {
    // Don't redirect if the click is on the favorite button or copy button
    if (event.target.closest('button')) return;

    // If promotion has URL, navigate to it
    if (promotion.url) {
      // Track this click for analytics before redirecting
      trackPromotionClick(promotion.id, promotion.title, promotion.merchant);

      // Open URL in a new tab
      window.open(promotion.url, '_blank', 'noopener,noreferrer');
    }
  };

  return (
    <div
      className={`promotion-card fade-in relative ${promotion.url ? 'cursor-pointer hover:shadow-lg transition-shadow' : ''}`}
      onClick={promotion.url ? handleCardClick : undefined} data-id="fvxy2i9nx" data-path="scripts/components/PromotionCard.js">
      {promotion.url && <div className="absolute top-2 right-2 z-10 text-primary-color" data-id="uqr1arni8" data-path="scripts/components/PromotionCard.js"><i className="fas fa-external-link-alt" data-id="dzieycn60" data-path="scripts/components/PromotionCard.js"></i></div>}
      <button
        className="absolute top-2 left-2 z-10 text-xl p-1 rounded-full bg-white bg-opacity-75 hover:bg-opacity-100 transition-all"
        onClick={handleFavoriteToggle}
        aria-label={isFavorite ? 'Remove from favorites' : 'Add to favorites'} data-id="ophilsedm" data-path="scripts/components/PromotionCard.js">

        <i className={`${isFavorite ? 'fas text-red-500' : 'far text-gray-600'} fa-heart`} data-id="nspxklhl0" data-path="scripts/components/PromotionCard.js"></i>
      </button>
      <div className="relative" data-id="mk6rbtgww" data-path="scripts/components/PromotionCard.js">
        <img
          src={promotion.image}
          alt={promotion.title}
          className="promo-image" data-id="w449psp12" data-path="scripts/components/PromotionCard.js" />

        <div className="discount-badge" data-id="3lpj2majj" data-path="scripts/components/PromotionCard.js">
          {promotion.discount} OFF
        </div>
      </div>
      
      <div className="p-4" data-id="a4nzs9vn4" data-path="scripts/components/PromotionCard.js">
        <div className="flex justify-between items-center mb-2" data-id="8wblidoua" data-path="scripts/components/PromotionCard.js">
          <p className="promo-merchant" data-id="fvsmm5ies" data-path="scripts/components/PromotionCard.js">{promotion.merchant}</p>
          <div className="expiry-tag" data-id="ht2kpl7tu" data-path="scripts/components/PromotionCard.js">
            <i className="far fa-clock" data-id="7fof49wud" data-path="scripts/components/PromotionCard.js"></i> {daysText}
          </div>
        </div>
        
        <h3 className="promo-title" data-id="pk2x3wl9r" data-path="scripts/components/PromotionCard.js">{promotion.title}</h3>
        <p className="promo-description mb-4" data-id="0bhjw6uew" data-path="scripts/components/PromotionCard.js">{promotion.description}</p>
        
        <div className="flex justify-between items-center mt-2" data-id="nvnblffz4" data-path="scripts/components/PromotionCard.js">
          <div className="flex items-center" data-id="m86g33u4d" data-path="scripts/components/PromotionCard.js">
            <span className="text-sm mr-2" data-id="qginijka0" data-path="scripts/components/PromotionCard.js">Code:</span>
            <code className="promo-code" data-id="zhk64jh57" data-path="scripts/components/PromotionCard.js">{promotion.code}</code>
          </div>
          
          <button
            onClick={handleCopyCode}
            className="btn btn-primary text-sm" data-id="dh6cf55ip" data-path="scripts/components/PromotionCard.js">

            <i className="far fa-copy mr-1" data-id="701j4r322" data-path="scripts/components/PromotionCard.js"></i> Copy
          </button>
        </div>
      </div>
    </div>);

}