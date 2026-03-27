function SearchBar({ onSearch, initialValue = '' }) {
  const { useState, useEffect } = React;
  const [searchTerm, setSearchTerm] = useState(initialValue);

  useEffect(() => {
    const timer = setTimeout(() => onSearch(searchTerm), 400);
    return () => clearTimeout(timer);
  }, [searchTerm]);

  return (
    <div className="search-container mx-auto">
      <i className="fas fa-search search-icon"></i>
      <input
        type="text"
        placeholder="Search deals, stores, categories..."
        className="search-input"
        value={searchTerm}
        onChange={(e) => setSearchTerm(e.target.value)}
      />
      {searchTerm && (
        <button className="search-clear" onClick={() => { setSearchTerm(''); onSearch(''); }}>
          <i className="fas fa-times"></i>
        </button>
      )}
    </div>
  );
}