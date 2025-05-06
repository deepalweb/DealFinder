function CategoryList({ selectedCategory, onCategoryChange }) {
  const { useNavigate } = ReactRouterDOM;
  const navigate = useNavigate();

  const handleCategoryClick = (categoryId) => {
    onCategoryChange(categoryId);
    navigate(`/categories/${categoryId}`);
  };

  return (
    <div className="category-list-container my-4" data-id="utmhwtq33" data-path="scripts/components/CategoryList.js">
      <div className="category-list" data-id="rdn6rx27z" data-path="scripts/components/CategoryList.js">
        {categories.map((category) =>
        <button
          key={category.id}
          className={`category-item ${selectedCategory === category.id ? 'active' : ''}`}
          onClick={() => handleCategoryClick(category.id)} data-id="2697t1tgw" data-path="scripts/components/CategoryList.js">

            <i className={`fas ${category.icon} mr-2`} data-id="nftnxbdk8" data-path="scripts/components/CategoryList.js"></i>
            {category.name}
          </button>
        )}
      </div>
    </div>);

}