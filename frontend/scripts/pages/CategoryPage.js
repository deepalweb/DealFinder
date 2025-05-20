function CategoryPage() {
  const { useState, useEffect } = React;
  const { useParams } = ReactRouterDOM;
  const { categoryId } = useParams();

  const [promotions, setPromotions] = useState([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [sortBy, setSortBy] = useState('newest');
  const [isOnlyActive, setIsOnlyActive] = useState(true);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    filterAndSortPromotions();
  }, [categoryId, searchTerm, sortBy, isOnlyActive]);

  const filterAndSortPromotions = async () => {
    try {
      setLoading(true);
      
      // Refresh promotions data to include any new promotions from API and demo merchant
      const allPromotions = await window.getPromotionsData();
      window.promotionsData = allPromotions;
      
      // Filter promotions based on category, search, and active status
      const filteredPromos = filterPromotions(allPromotions, {
        category: categoryId === 'all' ? '' : categoryId,
        searchTerm,
        onlyActive: isOnlyActive
      });

      // Sort the filtered promotions
      const sortedPromos = sortPromotions(filteredPromos, sortBy);
      setPromotions(sortedPromos);
      setLoading(false);
    } catch (error) {
      console.error('Error filtering promotions:', error);
      setLoading(false);
    }
  };

  const handleSearch = (term) => {
    setSearchTerm(term);
  };

  const handleSortChange = (e) => {
    setSortBy(e.target.value);
  };

  const handleActiveToggle = () => {
    setIsOnlyActive(!isOnlyActive);
  };

  // Find the category object for the title
  const currentCategory = categories.find((cat) => cat.id === categoryId) || { name: 'All Deals', icon: 'fa-tag' };

  return (
    <div className="page-container">
      <div className="container py-8">
        <h1 className="text-2xl md:text-3xl font-bold mb-6 flex items-center">
          <i className={`fas ${currentCategory.icon} mr-3 text-primary-color`}></i>
          {currentCategory.name}
        </h1>
        
        <div className="flex flex-col md:flex-row md:justify-between md:items-center gap-4 mb-6">
          <SearchBar onSearch={handleSearch} />
          
          <div className="flex flex-col sm:flex-row items-start sm:items-center gap-4">
            <div className="flex items-center">
              <label htmlFor="sortBy" className="mr-2 text-sm font-medium">Sort by:</label>
              <select
                id="sortBy"
                className="border rounded py-1 px-2"
                value={sortBy}
                onChange={handleSortChange}>
                <option value="newest">Newest</option>
                <option value="ending-soon">Ending Soon</option>
                <option value="discount">Biggest Discount</option>
              </select>
            </div>
            
            <div className="flex items-center">
              <input
                type="checkbox"
                id="activeOnly"
                className="mr-2"
                checked={isOnlyActive}
                onChange={handleActiveToggle} />
              <label htmlFor="activeOnly" className="text-sm font-medium">Active deals only</label>
            </div>
          </div>
        </div>
        
        <CategoryList
          selectedCategory={categoryId}
          onCategoryChange={(catId) => {}} />

        {loading ? (
          <div className="text-center py-12">
            <i className="fas fa-spinner fa-spin text-3xl text-primary-color"></i>
            <p className="mt-4 text-gray-600">Loading promotions...</p>
          </div>
        ) : promotions.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6 mt-6">
            {promotions.map((promotion) =>
              <div key={promotion.id}>
                <div onClick={() => window.location.href = `/deal/${promotion.id || promotion._id}`}
                  className="cursor-pointer">
                  <PromotionCard promotion={promotion} />
                </div>
              </div>
            )}
          </div>
        ) : (
          <div className="text-center py-12">
            <i className="fas fa-search text-5xl text-gray-300 mb-4"></i>
            <h2 className="text-xl font-semibold mb-2">No promotions found</h2>
            <p className="text-gray-500 mb-4">
              {searchTerm ?
                "Try different search terms or browse other categories" :
                "There are no active promotions in this category right now"}
            </p>
            {isOnlyActive &&
              <button
                className="btn btn-primary"
                onClick={handleActiveToggle}>
                Show Expired Deals
              </button>
            }
          </div>
        )}
      </div>
    </div>
  );
}