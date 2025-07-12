function LocationPicker({ location, onLocationChange }) {
  const { useState, useEffect, useRef } = React;

  // Refs for the map and search input elements
  const mapRef = useRef(null);
  const searchInputRef = useRef(null);

  // Refs for Google Maps objects to avoid re-creation on re-renders
  const googleMap = useRef(null);
  const marker = useRef(null);
  const autocomplete = useRef(null);

  // Default location (e.g., center of a country or a major city) if no location is set
  const defaultCenter = { lat: 40.7128, lng: -74.0060 }; // New York City

  const [currentLocation, setCurrentLocation] = useState(
    location && location.coordinates && location.coordinates[1] != null && location.coordinates[0] != null
      ? { lat: location.coordinates[1], lng: location.coordinates[0] }
      : defaultCenter
  );

  useEffect(() => {
    // Function to initialize the map
    const initMap = () => {
      // Check if the google object is available
      if (!window.google || !window.google.maps) {
        console.error("Google Maps script not loaded yet.");
        // Optionally, wait for the script to load. This assumes the callback `initMap` in index.html works.
        // A more robust solution might use a listener for a custom event fired by the global initMap.
        return;
      }

      // Create the map instance
      googleMap.current = new window.google.maps.Map(mapRef.current, {
        center: currentLocation,
        zoom: location ? 15 : 8,
        mapTypeControl: false,
        streetViewControl: false,
      });

      // Create the marker
      marker.current = new window.google.maps.Marker({
        position: currentLocation,
        map: googleMap.current,
        draggable: true,
        title: "Drag me to set the location!",
      });

      // Add listener for marker drag end
      marker.current.addListener('dragend', () => {
        const newPos = marker.current.getPosition();
        const newLocation = { lat: newPos.lat(), lng: newPos.lng() };
        setCurrentLocation(newLocation);
        onLocationChange({
          type: 'Point',
          coordinates: [newPos.lng(), newPos.lat()], // [longitude, latitude]
        });
      });

      // Initialize the Places Autocomplete search box
      autocomplete.current = new window.google.maps.places.Autocomplete(
        searchInputRef.current,
        {
          types: ['address'], // You can restrict to 'address', 'establishment', etc.
          fields: ['geometry.location', 'name', 'formatted_address'],
        }
      );

      // Add listener for when the user selects a place from the dropdown
      autocomplete.current.addListener('place_changed', () => {
        const place = autocomplete.current.getPlace();
        if (place.geometry && place.geometry.location) {
          const newPos = place.geometry.location;
          googleMap.current.setCenter(newPos);
          googleMap.current.setZoom(17);
          marker.current.setPosition(newPos);

          const newLocation = { lat: newPos.lat(), lng: newPos.lng() };
          setCurrentLocation(newLocation);
          onLocationChange({
            type: 'Point',
            coordinates: [newPos.lng(), newPos.lat()],
          });
        }
      });
    };

    // Check if the Google script has loaded, if not, wait.
    if (window.googleMapsScriptLoaded) {
      initMap();
    } else {
      // Fallback if component loads before script. A listener would be better.
      const interval = setInterval(() => {
        if (window.googleMapsScriptLoaded) {
          initMap();
          clearInterval(interval);
        }
      }, 100);
    }

  }, []); // Run this effect only once on mount

  // Effect to update marker position if the location prop changes from outside
  useEffect(() => {
    const newLocation = location && location.coordinates && location.coordinates[1] != null && location.coordinates[0] != null
      ? { lat: location.coordinates[1], lng: location.coordinates[0] }
      : null;

    if (newLocation && googleMap.current && marker.current) {
        if (newLocation.lat !== currentLocation.lat || newLocation.lng !== currentLocation.lng) {
            setCurrentLocation(newLocation);
            googleMap.current.setCenter(newLocation);
            marker.current.setPosition(newLocation);
        }
    }
  }, [location]);


  return (
    <div className="location-picker-container md:col-span-2">
      <label className="block text-sm font-medium mb-1">Store Location</label>
      <p className="text-xs text-gray-500 mb-2">Search for an address or drag the pin to set the exact location.</p>
      <input
        ref={searchInputRef}
        type="text"
        placeholder="Search for an address..."
        className="form-input mb-2"
      />
      <div
        ref={mapRef}
        style={{ height: '300px', width: '100%', borderRadius: '8px' }}
        className="bg-gray-200"
      >
        {/* The map will be rendered here */}
      </div>
    </div>
  );
}
