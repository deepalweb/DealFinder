// This utility handles dynamic loading of the Google Maps script.
(function(window) {
  let googleMapsPromise = null;

  function loadGoogleMaps() {
    // If the promise already exists, return it to avoid reloading
    if (googleMapsPromise) {
      return googleMapsPromise;
    }

    // Create a new promise that will resolve when the script is loaded
    googleMapsPromise = new Promise((resolve, reject) => {
      // Check if the script has already been loaded by some other means
      if (window.google && window.google.maps) {
        console.log("Google Maps script already loaded.");
        resolve(window.google);
        return;
      }

      // Define the callback BEFORE fetching the key so it's always available
      window.initMap = () => {
        console.log("Google Maps script loaded successfully.");
        resolve(window.google);
        delete window.initMap;
      };

      // Fetch the API key from our backend proxy
      window.API.Maps.getKey()
        .then(data => {
          if (!data.apiKey) {
            throw new Error("API key not received from server.");
          }

          const script = document.createElement('script');
          script.src = `https://maps.googleapis.com/maps/api/js?key=${data.apiKey}&libraries=places&callback=initMap`;
          script.async = true;
          script.defer = true;
          script.onerror = (error) => {
            console.error("Failed to load Google Maps script.", error);
            reject(new Error("Failed to load Google Maps script."));
            document.head.removeChild(script);
            delete window.initMap;
          };

          document.head.appendChild(script);
        })
        .catch(err => {
          console.error("Failed to fetch Google Maps API key:", err);
          delete window.initMap;
          reject(err);
        });
    });

    return googleMapsPromise;
  }

  // Expose the loader function on the window object
  window.loadGoogleMaps = loadGoogleMaps;

})(window);
