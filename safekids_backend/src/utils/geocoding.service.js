/**
 * Geocoding Service - Reverse Geocoding (coordinates to address)
 * Uses Nominatim (OpenStreetMap) - FREE, no API key needed!
 * 
 * Nominatim Usage Policy:
 * - Limit: 1 request per second per IP
 * - Free to use
 * - Caching highly recommended
 */

const https = require('https');

// Cache for reverse geocoding results (lat,lng -> address)
const geocodeCache = new Map();
const CACHE_TTL = 24 * 60 * 60 * 1000; // 24 hours
let lastRequestTime = 0;
const REQUEST_DELAY = 1100; // 1.1 second delay to respect rate limit

/**
 * Reverse geocode coordinates to address using Nominatim (FREE)
 */
exports.reverseGeocode = async (latitude, longitude) => {
  try {
    // Check cache first
    const cacheKey = `${latitude.toFixed(4)},${longitude.toFixed(4)}`;
    if (geocodeCache.has(cacheKey)) {
      const cached = geocodeCache.get(cacheKey);
      if (Date.now() - cached.timestamp < CACHE_TTL) {
        console.log(`🗺️ [Geocode] Cache hit: ${cacheKey} → ${cached.address}`);
        return cached.address;
      }
    }

    // Respect rate limit: 1 request per second
    const timeSinceLastRequest = Date.now() - lastRequestTime;
    if (timeSinceLastRequest < REQUEST_DELAY) {
      const waitTime = REQUEST_DELAY - timeSinceLastRequest;
      console.log(`⏳ [Geocode] Rate limit: waiting ${waitTime}ms`);
      await new Promise(resolve => setTimeout(resolve, waitTime));
    }

    // Use Nominatim (OpenStreetMap - FREE)
    try {
      const address = await reverseGeocodeNominatim(latitude, longitude);
      if (address) {
        geocodeCache.set(cacheKey, { address, timestamp: Date.now() });
        return address;
      }
    } catch (error) {
      console.warn('⚠️ [Geocode] Nominatim failed:', error.message);
    }

    // Fallback: return coordinates
    const fallback = `${latitude.toFixed(4)}, ${longitude.toFixed(4)}`;
    console.log(`🗺️ [Geocode] Using fallback coordinates: ${fallback}`);
    return fallback;

  } catch (error) {
    console.error('❌ [Geocode] Error:', error);
    return `${latitude.toFixed(4)}, ${longitude.toFixed(4)}`;
  }
};

/**
 * Reverse geocode using Nominatim (OpenStreetMap - FREE)
 * Vietnamese address format
 */
async function reverseGeocodeNominatim(latitude, longitude) {
  return new Promise((resolve, reject) => {
    const url = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}&language=vi&zoom=18&addressdetails=1`;

    lastRequestTime = Date.now();

    const request = https.get(url, {
      headers: {
        'User-Agent': 'SafeKids-App/1.0 (https://safekids.app)' // Required by Nominatim
      }
    }, (res) => {
      let data = '';
      
      res.on('data', chunk => {
        data += chunk;
      });
      
      res.on('end', () => {
        try {
          const result = JSON.parse(data);
          
          if (result.error) {
            reject(new Error(result.error.message));
            return;
          }
          
          if (result.address) {
            // Format address: [street] [ward] [district] [city]
            const parts = [];
            
            // Vietnam address components
            if (result.address.road) parts.push(result.address.road);
            if (result.address.neighbourhood) parts.push(result.address.neighbourhood);
            if (result.address.suburb) parts.push(result.address.suburb);
            if (result.address.district) parts.push(result.address.district);
            if (result.address.city) parts.push(result.address.city);
            if (result.address.town) parts.push(result.address.town);
            if (result.address.province) parts.push(result.address.province);

            const address = parts.length > 0 
              ? parts.slice(0, 3).join(', ')  // Max 3 parts to keep it short
              : result.address.display_name;
            
            console.log(`🗺️ [Geocode] Nominatim: ${address}`);
            resolve(address);
          } else {
            reject(new Error('No address found in response'));
          }
        } catch (error) {
          reject(new Error(`Parse error: ${error.message}`));
        }
      });
    });

    request.on('error', (error) => {
      reject(new Error(`Nominatim request failed: ${error.message}`));
    });

    // Timeout after 5 seconds
    request.setTimeout(5000, () => {
      request.destroy();
      reject(new Error('Nominatim request timeout'));
    });
  });
}

/**
 * Clear geocode cache
 */
exports.clearCache = () => {
  geocodeCache.clear();
  console.log('🗺️ [Geocode] Cache cleared');
};

/**
 * Get cache stats
 */
exports.getCacheStats = () => {
  return {
    size: geocodeCache.size,
    ttl: CACHE_TTL
  };
};
