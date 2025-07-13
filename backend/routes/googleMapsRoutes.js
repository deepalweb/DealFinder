const express = require('express');
const router = express.Router();
const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));

// IMPORTANT: For production, use an environment variable.
// The key is temporarily hardcoded here for development and debugging.
// You MUST set GOOGLE_MAPS_API_KEY in your Azure environment variables.
const API_KEY = process.env.GOOGLE_MAPS_API_KEY || "AIzaSyD8G22_65M5eM6l0oOHDstdzDZYu6rkmJQ";

if (!process.env.GOOGLE_MAPS_API_KEY) {
  console.warn("WARNING: GOOGLE_MAPS_API_KEY environment variable is not set. Using a hardcoded key for development. This is not secure for production.");
}

// Proxy for Place Autocomplete API
router.get('/autocomplete', async (req, res) => {
  const { input } = req.query;
  if (!API_KEY) {
    return res.status(500).json({ message: "Google Maps API key is not configured on the server." });
  }
  if (!input) {
    return res.status(400).json({ message: "Input query parameter is required." });
  }

  // Note: The new Autocomplete API is part of Places API (New) but is still accessible via a standard endpoint.
  // The URL structure is slightly different for the new text search vs legacy.
  // We'll use the standard, widely supported autocomplete endpoint which should work with the enabled "Places API".
  const url = `https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${encodeURIComponent(input)}&key=${API_KEY}&types=address`;

  try {
    const response = await fetch(url);
    const data = await response.json();
    res.json(data);
  } catch (error) {
    console.error("Error proxying Google Places Autocomplete request:", error);
    res.status(500).json({ message: 'Failed to fetch data from Google Maps API.' });
  }
});

// Proxy for Place Details API
router.get('/place-details', async (req, res) => {
  const { place_id } = req.query;
  if (!API_KEY) {
    return res.status(500).json({ message: "Google Maps API key is not configured on the server." });
  }
  if (!place_id) {
    return res.status(400).json({ message: "place_id query parameter is required." });
  }

  const url = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${encodeURIComponent(place_id)}&fields=geometry,name,formatted_address&key=${API_KEY}`;

  try {
    const response = await fetch(url);
    const data = await response.json();
    res.json(data);
  } catch (error) {
    console.error("Error proxying Google Place Details request:", error);
    res.status(500).json({ message: 'Failed to fetch data from Google Maps API.' });
  }
});

// Endpoint to provide the API key to the frontend
router.get('/get-key', (req, res) => {
  if (!API_KEY) {
    return res.status(500).json({ message: "Google Maps API key is not configured on the server." });
  }
  res.json({ apiKey: API_KEY });
});

module.exports = router;
