const Location = require('../models/Location');
const User = require('../models/User');
const { haversineDistance } = require('../utils/geolocation');
const { checkGeofences } = require('../services/geofence-detection.service');

/**
 * @route   POST /api/location
 * @desc    Create location update (child only)
 * @access  Private
 */
exports.createLocation = async (req, res) => {
  try {
    console.log('📍 [Location POST] Request received from user:', req.userId);
    console.log('📍 [Location POST] Body:', req.body);
    
    const userId = req.userId;
    const { latitude, longitude, accuracy, timestamp } = req.body;

    // Validate required fields
    if (latitude == null || longitude == null) {
      console.log('❌ [Location POST] Missing lat/lng');
      return res.status(400).json({ error: 'Latitude và longitude là bắt buộc' });
    }

    // Get user and verify role
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: 'Người dùng không tồn tại' });
    }

    // Only children can post locations
    if (user.role !== 'child') {
      return res.status(403).json({ error: 'Chỉ tài khoản trẻ em mới có thể gửi vị trí' });
    }

    // Ensure locationSettings exists with defaults
    if (!user.locationSettings) {
      user.locationSettings = {
        sharingEnabled: true,
        trackingInterval: 'continuous',
        pausedUntil: null
      };
      await user.save();
    }

    // Task 2.5.3: Check pause status FIRST (highest priority)
    if (user.locationSettings.pausedUntil && user.locationSettings.pausedUntil > new Date()) {
      console.log('⏸️ [Location POST] Location sharing is paused until:', user.locationSettings.pausedUntil);
      return res.status(403).json({ 
        error: 'Chia sẻ vị trí đang bị tạm dừng',
        pausedUntil: user.locationSettings.pausedUntil
      });
    }

    // Task 2.5.3: Auto-resume if pause expired
    if (user.locationSettings.pausedUntil && user.locationSettings.pausedUntil <= new Date()) {
      console.log('✅ [Location POST] Pause expired, auto-resuming tracking for user:', userId);
      user.locationSettings.pausedUntil = null;
      await user.save();
    }

    // Task 2.5.1: Check location sharing status (after pause check)
    if (!user.locationSettings.sharingEnabled) {
      console.log('❌ [Location POST] Location sharing is disabled for user:', userId);
      return res.status(403).json({ error: 'Chia sẻ vị trí đã bị tắt' });
    }

    // Create location with optional battery level (Task 2.6.6)
    const location = new Location({
      userId,
      latitude,
      longitude,
      accuracy: accuracy || 0,
      batteryLevel: req.body.batteryLevel || null,
      timestamp: timestamp ? new Date(timestamp) : new Date()
    });

    await location.save();
    console.log('✅ [Location POST] Saved to DB:', location._id);

    // Check geofences (Story 3.2)
    try {
      await checkGeofences(userId, latitude, longitude);
      console.log('✅ [Location POST] Geofence check completed');
    } catch (geofenceError) {
      console.warn('⚠️ [Location POST] Geofence check failed:', geofenceError.message);
      // Continue processing even if geofence check fails
    }

    // Emit Socket.io event
    const socketService = req.app.get('socketService');
    if (socketService) {
      socketService.emitLocationUpdate({
        userId: userId.toString(),
        latitude,
        longitude,
        accuracy: location.accuracy,
        timestamp: location.timestamp
      });
      console.log('✅ [Location POST] Socket.io event emitted');
    }

    res.status(201).json({
      success: true,
      data: { location }
    });
    console.log('✅ [Location POST] Response sent');

  } catch (error) {
    console.error('❌ [Location POST] Error:', error);
    res.status(500).json({ error: 'Không thể lưu vị trí' });
  }
};

/**
 * @route   GET /api/location/:userId
 * @desc    Get location history for a user
 * @access  Private
 */
exports.getLocations = async (req, res) => {
  try {
    const { userId } = req.params;
    const limit = parseInt(req.query.limit) || 100;

    const locations = await Location.find({ userId })
      .sort({ timestamp: -1 })
      .limit(limit);

    res.json({ success: true, data: { locations } });

  } catch (error) {
    console.error('Get locations error:', error);
    res.status(500).json({ error: 'Không thể lấy lịch sử vị trí' });
  }
};

