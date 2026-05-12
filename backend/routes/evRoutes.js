const express = require('express');
const router = express.Router();

// ✅ FIX: Use dynamic import for node-fetch to bypass the CommonJS/ESM restriction
const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));

const cache = new Map();
const CACHE_DURATION = 60 * 60 * 1000; // 1 hour

router.get('/nearby', async (req, res) => {
  const { lat, lon, radius = 20 } = req.query; // Radius in km

  // Validate inputs
  if (!lat || !lon) {
    return res.status(400).json({ message: 'Latitude and longitude are required.' });
  }

  // Log API key for debugging
  if (!process.env.OPEN_CHARGE_MAP_KEY) {
    console.error('OPEN_CHARGE_MAP_KEY is not set in environment variables');
    return res.status(500).json({ message: 'Server configuration error: API key missing' });
  }
  console.log('OpenChargeMap API Key:', process.env.OPEN_CHARGE_MAP_KEY);

  const cacheKey = `${lat}:${lon}:${radius}`;
  if (cache.has(cacheKey)) {
    const cached = cache.get(cacheKey);
    if (Date.now() - cached.timestamp < CACHE_DURATION) {
      console.log('Serving from cache:', cacheKey);
      return res.json(cached.stations);
    }
  }

  try {
    const url = `https://api.openchargemap.io/v3/poi?key=${process.env.OPEN_CHARGE_MAP_KEY}&latitude=${lat}&longitude=${lon}&distance=${radius}&distance_unit=km&maxresults=50&countrycode=IN&output=json`;
    console.log('Fetching from OpenChargeMap:', url);

    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
      },
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(`OpenChargeMap API error: Status ${response.status}, ${errorText}`);
      if (response.status === 401) {
        return res.status(500).json({ message: 'Invalid OpenChargeMap API key' });
      }
      if (response.status === 429) {
        return res.status(429).json({ message: 'Rate limit exceeded for OpenChargeMap API' });
      }
      throw new Error(`API request failed with status ${response.status}: ${errorText}`);
    }

    const data = await response.json();
    console.log('Received stations:', data.length);

    // Format to match frontend expectation (AddressInfo object)
    const stations = data.map((poi) => ({
      AddressInfo: {
        Title: poi.AddressInfo?.Title || 'Unknown Station',
        AddressLine1: poi.AddressInfo?.AddressLine1 || 'Unknown Address',
        Latitude: poi.AddressInfo?.Latitude || 0,
        Longitude: poi.AddressInfo?.Longitude || 0,
      },
    }));

    cache.set(cacheKey, { stations, timestamp: Date.now() });
    res.json(stations);
  } catch (error) {
    console.error('Error fetching EV stations:', {
      message: error.message,
      stack: error.stack,
      url: `https://api.openchargemap.io/v3/poi?key=[HIDDEN]&latitude=${lat}&longitude=${lon}&distance=${radius}&distance_unit=km&maxresults=50&countrycode=IN&output=json`,
    });
    res.status(500).json({ message: 'Failed to fetch EV stations', error: error.message });
  }
});

module.exports = router;