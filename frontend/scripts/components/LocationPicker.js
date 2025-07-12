function LocationPicker({ location, onLocationChange }) {
  const { useState, useEffect, useRef } = React;

  // Refs for the map and its core components
  const mapRef = useRef(null);
  const googleMap = useRef(null);
  const marker = useRef(null);

  // State for the search input and autocomplete predictions
  const [inputValue, setInputValue] = useState("");
  const [predictions, setPredictions] = useState([]);
  const [isDropdownVisible, setIsDropdownVisible] = useState(false);

  // Default location (e.g., center of a country or a major city) if no location is set
  const defaultCenter = { lat: 40.7128, lng: -74.0060 }; // New York City

  // The component's internal state for the current location on the map
  const [currentMapCenter, setCurrentMapCenter] = useState(
    location && location.coordinates && location.coordinates[1] != null && location.coordinates[0] != null
      ? { lat: location.coordinates[1], lng: location.coordinates[0] }
      : defaultCenter
  );

  // --- Map Initialization and Marker Logic ---
  useEffect(() => {
    const initMap = () => {
      if (!window.google || !window.google.maps) {
        console.error("Google Maps script not loaded yet.");
        return;
      }

      googleMap.current = new window.google.maps.Map(mapRef.current, {
        center: currentMapCenter,
        zoom: location && location.coordinates[0] != null ? 15 : 8,
        mapTypeControl: false,
        streetViewControl: false,
      });

      marker.current = new window.google.maps.Marker({
        position: currentMapCenter,
        map: googleMap.current,
        draggable: true,
        title: "Drag me to set the location!",
      });

      marker.current.addListener('dragend', () => {
        const newPos = marker.current.getPosition();
        updateLocation({ lat: newPos.lat(), lng: newPos.lng() });
      });
    };

    if (window.googleMapsScriptLoaded) {
      initMap();
    } else {
      const interval = setInterval(() => {
        if (window.googleMapsScriptLoaded) {
          initMap();
          clearInterval(interval);
        }
      }, 100);
    }
  }, []); // Run only on mount

  // --- Autocomplete Search Logic ---
  useEffect(() => {
    // Debounce the API call
    const handler = setTimeout(() => {
      if (inputValue && isDropdownVisible) {
        window.API.Maps.getAutocomplete(inputValue)
          .then(data => {
            if (data && data.predictions) {
              setPredictions(data.predictions);
            }
          })
          .catch(error => console.error("Autocomplete fetch error:", error));
      } else {
        setPredictions([]);
      }
    }, 300); // 300ms debounce delay

    return () => {
      clearTimeout(handler);
    };
  }, [inputValue, isDropdownVisible]);

  const handleInputChange = (e) => {
    setInputValue(e.target.value);
    setIsDropdownVisible(true);
  };

  const handlePredictionClick = (placeId) => {
    setInputValue(""); // Clear input after selection
    setPredictions([]);
    setIsDropdownVisible(false);

    window.API.Maps.getPlaceDetails(placeId)
      .then(data => {
        if (data && data.result && data.result.geometry) {
          const newPos = data.result.geometry.location;
          updateLocation({ lat: newPos.lat, lng: newPos.lng() }, true);
        }
      })
      .catch(error => console.error("Place Details fetch error:", error));
  };

  // --- Helper function to update location state and map ---
  const updateLocation = (newPos, shouldZoom = true) => {
    setCurrentMapCenter(newPos);

    if (googleMap.current && marker.current) {
        googleMap.current.setCenter(newPos);
        if (shouldZoom) {
            googleMap.current.setZoom(17);
        }
        marker.current.setPosition(newPos);
    }

    // Call the parent component's callback
    onLocationChange({
      type: 'Point',
      coordinates: [newPos.lng, newPos.lat], // [longitude, latitude]
    });
  };

  return (
    <div className="location-picker-container md:col-span-2">
      <label className="block text-sm font-medium mb-1">Store Location</label>
      <p className="text-xs text-gray-500 mb-2">Search for an address or drag the pin to set the exact location.</p>

      <div className="relative">
        <input
          type="text"
          value={inputValue}
          onChange={handleInputChange}
          onFocus={() => setIsDropdownVisible(true)}
          onBlur={() => setTimeout(() => setIsDropdownVisible(false), 200)} // Delay to allow click on dropdown
          placeholder="Search for an address..."
          className="form-input"
          autoComplete="off"
        />
        {isDropdownVisible && predictions.length > 0 && (
          <div className="absolute z-10 w-full bg-white border border-gray-300 rounded-md mt-1 shadow-lg max-h-48 overflow-y-auto">
            {predictions.map(p => (
              <div
                key={p.place_id}
                className="px-4 py-2 cursor-pointer hover:bg-gray-100"
                onClick={() => handlePredictionClick(p.place_id)}
              >
                <p className="text-sm font-medium">{p.structured_formatting.main_text}</p>
                <p className="text-xs text-gray-500">{p.structured_formatting.secondary_text}</p>
              </div>
            ))}
          </div>
        )}
      </div>

      <div
        ref={mapRef}
        style={{ height: '300px', width: '100%', borderRadius: '8px', marginTop: '8px' }}
        className="bg-gray-200"
      >
        {/* The map will be rendered here */}
      </div>
    </div>
  );
}