/**
 * @route   GET /api/location/child/:childId/latest
 * @desc    Get latest location for a child (parent only, must be linked)
 * @access  Private
 */
exports.getLatestLocation = async (req, res) => {
  try {
    const parentId = req.userId;
    const { childId } = req.params;

    // Verify parent is logged in
    const parent = await User.findById(parentId);
    if (!parent) {
      return res.status(404).json({ error: 'Người dùng không tồn tại' });
    }

    // Only parents can access this endpoint
    if (parent.role !== 'parent') {
      return res.status(403).json({ error: 'Chỉ phụ huynh mới có thể xem vị trí con' });
    }

    // Verify child exists
    const child = await User.findById(childId);
    if (!child || child.role !== 'child') {
      return res.status(404).json({ error: 'Không tìm thấy tài khoản trẻ em' });
    }

    // Verify parent is linked to this child
    const isLinked = parent.linkedChildren.some(
      linkedChildId => linkedChildId.toString() === childId
    );

    if (!isLinked) {
      return res.status(403).json({ 
        error: 'Bạn không có quyền xem vị trí của trẻ này' 
      });
    }

    // Get latest location
    const location = await Location.findOne({ userId: childId })
      .sort({ timestamp: -1 })
      .limit(1);

    if (!location) {
      return res.status(404).json({ 
        error: 'Chưa có dữ liệu vị trí',
        success: false 
      });
    }

    res.json({ 
      success: true, 
      data: { 
        location: {
          ...location.toObject(),
          batteryLevel: location.batteryLevel
        },
        childName: child.fullName || child.name,
        childId: child._id,
        batteryLevel: location.batteryLevel
      } 
    });

  } catch (error) {
    console.error('Get latest location error:', error);
    res.status(500).json({ error: 'Không thể lấy vị trí' });
  }
};

/**
 * @route   GET /api/location/my-children
 * @desc    Get latest locations for all linked children (optimization)
 * @access  Private (Parent only)
 */
exports.getAllChildrenLocations = async (req, res) => {
  try {
    const parentId = req.userId;

    // Verify parent is logged in
    const parent = await User.findById(parentId).populate('linkedChildren', 'fullName name');
    if (!parent) {
      return res.status(404).json({ error: 'Người dùng không tồn tại' });
    }

    // Only parents can access this endpoint
    if (parent.role !== 'parent') {
      return res.status(403).json({ error: 'Chỉ phụ huynh mới có thể xem vị trí con' });
    }

    const childIds = parent.linkedChildren.map(c => c._id);
    
    if (childIds.length === 0) {
      return res.json({ success: true, data: [] });
    }

    // Aggregate to get latest location for each child
    const locations = await Location.aggregate([
      { $match: { userId: { $in: childIds } } },
      { $sort: { timestamp: -1 } },
      { $group: {
        _id: '$userId',
        latitude: { $first: '$latitude' },
        longitude: { $first: '$longitude' },
        accuracy: { $first: '$accuracy' },
        timestamp: { $first: '$timestamp' },
        batteryLevel: { $first: '$batteryLevel' }
      }}
    ]);

    // Merge with child names
    const data = locations.map(loc => {
      const child = parent.linkedChildren.find(c => c._id.toString() === loc._id.toString());
      return {
        childId: loc._id,
        childName: child?.fullName || child?.name || 'Unknown',
        latitude: loc.latitude,
        longitude: loc.longitude,
        accuracy: loc.accuracy,
        timestamp: loc.timestamp,
        batteryLevel: loc.batteryLevel
      };
    });

    res.json({ success: true, data });

  } catch (error) {
    console.error('Get all children locations error:', error);
    res.status(500).json({ error: 'Không thể lấy vị trí các con' });
  }
};

/**
 * @route   GET /api/location/child/:childId/history
 * @desc    Get location history for a specific child
 * @access  Private (Parent only)
 */
