// DealPage.js - Single deal view with comments, ratings, and sharing
function DealPage() {
  const { useParams, useNavigate } = ReactRouterDOM;
  const { useState, useEffect } = React;
  const { dealId } = useParams();
  const navigate = useNavigate();
  const [deal, setDeal] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    async function fetchDeal() {
      setLoading(true);
      try {
        const res = await fetch(`/api/promotions/${dealId}`);
        if (!res.ok) throw new Error("Deal not found");
        setDeal(await res.json());
      } catch (err) {
        setError("Deal not found or failed to load.");
      }
      setLoading(false);
    }
    fetchDeal();
  }, [dealId]);

  if (loading) return <div className="container py-8 text-center"><i className="fas fa-spinner fa-spin text-3xl text-primary-color"></i></div>;
  if (error || !deal) return <div className="container py-8 text-center text-red-500">{error || "Deal not found."}</div>;

  // Share handler
  const handleShare = () => {
    const url = window.location.href;
    if (navigator.share) {
      navigator.share({ title: deal.title, text: deal.description, url });
    } else {
      navigator.clipboard.writeText(url);
      alert("Deal link copied to clipboard!");
    }
  };

  return (
    <div className="container max-w-xl mx-auto py-8">
      <button className="mb-4 text-primary-color hover:underline" onClick={() => navigate(-1)}><i className="fas fa-arrow-left mr-1"></i>Back</button>
      <div className="bg-white rounded-lg shadow-md p-4">
        <div className="mb-4 flex flex-col items-center">
          <img src={deal.image} alt={deal.title} className="w-48 h-48 object-cover rounded mb-2" />
          <h1 className="text-2xl font-bold mb-1">{deal.title}</h1>
          <div className="text-gray-600 mb-2">{deal.description}</div>

          {/* Price Display for Deal Page */}
          {(deal.price || deal.originalPrice || deal.discountedPrice) && (
            <div className="my-3 p-3 bg-gray-50 rounded-md price-details">
              {deal.discountedPrice && deal.originalPrice ? (
                <div>
                  <p className="text-2xl font-bold text-red-700">
                    ${deal.discountedPrice.toFixed(2)}
                  </p>
                  <p className="text-md text-gray-500 ">
                    Original Price: <span className="line-through">${deal.originalPrice.toFixed(2)}</span>
                  </p>
                </div>
              ) : deal.price ? (
                <p className="text-2xl font-bold text-primary-color">${deal.price.toFixed(2)}</p>
              ) : deal.discountedPrice ? (
                <p className="text-2xl font-bold text-red-700">${deal.discountedPrice.toFixed(2)}</p>
              ) : deal.originalPrice ? (
                <p className="text-xl text-gray-700">${deal.originalPrice.toFixed(2)} (Original Price)</p>
              ) : null}
            </div>
          )}

          <div className="mb-2 flex gap-2 items-center">
            <span className="bg-primary-color text-white px-2 py-1 rounded text-sm font-semibold">{deal.discount} OFF</span>
            <span className="text-xs text-gray-500">Code: <code className="bg-gray-100 px-1 rounded">{deal.code}</code></span>
          </div>
          <div className="mb-2 text-xs text-gray-500">{new Date(deal.startDate).toLocaleDateString()} - {new Date(deal.endDate).toLocaleDateString()}</div>
          {/* Price Section */}
          {(deal.price || deal.originalPrice || deal.discountedPrice) && (
            <div className="mb-2 flex gap-2 items-center">
              {deal.originalPrice && (
                <span className="line-through text-gray-400 text-base">Rs. {deal.originalPrice.toFixed(2)}</span>
              )}
              {deal.discountedPrice && (
                <span className="text-green-600 font-bold text-lg">Rs. {deal.discountedPrice.toFixed(2)}</span>
              )}
              {deal.price && !deal.discountedPrice && (
                <span className="text-primary-color font-bold text-lg">Rs. {deal.price.toFixed(2)}</span>
              )}
            </div>
          )}
          <button className="btn btn-primary btn-sm mt-2" onClick={handleShare}><i className="fas fa-share-alt mr-1"></i>Share</button>
        </div>
        {/* Comments & Ratings UI (reuse PromotionCard logic) */}
        <div className="border-t pt-4 mt-4">
          <window.PromotionCard promotion={deal} singlePageMode={true} />
        </div>
      </div>
    </div>
  );
}

window.DealPage = DealPage;
