const Geofence = require('../models/Geofence');
const GeofenceState = require('../models/GeofenceState');
const GeofenceAlert = require('../models/GeofenceAlert');
const User = require('../models/User');
const notificationService = require('./notification.service');
const { haversineDistance } = require('../utils/geolocation');
const { GeofenceMessages } = require('../constants/messages');
const geocodingService = require('../utils/geocoding.service');

// In-memory throttle cache (use Redis in production)
const alertThrottle = new Map();

// GPS accuracy buffer to prevent false alerts on boundary
const GPS_ACCURACY_BUFFER = 20; // 20 meters buffer for GPS inaccuracy

/**
 * Check if point is inside geofence with GPS accuracy buffer
 */
const isInsideGeofenceWithBuffer = (distance, radius) => {
  const effectiveRadius = radius + GPS_ACCURACY_BUFFER;
  return distance <= effectiveRadius;
};

/**
 * Check all geofences for a child on location update
 */
exports.checkGeofences = async (childId, latitude, longitude) => {
  try {
    console.log(`🔍 [Geofence] Checking geofences for child ${childId} at lat:${latitude}, lng:${longitude}`);
    
    // Get only ACTIVE geofences for this child (Story 3.3 requirement)
    const geofences = await Geofence.find({ 
      linkedChildren: childId,
      active: true // ← NEW: Only check active geofences
    });
    console.log(`🔍 [Geofence] Found ${geofences.length} geofences for child ${childId}`);

    for (const geofence of geofences) {
      console.log(`🔍 [Geofence] Processing geofence: ${geofence.name} (${geofence.type})`);
      
      // Calculate distance from location to geofence center
      const distance = haversineDistance(
        latitude,
        longitude,
        geofence.center.latitude,
        geofence.center.longitude
      ) * 1000; // Convert km to meters
      
      const isInside = isInsideGeofenceWithBuffer(distance, geofence.radius);
      console.log(`🔍 [Geofence] Distance: ${distance.toFixed(2)}m, Radius: ${geofence.radius}m (+${GPS_ACCURACY_BUFFER}m buffer), Inside: ${isInside}`);
      
      // Get previous state
      let state = await GeofenceState.findOne({ childId, geofenceId: geofence._id });
      if (!state) {
        state = new GeofenceState({ childId, geofenceId: geofence._id, isInside });
        await state.save();
        console.log(`🔍 [Geofence] First time checking geofence ${geofence.name} for child ${childId}`);
        continue; // First time, no alert
      }
      
      const wasInside = state.isInside;
      
      // Detect state change
      if (wasInside !== isInside) {
        const action = isInside ? 'enter' : 'exit';
        console.log(`🔍 [Geofence] State changed: ${wasInside} → ${isInside} (${action})`);
        
        // Determine if alert should be triggered
        const shouldAlert = (geofence.type === 'safe' && action === 'exit') ||
                            (geofence.type === 'danger' && action === 'enter');
        
        console.log(`🔍 [Geofence] Geofence type: ${geofence.type}, Action: ${action}, Should alert: ${shouldAlert}`);
        
        if (shouldAlert) {
          await triggerAlert(geofence, childId, action, { latitude, longitude });
        }
        
        // Update state
        state.isInside = isInside;
        state.lastCheck = new Date();
        await state.save();
        console.log(`🔍 [Geofence] Updated state for geofence ${geofence.name}`);
      }
    }
  } catch (error) {
    console.error('❌ [Geofence] Error checking geofences:', error);
  }
};

/**
 * Trigger geofence alert notification
 */
async function triggerAlert(geofence, childId, action, location) {
  try {
    // Check throttle
    const throttleKey = `${childId}-${geofence._id}`;
    const lastAlert = alertThrottle.get(throttleKey);
    const now = Date.now();
    
    if (lastAlert && (now - lastAlert) < 5 * 60 * 1000) {
      console.log('⏰ [Geofence] Alert throttled - too soon');
      return; // Skip - alerted in last 5 minutes
    }
    
    // Update throttle
    alertThrottle.set(throttleKey, now);
    console.log(`🔔 [Geofence] Triggering ${action} alert for geofence: ${geofence.name}`);
    
    // Get child and parents
    const child = await User.findById(childId);
    const parents = await User.find({ _id: { $in: child.linkedParents } });
    
    if (!child || !parents || parents.length === 0) {
      console.error('❌ [Geofence] Child or parents not found');
      return;
    }
    
    // Construct message using localization constants
    const message = GeofenceMessages.buildAlertMessage(child.fullName, action, geofence.name);
    console.log(`📱 [Geofence] Alert message: ${message}`);
    
    // Send FCM notifications
    let notifiedCount = 0;
    for (const parent of parents) {
      if (parent.fcmToken) {
        const success = await notificationService.sendNotification(
          parent.fcmToken,
          GeofenceMessages.NOTIFICATION_TITLE,
          message,
          {
            type: 'geofence',
            geofenceId: geofence._id.toString(),
            childId: childId.toString(),
            action
          }
        );
        if (success) notifiedCount++;
      }
    }
    console.log(`📱 [Geofence] Sent FCM notifications to ${notifiedCount}/${parents.length} parents`);
    
    // Emit Socket.io with reverse geocoded address
    const socketService = require('./socket.service');
    const parentIds = parents.map(p => p._id.toString());
    
    try {
      // Get address from coordinates
      const address = await geocodingService.reverseGeocode(location.latitude, location.longitude);
      
      const emitCount = socketService.emitGeofenceAlert(parentIds, {
        geofenceId: geofence._id,
        childId,
        childName: child.fullName,
        geofenceName: geofence.name,
        zoneType: geofence.type,  // 'safe' or 'danger'
        action,
        timestamp: new Date(),
        location: {
          latitude: location.latitude,
          longitude: location.longitude,
          address: address
        }
      });
      console.log(`🔌 [Geofence] Emitted Socket.io alerts to ${emitCount}/${parentIds.length} connected parents (${address})`);
    } catch (socketError) {
      console.warn('⚠️ [Geofence] Socket.io emit failed:', socketError.message);
    }
    
    // Save alert log
    const alert = new GeofenceAlert({
      geofenceId: geofence._id,
      childId,
      action,
      location,
      timestamp: new Date(),
      notified: notifiedCount > 0
    });
    await alert.save();
    console.log(`💾 [Geofence] Alert logged to database (notified: ${notifiedCount > 0})`);
    
  } catch (error) {
    console.error('❌ [Geofence] Error triggering alert:', error);
  }
}