exports.getLocationHistory = async (req, res) => {
  try {
    const parentId = req.userId;
    const { childId } = req.params;
    const { startDate, endDate, limit = 100 } = req.query;

    // Verify parent-child link
    const parent = await User.findById(parentId);
    if (!parent || !parent.linkedChildren.some(id => id.toString() === childId)) {
      return res.status(403).json({ error: 'Bạn không có quyền xem lịch sử vị trí của trẻ này' });
    }

    // Default date range: last 24 hours
    const start = startDate ? new Date(startDate) : new Date(Date.now() - 24 * 60 * 60 * 1000);
    const end = endDate ? new Date(endDate) : new Date();

    const locations = await Location.find({
      userId: childId,
      timestamp: { $gte: start, $lte: end }
    })
    .sort({ timestamp: -1 })
    .limit(Math.min(parseInt(limit) || 100, 1000));

    res.json({ success: true, data: { locations, count: locations.length } });
  } catch (error) {
    console.error('Get location history error:', error);
    res.status(500).json({ error: 'Không thể lấy lịch sử vị trí' });
  }
};

/**
 * @route   GET /api/location/child/:childId/stats
 * @desc    Get location statistics for a specific child
 * @access  Private (Parent only)
 */
exports.getLocationStats = async (req, res) => {
  try {
    const parentId = req.userId;
    const { childId } = req.params;
    const { startDate, endDate } = req.query;

    // Verify parent-child link
    const parent = await User.findById(parentId);
    if (!parent || !parent.linkedChildren.some(id => id.toString() === childId)) {
      return res.status(403).json({ error: 'Bạn không có quyền xem thống kê vị trí của trẻ này' });
    }

    // Default date range: last 24 hours
    const start = startDate ? new Date(startDate) : new Date(Date.now() - 24 * 60 * 60 * 1000);
    const end = endDate ? new Date(endDate) : new Date();

    const locations = await Location.find({
      userId: childId,
      timestamp: { $gte: start, $lte: end }
    }).sort({ timestamp: 1 }); // Sort ascending for distance calculation

    if (locations.length < 2) {
      return res.json({ 
        success: true, 
        data: { totalDistance: 0, totalTime: 0, mostVisited: [] }
      });
    }

    // Calculate total distance
    let totalDistance = 0;
    for (let i = 1; i < locations.length; i++) {
      const dist = haversineDistance(
        locations[i - 1].latitude, locations[i - 1].longitude,
        locations[i].latitude, locations[i].longitude
      );
      totalDistance += dist;
    }

    // Calculate total time in hours
    const totalTime = (locations[locations.length - 1].timestamp - locations[0].timestamp) / (1000 * 60 * 60);

    // Calculate most visited locations - cluster within 100m radius
    const clusters = [];
    const CLUSTER_RADIUS_M = 100; // 100 meters
    const visited = new Set();

    for (let i = 0; i < locations.length; i++) {
      if (visited.has(i)) continue;

      const cluster = [locations[i]];
      visited.add(i);

      // Find all locations within 100m of this location
      for (let j = i + 1; j < locations.length; j++) {
        if (visited.has(j)) continue;
        
        const dist = haversineDistance(
          locations[i].latitude, locations[i].longitude,
          locations[j].latitude, locations[j].longitude
        );
        
        // Convert km to meters and check if within cluster radius
        if (dist * 1000 <= CLUSTER_RADIUS_M) {
          cluster.push(locations[j]);
          visited.add(j);
        }
      }

      clusters.push(cluster);
    }

    // Sort clusters by count (most visited first) and get top 3
    const mostVisited = clusters
      .sort((a, b) => b.length - a.length)
      .slice(0, 3)
      .map(cluster => {
        // Calculate centroid of cluster
        const avgLat = cluster.reduce((sum, loc) => sum + loc.latitude, 0) / cluster.length;
        const avgLon = cluster.reduce((sum, loc) => sum + loc.longitude, 0) / cluster.length;
        
        return {
          latitude: parseFloat(avgLat.toFixed(6)),
          longitude: parseFloat(avgLon.toFixed(6)),
          count: cluster.length,
          address: 'Địa điểm'
        };
      });

    res.json({
      success: true,
      data: {
        totalDistance: parseFloat(totalDistance.toFixed(2)),
        totalTime: parseFloat(totalTime.toFixed(2)),
        mostVisited,
      }
    });

  } catch (error) {
    console.error('Get location stats error:', error);
    res.status(500).json({ error: 'Không thể tính toán thống kê vị trí' });
  }
};
