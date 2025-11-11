const Location = require('../models/Location');
const { haversineDistance } = require('../utils/geolocation');
const { getLocationName } = require('../utils/geocoding');

const CLUSTER_RADIUS_METERS = 100;
const MIN_VISITS_THRESHOLD = 3;
const MAX_SUGGESTIONS = 5;
const MIN_SUGGESTED_RADIUS = 100;
const MAX_SUGGESTED_RADIUS = 500;
const RADIUS_BUFFER = 50;

/**
 * Find frequent locations by clustering GPS points
 * @param {string} childId - Child user ID
 * @param {number} days - Number of days to analyze (default 30)
 * @returns {Promise<Array>} Array of location clusters with visit counts
 */
const findFrequentLocations = async (childId, days = 30) => {
  try {
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    // Get all locations for child in last X days
    const locations = await Location.find({
      userId: childId,
      timestamp: { $gte: startDate }
    }).sort({ timestamp: 1 });

    console.log(`[findFrequentLocations] childId: ${childId}, found ${locations.length} locations in last ${days} days`);

    if (locations.length < MIN_VISITS_THRESHOLD) {
      console.log(`[findFrequentLocations] Not enough locations (need ${MIN_VISITS_THRESHOLD}, got ${locations.length})`);
      return [];
    }

    // Simple clustering: group locations within 100m
    const clusters = [];

    for (const loc of locations) {
      let addedToCluster = false;

      // Check if near existing cluster
      for (const cluster of clusters) {
        const distanceKm = haversineDistance(
          loc.latitude,
          loc.longitude,
          cluster.center.latitude,
          cluster.center.longitude
        );
        const distanceMeters = distanceKm * 1000;

        if (distanceMeters <= CLUSTER_RADIUS_METERS) {
          // Add to cluster
          cluster.locations.push(loc);
          
          // Count unique days (Vietnam timezone UTC+7)
          const uniqueDays = new Set(
            cluster.locations.map(l => {
              const date = new Date(l.timestamp);
              // Convert to Vietnam time (UTC+7)
              const vietnamTime = new Date(date.getTime() + 7 * 60 * 60 * 1000);
              const year = vietnamTime.getUTCFullYear();
              const month = String(vietnamTime.getUTCMonth() + 1).padStart(2, '0');
              const day = String(vietnamTime.getUTCDate()).padStart(2, '0');
              return `${year}-${month}-${day}`;
            })
          );
          cluster.visitCount = uniqueDays.size;

          // Update cluster center (average)
          const totalLat = cluster.locations.reduce((sum, l) => sum + l.latitude, 0);
          const totalLng = cluster.locations.reduce((sum, l) => sum + l.longitude, 0);
          cluster.center.latitude = totalLat / cluster.locations.length;
          cluster.center.longitude = totalLng / cluster.locations.length;

          addedToCluster = true;
          break;
        }
      }

      // Create new cluster
      if (!addedToCluster) {
        clusters.push({
          center: {
            latitude: loc.latitude,
            longitude: loc.longitude
          },
          visitCount: 1,
          locations: [loc]
        });
      }
    }

    // Filter: only clusters with 3+ visits
    console.log(`[findFrequentLocations] Total clusters before filtering: ${clusters.length}`);
    clusters.forEach((c, i) => {
      console.log(`  Cluster ${i}: visitCount=${c.visitCount}, locations=${c.locations.length}`);
    });
    
    const frequentClusters = clusters.filter(c => c.visitCount >= MIN_VISITS_THRESHOLD);
    console.log(`[findFrequentLocations] Frequent clusters (>=${MIN_VISITS_THRESHOLD} visits): ${frequentClusters.length}`);

    // Calculate suggested radius for each cluster (max distance from center)
    frequentClusters.forEach(cluster => {
      let maxDistance = 0;
      for (const loc of cluster.locations) {
        const distanceKm = haversineDistance(
          loc.latitude,
          loc.longitude,
          cluster.center.latitude,
          cluster.center.longitude
        );
        const distanceMeters = distanceKm * 1000;
        if (distanceMeters > maxDistance) {
          maxDistance = distanceMeters;
        }
      }
      // Suggested radius = max distance + buffer, clamped between min and max
      cluster.suggestedRadius = Math.min(
        Math.max(maxDistance + RADIUS_BUFFER, MIN_SUGGESTED_RADIUS),
        MAX_SUGGESTED_RADIUS
      );
    });

    // Sort by visit count DESC, return top 5
    frequentClusters.sort((a, b) => b.visitCount - a.visitCount);
    const topClusters = frequentClusters.slice(0, MAX_SUGGESTIONS);

    // Get location names via reverse geocoding
    const clustersWithNames = await Promise.all(
      topClusters.map(async (cluster) => {
        const locationName = await getLocationName(
          cluster.center.latitude,
          cluster.center.longitude
        );
        return {
          ...cluster,
          locationName,
        };
      })
    );

    return clustersWithNames;
  } catch (error) {
    console.error('❌ [Location Clustering] Error:', error);
    throw error;
  }
};

module.exports = {
  findFrequentLocations
};
