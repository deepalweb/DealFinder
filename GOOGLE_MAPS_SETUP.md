# Google Maps Integration Setup Guide

This guide explains how to set up Google Maps API integration for location-based features in DealFinder.

## Features Added

1. **Location Picker for Merchants**: Merchants can set their business location using an interactive map
2. **Nearby Deals Page**: Users can find deals near their current location
3. **Distance Display**: Shows distance from user to merchant locations
4. **Address Autocomplete**: Search and select locations easily

## Setup Instructions

### 1. Get Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - Maps JavaScript API
   - Places API
   - Geocoding API
4. Create credentials (API Key)
5. Restrict the API key to your domain for security

### 2. Configure Environment Variables

1. Copy the example environment file:
   ```bash
   cp backend/.env.example backend/.env
   ```

2. Add your Google Maps API key to `backend/.env`:
   ```
   GOOGLE_MAPS_API_KEY=your_actual_api_key_here
   ```

### 3. API Key Security (Important!)

For production, restrict your API key:

1. In Google Cloud Console, go to Credentials
2. Click on your API key
3. Under "Application restrictions":
   - Select "HTTP referrers (web sites)"
   - Add your domain: `https://yourdomain.com/*`
4. Under "API restrictions":
   - Select "Restrict key"
   - Choose: Maps JavaScript API, Places API, Geocoding API

## How It Works

### Backend Changes

1. **Merchant Model**: Already includes GeoJSON location field
2. **Promotion Routes**: `/api/promotions/nearby` endpoint for location-based queries
3. **Config Endpoint**: `/api/config` serves API key to frontend securely

### Frontend Changes

1. **LocationPicker Component**: Interactive map for selecting locations
2. **NearbyDealsPage**: Shows deals based on user's location
3. **Updated MerchantForm**: Includes location selection
4. **Navigation**: Added "Nearby" link to header

## Usage

### For Merchants (Admin Panel)

1. Go to Admin → Merchants
2. Create or edit a merchant
3. Use the location picker to set the business location
4. The map allows:
   - Clicking to place a marker
   - Searching for addresses
   - Using current location
   - Dragging markers to adjust position

### For Users

1. Click "Nearby" in the navigation
2. Allow location access when prompted
3. View deals sorted by distance
4. Adjust search radius (5km, 10km, 20km, 50km)

## Database

The merchant location is stored as GeoJSON:
```javascript
location: {
  type: 'Point',
  coordinates: [longitude, latitude]
}
```

MongoDB's geospatial queries are used for efficient nearby searches.

## API Endpoints

- `GET /api/config` - Returns Google Maps API key
- `GET /api/promotions/nearby?latitude=X&longitude=Y&radius=Z` - Get nearby deals
- `POST /api/merchants` - Create merchant with location
- `PUT /api/merchants/:id` - Update merchant location

## Troubleshooting

### Common Issues

1. **Maps not loading**: Check API key in browser console
2. **Location access denied**: Users need to allow location permissions
3. **No nearby deals**: Ensure merchants have locations set
4. **API quota exceeded**: Monitor usage in Google Cloud Console

### Error Messages

- "Google Maps API key not configured" - Add key to .env file
- "Location access denied" - User needs to enable location services
- "Failed to load nearby deals" - Check backend API and database

## Cost Considerations

Google Maps API has usage limits and costs:
- Maps JavaScript API: $7 per 1,000 loads
- Places API: $17 per 1,000 requests
- Geocoding API: $5 per 1,000 requests

Monitor usage in Google Cloud Console and set up billing alerts.

## Security Best Practices

1. **Restrict API Key**: Limit to your domain only
2. **Environment Variables**: Never commit API keys to version control
3. **Rate Limiting**: Consider implementing rate limiting for API calls
4. **HTTPS Only**: Use HTTPS in production for secure API calls

## Testing

1. Test with different locations
2. Verify distance calculations
3. Check mobile responsiveness
4. Test with location services disabled
5. Verify API key restrictions work

## Future Enhancements

Possible improvements:
1. **Route Planning**: Directions to merchant locations
2. **Geofencing**: Notifications when near deals
3. **Location History**: Remember user's frequent locations
4. **Merchant Clustering**: Group nearby merchants on map
5. **Real-time Updates**: Live location tracking for delivery deals