function LocationPicker({ location, onLocationChange }) {
  const { useState, useEffect, useRef } = React;

  const mapRef = useRef(null);
  const leafletMap = useRef(null);
  const markerRef = useRef(null);

  const [inputValue, setInputValue] = useState('');
  const [suggestions, setSuggestions] = useState([]);
  const [showDropdown, setShowDropdown] = useState(false);
  const [searching, setSearching] = useState(false);
  const [noResults, setNoResults] = useState(false);

  const hasCoords = location && location.coordinates &&
    location.coordinates[0] != null && location.coordinates[1] != null;

  const defaultCenter = [7.8731, 80.7718]; // Sri Lanka
  const initialCenter = hasCoords
    ? [location.coordinates[1], location.coordinates[0]]
    : defaultCenter;

  useEffect(() => {
    const initMap = () => {
      if (leafletMap.current) return;
      const L = window.L;
      if (!L) return;

      leafletMap.current = L.map(mapRef.current).setView(initialCenter, hasCoords ? 15 : 8);

      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
      }).addTo(leafletMap.current);

      markerRef.current = L.marker(initialCenter, { draggable: true }).addTo(leafletMap.current);

      markerRef.current.on('dragend', () => {
        const pos = markerRef.current.getLatLng();
        reverseGeocode(pos.lat, pos.lng);
        onLocationChange({ type: 'Point', coordinates: [pos.lng, pos.lat] });
      });

      leafletMap.current.on('click', (e) => {
        const { lat, lng } = e.latlng;
        markerRef.current.setLatLng([lat, lng]);
        reverseGeocode(lat, lng);
        onLocationChange({ type: 'Point', coordinates: [lng, lat] });
      });
    };

    if (window.L) {
      initMap();
    } else {
      const script = document.createElement('script');
      script.src = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js';
      script.onload = initMap;
      document.head.appendChild(script);
    }

    return () => {
      if (leafletMap.current) {
        leafletMap.current.remove();
        leafletMap.current = null;
      }
    };
  }, []);

  const reverseGeocode = async (lat, lng) => {
    try {
      const res = await fetch(`/api/maps/nominatim/reverse?lat=${lat}&lon=${lng}`);
      const data = await res.json();
      if (data && data.display_name) setInputValue(data.display_name);
    } catch (e) {}
  };

  const doSearch = async () => {
    const q = inputValue.trim();
    if (!q) return;
    setSearching(true);
    setNoResults(false);
    setSuggestions([]);
    setShowDropdown(false);
    try {
      const res = await fetch(`/api/maps/nominatim/search?q=${encodeURIComponent(q)}`);
      const data = await res.json();
      setSuggestions(data);
      setNoResults(data.length === 0);
      setShowDropdown(true);
    } catch (e) {
      setNoResults(true);
    } finally {
      setSearching(false);
    }
  };

  const handleKeyDown = (e) => {
    if (e.key === 'Enter') { e.preventDefault(); doSearch(); }
  };

  const handleSelect = (item) => {
    const lat = parseFloat(item.lat);
    const lng = parseFloat(item.lon);
    setInputValue(item.display_name);
    setSuggestions([]);
    setShowDropdown(false);
    setNoResults(false);

    if (leafletMap.current && markerRef.current) {
      markerRef.current.setLatLng([lat, lng]);
      leafletMap.current.setView([lat, lng], 16);
    }
    onLocationChange({ type: 'Point', coordinates: [lng, lat] });
  };

  return (
    <div className="md:col-span-2">
      <label className="block text-sm font-medium mb-1">
        <i className="fas fa-map-marker-alt text-primary-color mr-1"></i> Store Location
      </label>
      <p className="text-xs text-gray-500 mb-2">
        Search for your store address, or click / drag the pin on the map.
      </p>

      {/* Search Bar */}
      <div className="relative mb-2">
        <div className="flex gap-2">
          <div className="relative flex-1">
            <i className="fas fa-search absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm pointer-events-none"></i>
            <input
              type="text"
              value={inputValue}
              onChange={e => { setInputValue(e.target.value); setShowDropdown(false); setNoResults(false); }}
              onKeyDown={handleKeyDown}
              onBlur={() => setTimeout(() => setShowDropdown(false), 200)}
              placeholder="e.g. 123 Main Street, Colombo"
              className="w-full pl-9 pr-8 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-color text-sm"
              autoComplete="off"
            />
            {inputValue && (
              <button
                type="button"
                onClick={() => { setInputValue(''); setSuggestions([]); setShowDropdown(false); setNoResults(false); }}
                className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
              >
                <i className="fas fa-times text-xs"></i>
              </button>
            )}
          </div>
          <button
            type="button"
            onClick={doSearch}
            disabled={searching || !inputValue.trim()}
            className="px-4 py-2 bg-primary-color text-white rounded-md hover:bg-primary-dark disabled:opacity-50 flex items-center gap-2 text-sm whitespace-nowrap"
          >
            {searching
              ? <><i className="fas fa-spinner fa-spin"></i> Searching...</>
              : <><i className="fas fa-search"></i> Search</>
            }
          </button>
        </div>

        {/* Results dropdown */}
        {showDropdown && suggestions.length > 0 && (
          <div className="absolute z-50 w-full bg-white border border-gray-300 rounded-md mt-1 shadow-xl max-h-56 overflow-y-auto">
            {suggestions.map((s, i) => (
              <div
                key={i}
                className="flex items-start gap-3 px-4 py-3 cursor-pointer hover:bg-indigo-50 border-b border-gray-100 last:border-0"
                onMouseDown={() => handleSelect(s)}
              >
                <i className="fas fa-map-marker-alt text-primary-color mt-0.5 flex-shrink-0"></i>
                <div>
                  <p className="text-sm font-medium text-gray-800 leading-tight">
                    {s.address?.road || s.address?.amenity || s.name || s.display_name.split(',')[0]}
                  </p>
                  <p className="text-xs text-gray-500 mt-0.5">{s.display_name}</p>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* No results */}
        {noResults && (
          <div className="absolute z-50 w-full bg-white border border-gray-300 rounded-md mt-1 shadow-xl px-4 py-3 text-sm text-gray-500">
            <i className="fas fa-exclamation-circle mr-2 text-yellow-500"></i>
            No results found. Try a different search term.
          </div>
        )}
      </div>

      {/* Map */}
      <div
        ref={mapRef}
        style={{ height: '320px', width: '100%', borderRadius: '8px', zIndex: 0, border: '1px solid #e5e7eb' }}
      />
      <p className="text-xs text-gray-400 mt-1">
        <i className="fas fa-info-circle mr-1"></i>
        You can also click anywhere on the map or drag the pin to set the location.
      </p>
    </div>
  );
}
