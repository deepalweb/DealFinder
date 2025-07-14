// NearbyDealsPage component for showing location-based deals
const NearbyDealsPage = () => {
  const { useState, useEffect } = React;

  const [promotions, setPromotions] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [userLocation, setUserLocation] = useState(null);
  const [radius, setRadius] = useState(10); // Default 10km radius
  const [locationPermission, setLocationPermission] = useState('prompt');

  useEffect(() => {
    checkLocationPermission();
  }, []);

  const checkLocationPermission = () => {
    if ('geolocation' in navigator) {
      navigator.permissions.query({ name: 'geolocation' }).then((result) => {
        setLocationPermission(result.state);
        if (result.state === 'granted') {
          getCurrentLocationAndFetchDeals();
        }
      }).catch(() => {
        // Fallback for browsers that don't support permissions API
        setLocationPermission('prompt');
      });
    } else {
      setError('Geolocation is not supported by this browser.');
    }
  };

  const getCurrentLocationAndFetchDeals = () => {
    setLoading(true);
    setError('');

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const location = {
          latitude: position.coords.latitude,
          longitude: position.coords.longitude
        };
        setUserLocation(location);
        fetchNearbyDeals(location);
      },
      (error) => {
        setLoading(false);
        switch (error.code) {
          case error.PERMISSION_DENIED:
            setError(
              <div>
                <strong>Location access denied.</strong><br/>
                <small>Click the 🔒 lock icon in your address bar and allow location access, then refresh the page.</small>
              </div>
            );
            break;
          case error.POSITION_UNAVAILABLE:
            setError('Location information is unavailable.');
            break;
          case error.TIMEOUT:
            setError('Location request timed out.');
            break;
          default:
            setError('An unknown error occurred while retrieving location.');
            break;
        }
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 300000 // 5 minutes
      }
    );
  };

  const fetchNearbyDeals = async (location) => {
    try {
      const response = await fetch(
        `/api/promotions/nearby?latitude=${location.latitude}&longitude=${location.longitude}&radius=${radius}`
      );
      
      if (!response.ok) {
        throw new Error('Failed to fetch nearby deals');
      }
      
      const data = await response.json();
      setPromotions(data);
    } catch (err) {
      setError('Failed to load nearby deals. Please try again.');
      console.error('Error fetching nearby deals:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleRadiusChange = (newRadius) => {
    setRadius(newRadius);
    if (userLocation) {
      setLoading(true);
      fetchNearbyDeals(userLocation);
    }
  };

  const formatDistance = (distanceInMeters) => {
    if (distanceInMeters < 1000) {
      return `${Math.round(distanceInMeters)}m`;
    } else {
      return `${(distanceInMeters / 1000).toFixed(1)}km`;
    }
  };

  const containerStyle = {
    maxWidth: '1200px',
    margin: '0 auto',
    padding: '20px'
  };

  const headerStyle = {
    textAlign: 'center',
    marginBottom: '30px'
  };

  const titleStyle = {
    fontSize: '2.5rem',
    fontWeight: 'bold',
    color: '#333',
    marginBottom: '10px'
  };

  const subtitleStyle = {
    fontSize: '1.1rem',
    color: '#666',
    marginBottom: '20px'
  };

  const controlsStyle = {
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    gap: '20px',
    marginBottom: '30px',
    flexWrap: 'wrap'
  };

  const buttonStyle = {
    padding: '12px 24px',
    backgroundColor: '#007bff',
    color: 'white',
    border: 'none',
    borderRadius: '6px',
    cursor: 'pointer',
    fontSize: '16px',
    fontWeight: '500',
    transition: 'background-color 0.2s'
  };

  const radiusSelectStyle = {
    padding: '8px 12px',
    border: '1px solid #ccc',
    borderRadius: '4px',
    fontSize: '14px'
  };

  const errorStyle = {
    backgroundColor: '#f8d7da',
    color: '#721c24',
    padding: '15px',
    borderRadius: '6px',
    marginBottom: '20px',
    textAlign: 'center'
  };

  const loadingStyle = {
    textAlign: 'center',
    padding: '40px',
    fontSize: '18px',
    color: '#666'
  };

  const noDealsStyle = {
    textAlign: 'center',
    padding: '40px',
    color: '#666'
  };

  const dealsGridStyle = {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))',
    gap: '20px',
    marginTop: '20px'
  };

  const dealCardStyle = {
    border: '1px solid #e0e0e0',
    borderRadius: '8px',
    overflow: 'hidden',
    backgroundColor: 'white',
    boxShadow: '0 2px 4px rgba(0,0,0,0.1)',
    transition: 'transform 0.2s, box-shadow 0.2s'
  };

  const distanceBadgeStyle = {
    position: 'absolute',
    top: '10px',
    right: '10px',
    backgroundColor: '#28a745',
    color: 'white',
    padding: '4px 8px',
    borderRadius: '12px',
    fontSize: '12px',
    fontWeight: 'bold'
  };

  return (
    React.createElement('div', { style: containerStyle },
      React.createElement('div', { style: headerStyle },
        React.createElement('h1', { style: titleStyle }, '📍 Nearby Deals'),
        React.createElement('p', { style: subtitleStyle }, 
          'Discover amazing deals and promotions near your location'
        )
      ),

      React.createElement('div', { style: controlsStyle },
        React.createElement('button', {
          onClick: getCurrentLocationAndFetchDeals,
          style: buttonStyle,
          disabled: loading
        }, loading ? '🔄 Loading...' : '📍 Find Nearby Deals'),
        
        React.createElement('div', { style: { display: 'flex', alignItems: 'center', gap: '8px' } },
          React.createElement('label', { htmlFor: 'radius', style: { fontSize: '14px', color: '#666' } }, 'Radius:'),
          React.createElement('select', {
            id: 'radius',
            value: radius,
            onChange: (e) => handleRadiusChange(parseInt(e.target.value)),
            style: radiusSelectStyle
          },
            React.createElement('option', { value: 5 }, '5 km'),
            React.createElement('option', { value: 10 }, '10 km'),
            React.createElement('option', { value: 20 }, '20 km'),
            React.createElement('option', { value: 50 }, '50 km')
          )
        )
      ),

      error && React.createElement('div', { style: errorStyle }, error),

      loading && React.createElement('div', { style: loadingStyle }, 
        '🔄 Finding deals near you...'
      ),

      !loading && !error && promotions.length === 0 && userLocation && 
      React.createElement('div', { style: noDealsStyle },
        React.createElement('h3', null, '😔 No deals found nearby'),
        React.createElement('p', null, 'Try increasing the search radius or check back later for new deals.')
      ),

      !loading && promotions.length > 0 && 
      React.createElement('div', null,
        React.createElement('h2', { 
          style: { 
            textAlign: 'center', 
            marginBottom: '20px', 
            color: '#333',
            fontSize: '1.5rem'
          } 
        }, `Found ${promotions.length} deals within ${radius}km`),
        
        React.createElement('div', { style: dealsGridStyle },
          promotions.map(promotion => 
            React.createElement('div', { 
              key: promotion._id, 
              style: { 
                ...dealCardStyle,
                position: 'relative'
              }
            },
              promotion.merchant && promotion.merchant.distance && 
              React.createElement('div', { style: distanceBadgeStyle },
                formatDistance(promotion.merchant.distance)
              ),
              React.createElement(PromotionCard, { 
                promotion: promotion,
                showMerchantInfo: true
              })
            )
          )
        )
      ),

      !userLocation && !loading && !error &&
      React.createElement('div', { style: noDealsStyle },
        React.createElement('h3', null, '📍 Location Required'),
        React.createElement('p', null, 'Click "Find Nearby Deals" to discover promotions in your area.'),
        React.createElement('p', { style: { fontSize: '14px', color: '#888', marginTop: '10px' } },
          'We need your location to show you relevant deals nearby.'
        )
      )
    )
  );
};

window.NearbyDealsPage = NearbyDealsPage;