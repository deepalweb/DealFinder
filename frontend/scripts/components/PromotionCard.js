function PromotionCard({ promotion, onFavoriteToggle, singlePageMode }) {
  const { useState, useEffect } = React;
  const daysRemaining = calculateDaysRemaining(promotion.endDate);
  const daysText = getDaysText(daysRemaining);
  const [isFavorite, setIsFavorite] = useState(false);
  const [hoverRating, setHoverRating] = useState(0);
  const [showAllEmojis, setShowAllEmojis] = useState(false);

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
    // If promotion has URL, navigate to it in the same tab
    if (promotion.url) {
      const promoId = promotion.id || promotion._id;
      trackPromotionClick(promoId, promotion.title, getMerchantName(promotion.merchant));
      window.location.href = promotion.url;
    }
  };

  // --- Comments & Ratings UI ---
  const [comments, setComments] = useState([]);
  const [commentText, setCommentText] = useState("");
  const [ratings, setRatings] = useState([]);
  const [userRating, setUserRating] = useState(0);
  const [loadingComments, setLoadingComments] = useState(false);
  const [loadingRatings, setLoadingRatings] = useState(false);

  // Fetch comments and ratings on mount
  useEffect(() => {
    async function fetchSocial() {
      setLoadingComments(true);
      setLoadingRatings(true);
      try {
        const [commentsRes, ratingsRes] = await Promise.all([
          fetch(`/api/promotions/${promotion.id || promotion._id}/comments`),
          fetch(`/api/promotions/${promotion.id || promotion._id}/ratings`)
        ]);
        setComments(await commentsRes.json());
        const ratingsData = await ratingsRes.json();
        setRatings(ratingsData);
        // Set user's rating if exists
        const userData = localStorage.getItem('dealFinderUser');
        if (userData) {
          const user = JSON.parse(userData);
          const found = ratingsData.find(r => r.user && (r.user._id === user._id));
          setUserRating(found ? found.value : 0);
        }
      } catch {}
      setLoadingComments(false);
      setLoadingRatings(false);
    }
    fetchSocial();
  }, [promotion.id, promotion._id]);

  // Add comment handler
  async function handleAddComment(e) {
    e.preventDefault();
    const userData = localStorage.getItem('dealFinderUser');
    if (!userData || !commentText.trim()) return;
    const user = JSON.parse(userData);
    const res = await fetch(`/api/promotions/${promotion.id || promotion._id}/comments`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ userId: user._id, text: commentText })
    });
    if (res.ok) {
      const newComment = await res.json();
      setComments([...comments, { ...newComment, user: { _id: user._id, name: user.name, email: user.email } }]);
      setCommentText("");
    }
  }

  // Add/update rating handler
  async function handleRate(value) {
    const userData = localStorage.getItem('dealFinderUser');
    if (!userData) return;
    const user = JSON.parse(userData);
    try {
      const res = await fetch(`/api/promotions/${promotion.id || promotion._id}/ratings`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId: user._id, value })
      });
      if (!res.ok) {
        let errorMsg = `Failed to save rating. Status: ${res.status}`;
        try {
          const errData = await res.json();
          errorMsg += `\n${errData.message || JSON.stringify(errData)}`;
        } catch {}
        alert(errorMsg);
        console.error('Rating save error:', res);
        return;
      }
      setUserRating(value);
      // Reload ratings after update
      const ratingsRes = await fetch(`/api/promotions/${promotion.id || promotion._id}/ratings`);
      setRatings(await ratingsRes.json());
    } catch (err) {
      alert('An error occurred while saving your rating. See console for details.');
      console.error('Rating save exception:', err);
    }
  }

  const averageRating = ratings.length > 0
    ? (ratings.reduce((sum, r) => sum + r.value, 0) / ratings.length).toFixed(1)
    : null;

  // Only show social features if singlePageMode is true
  if (singlePageMode) {
    return (
      <div>
        {/* Average Rating UI */}
        <div className="flex items-center mb-1">
          <span className="text-yellow-500 mr-1">
            {[1,2,3,4,5].map(star => (
              <i key={star} className={`fa-star ${averageRating && averageRating >= star ? 'fas' : 'far'}`}></i>
            ))}
          </span>
          {averageRating ? (
            <span className="text-xs text-gray-600">{averageRating} / 5</span>
          ) : (
            <span className="text-xs text-gray-400">No ratings yet</span>
          )}
        </div>
        {/* Ratings UI */}
        <div className="flex items-center mb-2">
          <span className="mr-2 text-sm text-gray-600">Rate this deal:</span>
          {[1,2,3,4,5].map(star => (
            <button
              key={star}
              type="button"
              onClick={() => handleRate(star)}
              onMouseEnter={() => setHoverRating(star)}
              onMouseLeave={() => setHoverRating(0)}
              className="focus:outline-none p-1 cursor-pointer group"
              aria-label={`Rate ${star} star${star > 1 ? 's' : ''}`}
              style={{ background: 'none', border: 'none' }}
            >
              <i className={`fa-star ${
                (hoverRating ? hoverRating >= star : userRating >= star)
                  ? 'fas text-yellow-400'
                  : 'far text-gray-400'
              } group-hover:text-yellow-500 transition-colors duration-150`}></i>
            </button>
          ))}
          <span className="ml-2 text-xs text-gray-500">({ratings.length} ratings)</span>
        </div>
        {/* Promo link button */}
        {promotion.url && (
          <div className="mb-2">
            <button className="btn btn-accent btn-xs" onClick={() => {
              const promoId = promotion.id || promotion._id;
              trackPromotionClick(promoId, promotion.title, getMerchantName(promotion.merchant));
              window.open(promotion.url, '_blank', 'noopener');
            }}>
              Go to Promotion
            </button>
          </div>
        )}
        {/* Comments UI */}
        <div className="mb-2">
          <div className="font-semibold text-sm mb-1">Comments</div>
          <div className="max-h-24 overflow-y-auto border rounded bg-gray-50 p-2 mb-1">
            {loadingComments ? <div>Loading...</div> :
              comments.length === 0 ? <div className="text-xs text-gray-400">No comments yet.</div> :
              comments.map((c, i) => (
                <div key={i} className="mb-1 text-xs"><span className="font-bold">{c.user?.name || c.user?.email || 'User'}:</span> {c.text}</div>
              ))}
          </div>
          {/* Emoji Picker with Expandable Option */}
          <div className="flex flex-wrap gap-1 mb-1 items-center">
            {/* Show a few common emojis by default */}
            {['😀','😂','😍','👍','🎉','🔥','😢','🙏'].map(emoji => (
              <button
                key={emoji}
                type="button"
                className="text-lg hover:scale-125 transition-transform"
                style={{ background: 'none', border: 'none', padding: 0, cursor: 'pointer' }}
                title={emoji}
                onClick={e => {
                  e.preventDefault();
                  const input = document.getElementById(`comment-input-${promotion.id || promotion._id}`);
                  if (input) {
                    const start = input.selectionStart;
                    const end = input.selectionEnd;
                    const value = input.value;
                    const newValue = value.slice(0, start) + emoji + value.slice(end);
                    input.value = newValue;
                    input.focus();
                    input.selectionStart = input.selectionEnd = start + emoji.length;
                    setCommentText(newValue);
                  }
                }}
              >{emoji}</button>
            ))}
            {/* Expand/collapse for more emojis */}
            <span>
              <button
                type="button"
                className="text-xs px-2 py-1 border rounded bg-gray-100 hover:bg-gray-200 ml-1"
                style={{ lineHeight: 1, fontWeight: 500 }}
                onClick={e => {
                  e.preventDefault();
                  setShowAllEmojis(v => !v);
                }}
              >{showAllEmojis ? 'Less...' : 'More...'}</button>
            </span>
            {showAllEmojis && (
              <div className="flex flex-wrap gap-1 mt-1">
                {['😎','🥳','😡','👏','💯','🤩','😅','😇','😜','😏','😬','🤔'].map(emoji => (
                  <button
                    key={emoji}
                    type="button"
                    className="text-lg hover:scale-125 transition-transform"
                    style={{ background: 'none', border: 'none', padding: 0, cursor: 'pointer' }}
                    title={emoji}
                    onClick={e => {
                      e.preventDefault();
                      const input = document.getElementById(`comment-input-${promotion.id || promotion._id}`);
                      if (input) {
                        const start = input.selectionStart;
                        const end = input.selectionEnd;
                        const value = input.value;
                        const newValue = value.slice(0, start) + emoji + value.slice(end);
                        input.value = newValue;
                        input.focus();
                        input.selectionStart = input.selectionEnd = start + emoji.length;
                        setCommentText(newValue);
                      }
                    }}
                  >{emoji}</button>
                ))}
              </div>
            )}
          </div>
          <form onSubmit={handleAddComment} className="flex gap-2 mt-1">
            <input id={`comment-input-${promotion.id || promotion._id}`} type="text" value={commentText} onChange={e => setCommentText(e.target.value)} className="flex-1 border rounded px-2 py-1 text-xs" placeholder="Add a comment..." maxLength={200} />
            <button type="submit" className="btn btn-primary btn-xs">Post</button>
          </form>
        </div>
        {/* Share button */}
        <div className="mb-2">
          <button className="btn btn-primary btn-xs" onClick={() => {
            const url = window.location.href;
            if (navigator.share) {
              navigator.share({ title: promotion.title, text: promotion.description, url });
            } else {
              navigator.clipboard.writeText(url);
              alert("Deal link copied to clipboard!");
            }
          }}><i className="fas fa-share-alt mr-1"></i>Share</button>
        </div>
      </div>
    );
  }

  return (
    <div
      className={`promotion-card fade-in relative transform transition-all duration-200 hover:scale-105 hover:shadow-2xl ${promotion.url ? 'cursor-pointer hover:shadow-lg transition-shadow' : ''}`}
      onClick={promotion.url ? handleCardClick : undefined} data-id="fvxy2i9nx" data-path="scripts/components/PromotionCard.js"
    >      {promotion.url && (
        <div className="absolute top-2 right-2 z-10">
          <button className="btn btn-accent btn-xs" onClick={e => {
            e.stopPropagation();
            const promoId = promotion.id || promotion._id;
            trackPromotionClick(promoId, promotion.title, getMerchantName(promotion.merchant));
            window.open(promotion.url, '_blank', 'noopener');
          }}>
            Go to Promotion
          </button>
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
        {/* Average Rating in Card View */}
        <div className="flex items-center mb-1 mt-1">
          <span className="text-yellow-500 mr-1">
            {[1,2,3,4,5].map(star => (
              <i key={star} className={`fa-star ${averageRating && averageRating >= star ? 'fas' : 'far'}`}></i>
            ))}
          </span>
          {averageRating ? (
            <span className="text-xs text-gray-600">{averageRating} / 5</span>
          ) : (
            <span className="text-xs text-gray-400">No ratings</span>
          )}
        </div>
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
        {/* Remove ratings, comments, and share from card view */}
      </div>
    </div>
  );
}
