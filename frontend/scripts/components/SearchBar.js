function SearchBar({ onSearch, initialValue = '' }) {
  const { useState, useEffect } = React;
  const [searchTerm, setSearchTerm] = useState(initialValue);

  const handleSearch = (e) => {
    e.preventDefault();
    onSearch(searchTerm);
  };

  // Debounce search as user types
  useEffect(() => {
    const timer = setTimeout(() => {
      onSearch(searchTerm);
    }, 500);

    return () => clearTimeout(timer);
  }, [searchTerm]);

  return (
    <div className="search-container mx-auto my-4" data-id="25b5jau6e" data-path="scripts/components/SearchBar.js">
      <form onSubmit={handleSearch} data-id="e9titpi4g" data-path="scripts/components/SearchBar.js">
        <div className="relative" data-id="j6k86v696" data-path="scripts/components/SearchBar.js">
          <i className="fas fa-search search-icon" data-id="9vi9zmbtd" data-path="scripts/components/SearchBar.js"></i>
          <input
            type="text"
            placeholder="Search for deals, stores, or categories..."
            className="search-input"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)} data-id="sw4wed13u" data-path="scripts/components/SearchBar.js" />

        </div>
      </form>
    </div>);

}