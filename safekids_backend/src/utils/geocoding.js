const axios = require('axios');

const NOMINATIM_URL = 'https://nominatim.openstreetmap.org/reverse';
const CACHE = {}; // Simple in-memory cache

/**
 * Reverse geocode coordinates to location name using Nominatim
 * @param {number} latitude
 * @param {number} longitude
 * @returns {Promise<string>} Location name or fallback
 */
const getLocationName = async (latitude, longitude) => {
  const cacheKey = `${latitude.toFixed(4)},${longitude.toFixed(4)}`;

  // Check cache first
  if (CACHE[cacheKey]) {
    return CACHE[cacheKey];
  }

  try {
    // Call Nominatim API
    const response = await axios.get(NOMINATIM_URL, {
      params: {
        lat: latitude,
        lon: longitude,
        format: 'json',
        addressdetails: 1,
        zoom: 18,
        language: 'vi',
      },
      headers: {
        'User-Agent': 'SafeKids-App/1.0',
      },
      timeout: 5000, // 5 second timeout
    });

    if (!response.data || !response.data.address) {
      return `Địa điểm thường xuyên`;
    }

    const address = response.data.address;

    // Try to build meaningful name from address parts
    let locationName =
      address.building ||
      address.amenity ||
      address.shop ||
      address.office ||
      address.school ||
      address.university ||
      address.leisure ||
      address.suburb ||
      address.village ||
      address.town ||
      address.city ||
      'Địa điểm không xác định';

    // Cache the result
    CACHE[cacheKey] = locationName;

    return locationName;
  } catch (error) {
    console.warn(`[Geocoding] Error for (${latitude}, ${longitude}):`, error.message);
    
    // Return generic fallback on error
    return `Địa điểm thường xuyên`;
  }
};

/**
 * Clear geocoding cache (useful for testing)
 */
const clearGeocachingCache = () => {
  Object.keys(CACHE).forEach(key => delete CACHE[key]);
};

module.exports = {
  getLocationName,
  clearGeocachingCache,
};
