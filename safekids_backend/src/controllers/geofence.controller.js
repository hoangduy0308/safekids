const Geofence = require('../models/Geofence');
const User = require('../models/User');
const GeofenceAlert = require('../models/GeofenceAlert');
const DismissedSuggestion = require('../models/DismissedSuggestion');
const { findFrequentLocations } = require('../services/location-clustering.service');
const { haversineDistance } = require('../utils/geolocation');

/**
 * @route   POST /api/geofence
 * @desc    Create a new geofence (parent only)
 * @access  Private
 */
exports.createGeofence = async (req, res) => {
  try {
    const parentId = req.userId;
    const { name, type, center, radius, activeHours, linkedChildren } = req.body;
    const centerLat = center?.latitude;
    const centerLng = center?.longitude;

    console.log('[CreateGeofence] Request body:', { name, type, center, radius, linkedChildren });
    console.log('[CreateGeofence] Extracted coords:', { centerLat, centerLng });

    // Verify parent role
    const parent = await User.findById(parentId);
    if (!parent) {
      return res.status(404).json({ error: 'Người dùng không tồn tại' });
    }

    console.log('[CreateGeofence] Parent:', { id: parent._id, name: parent.name, linkedChildren: parent.linkedChildren });

    if (parent.role !== 'parent') {
      return res.status(403).json({ error: 'Chỉ phụ huynh mới có thể tạo vùng địa phương' });
    }

    // Validate coordinates exist
    if (centerLat === undefined || centerLng === undefined) {
      return res.status(400).json({ error: 'Tọa độ tâm vùng là bắt buộc' });
    }

    // Validate linkedChildren are parent's children
    if (!linkedChildren || linkedChildren.length === 0) {
      return res.status(400).json({ error: 'Phải chọn ít nhất một trẻ em' });
    }

    const validChildren = linkedChildren.filter(childId => {
      const match = parent.linkedChildren.some(id => id.toString() === childId);
      console.log(`[CreateGeofence] Checking childId: ${childId}, found: ${match}`);
      return match;
    });

    console.log('[CreateGeofence] Valid children:', validChildren);

    if (validChildren.length === 0) {
      return res.status(400).json({ 
        error: 'Các trẻ em được chọn không hợp lệ',
        debug: {
          sentChildren: linkedChildren,
          parentLinkedChildren: parent.linkedChildren.map(id => id.toString())
        }
      });
    }

    // Validate radius
    if (radius < 50 || radius > 1000) {
      return res.status(400).json({ error: 'Bán kính phải từ 50-1000 mét' });
    }

    // Validate coordinates
    if (centerLat < -90 || centerLat > 90 || centerLng < -180 || centerLng > 180) {
      return res.status(400).json({ error: 'Tọa độ không hợp lệ' });
    }

    const geofence = new Geofence({
      parentId,
      name,
      type,
      center: {
        latitude: centerLat,
        longitude: centerLng
      },
      radius,
      activeHours: activeHours || null,
      linkedChildren: validChildren
    });

    await geofence.save();

    res.status(201).json({
      success: true,
      data: { geofence }
    });
  } catch (error) {
    console.error('❌ [Geofence POST] Error:', error);
    res.status(500).json({ error: error.message || 'Lỗi khi tạo vùng địa phương' });
  }
};

/**
 * @route   GET /api/geofence
 * @desc    Get all geofences for parent or child
 * @access  Private
 */
exports.getGeofences = async (req, res) => {
  try {
    const userId = req.userId;
    const { childId } = req.query;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: 'Người dùng không tồn tại' });
    }

    let query = {};

    if (user.role === 'parent') {
      query.parentId = userId;
      if (childId) {
        query.linkedChildren = childId;
      }
    } else if (user.role === 'child') {
      query.linkedChildren = userId;
    }

    const geofences = await Geofence.find(query)
      .populate('linkedChildren', 'fullName name')
      .sort({ createdAt: -1 });

    res.json({
      success: true,
      data: { geofences }
    });
  } catch (error) {
    console.error('❌ [Geofence GET] Error:', error);
    res.status(500).json({ error: error.message || 'Lỗi khi lấy vùng địa phương' });
  }
};

/**
 * @route   PUT /api/geofence/:id
 * @desc    Update a geofence (parent only)
 * @access  Private
 */
exports.updateGeofence = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.userId;
    const { name, type, centerLat, centerLng, radius, activeHours, linkedChildren } = req.body;

    const geofence = await Geofence.findById(id);

    if (!geofence) {
      return res.status(404).json({ error: 'Vùng địa phương không tồn tại' });
    }

    // Only owner can update - compare as strings
    if (geofence.parentId.toString() !== userId.toString()) {
      return res.status(403).json({ error: 'Không có quyền cập nhật vùng này' });
    }

    // Verify parent and linkedChildren
    const parent = await User.findById(userId);
    if (linkedChildren) {
      const validChildren = linkedChildren.filter(childId => 
        parent.linkedChildren.some(id => id.toString() === childId)
      );
      if (validChildren.length === 0) {
        return res.status(400).json({ error: 'Các trẻ em được chọn không hợp lệ' });
      }
    }

    // Update fields
    if (name) geofence.name = name;
    if (type) geofence.type = type;
    if (centerLat !== undefined && centerLng !== undefined) {
      geofence.center = {
        latitude: centerLat,
        longitude: centerLng
      };
    }
    if (radius) {
      if (radius < 50 || radius > 1000) {
        return res.status(400).json({ error: 'Bán kính phải từ 50-1000 mét' });
      }
      geofence.radius = radius;
    }
    if (activeHours !== undefined) geofence.activeHours = activeHours;
    if (linkedChildren) geofence.linkedChildren = linkedChildren;

    geofence.updatedAt = new Date();
    await geofence.save();

    res.json({
      success: true,
      data: { geofence }
    });
  } catch (error) {
    console.error('❌ [Geofence PUT] Error:', error);
    res.status(500).json({ error: error.message || 'Lỗi khi cập nhật vùng địa phương' });
  }
};

/**
 * @route   DELETE /api/geofence/:id
 * @desc    Delete a geofence (parent only)
 * @access  Private
 */
exports.deleteGeofence = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.userId;

    const geofence = await Geofence.findById(id);

    if (!geofence) {
      return res.status(404).json({ error: 'Vùng địa phương không tồn tại' });
    }

    console.log('[Geofence DELETE] userId:', userId, 'type:', typeof userId);
    console.log('[Geofence DELETE] parentId:', geofence.parentId, 'type:', typeof geofence.parentId);
    console.log('[Geofence DELETE] match:', geofence.parentId.toString() === userId.toString());

    // Only owner can delete - compare as strings
    if (geofence.parentId.toString() !== userId.toString()) {
      return res.status(403).json({ error: 'Không có quyền xóa vùng này' });
    }

    await geofence.deleteOne();

    res.json({
      success: true,
      message: 'Vùng địa phương đã được xóa'
    });
  } catch (error) {
    console.error('❌ [Geofence DELETE] Error:', error);
    res.status(500).json({ error: error.message || 'Lỗi khi xóa vùng địa phương' });
  }
};

/**
 * @route   POST /api/geofence/bulk-delete
 * @desc    Delete multiple geofences (parent only)
 * @access  Private
 */
exports.bulkDeleteGeofences = async (req, res) => {
  try {
    const { geofenceIds } = req.body;
    const userId = req.userId;

    if (!geofenceIds || !Array.isArray(geofenceIds) || geofenceIds.length === 0) {
      return res.status(400).json({ error: 'Danh sách ID vùng là bắt buộc' });
    }

    // Find all geofences and verify ownership
    const geofences = await Geofence.find({ _id: { $in: geofenceIds } });
    
    if (geofences.length === 0) {
      return res.status(404).json({ error: 'Không tìm thấy vùng nào' });
    }

    // Check ownership for each geofence - compare as strings
    const unauthorizedGeofences = geofences.filter(g => g.parentId.toString() !== userId.toString());
    if (unauthorizedGeofences.length > 0) {
      return res.status(403).json({ 
        error: `Không có quyền xóa ${unauthorizedGeofences.length} vùng`,
        unauthorized: unauthorizedGeofences.map(g => g._id)
      });
    }

    // Delete authorized geofences
    const authorizedGeofences = geofences.filter(g => g.parentId.toString() === userId.toString());
    const result = await Geofence.deleteMany({ _id: { $in: authorizedGeofences.map(g => g._id) } });

    res.json({
      success: true,
      data: { 
        deletedCount: result.deletedCount,
        unauthorizedCount: unauthorizedGeofences.length
      }
    });
  } catch (error) {
    console.error('❌ [Geofence Bulk Delete] Error:', error);
    res.status(500).json({ error: error.message || 'Lỗi khi xóa hàng loạt vùng' });
  }
}

/**
 * @route   POST /api/geofence/bulk-update
 * @desc    Bulk update geofence status (parent only)
 * @access  Private
 */
exports.bulkUpdateGeofences = async (req, res) => {
  try {
    const { geofenceIds, updates } = req.body;
    const userId = req.userId;

    if (!geofenceIds || !Array.isArray(geofenceIds) || geofenceIds.length === 0) {
      return res.status(400).json({ error: 'Danh sách ID vùng là bắt buộc' });
    }

    if (!updates || typeof updates !== 'object') {
      return res.status(400).json({ error: 'Dữ liệu cập nhật là bắt buộc' });
    }

    // Find geofences and verify ownership
    const geofences = await Geofence.find({ _id: { $in: geofenceIds } });
    
    const unauthorizedGeofences = geofences.filter(g => g.parentId.toString() !== userId);
    if (unauthorizedGeofences.length > 0) {
      return res.status(403).json({ 
        error: `Không có quyền cập nhật ${unauthorizedGeofences.length} vùng`,
        unauthorized: unauthorizedGeofences.map(g => g._id)
      });
    }

    // Update authorized geofences
    const authorizedGeofences = geofences.filter(g => g.parentId.toString() === userId);
    const updatesWithTimestamp = {
      ...updates,
      updatedAt: new Date()
    };

    const result = await Geofence.updateMany(
      { _id: { $in: authorizedGeofences.map(g => g._id) } },
      updatesWithTimestamp
    );

    res.json({
      success: true,
      data: {
        updatedCount: result.modifiedCount,
        unauthorizedCount: unauthorizedGeofences.length
      }
    });
  } catch (error) {
    console.error('❌ [Geofence Bulk Update] Error:', error);
    res.status(500).json({ error: error.message || 'Lỗi khi cập nhật hàng loạt vùng' });
  }
}

/**
 * @route   GET /api/geofence/suggestions/:childId
 * @desc    Get smart suggestions for geofences based on frequent locations
 * @access  Private (parent only)
 */
exports.getSuggestions = async (req, res) => {
  try {
    const parentId = req.userId;
    const { childId } = req.params;

    // Verify parent owns child
    const parent = await User.findById(parentId);
    if (!parent) {
      return res.status(404).json({ error: 'Người dùng không tồn tại' });
    }

    if (!parent.linkedChildren.includes(childId)) {
      return res.status(403).json({ error: 'Không có quyền xem gợi ý cho trẻ này' });
    }

    // Find frequent locations
    const clusters = await findFrequentLocations(childId, 30);
    console.log(`[getSuggestions] childId: ${childId}, clusters found: ${clusters.length}`);

    if (clusters.length === 0) {
      console.log(`[getSuggestions] No clusters found for childId: ${childId}`);
      return res.json({ success: true, data: { suggestions: [] } });
    }

    // Get existing geofences for this child
    const existingGeofences = await Geofence.find({
      parentId,
      linkedChildren: childId
    });

    // Get dismissed suggestions
    const dismissed = await DismissedSuggestion.find({ parentId, childId });

    // Filter out clusters that already have geofences or are dismissed
    const suggestions = [];
    for (let i = 0; i < clusters.length; i++) {
      const cluster = clusters[i];

      // Check if geofence already exists nearby (within 200m)
      const hasDuplicate = existingGeofences.some(g => {
        const distanceKm = haversineDistance(
          cluster.center.latitude,
          cluster.center.longitude,
          g.center.latitude,
          g.center.longitude
        );
        const distanceMeters = distanceKm * 1000;
        return distanceMeters <= 200;
      });

      if (hasDuplicate) continue;

      // Check if dismissed
      const isDismissed = dismissed.some(d => {
        const distanceKm = haversineDistance(
          cluster.center.latitude,
          cluster.center.longitude,
          d.location.latitude,
          d.location.longitude
        );
        const distanceMeters = distanceKm * 1000;
        return distanceMeters <= 100;
      });

      if (isDismissed) continue;

      // Add to suggestions
      suggestions.push({
        id: `suggestion-${suggestions.length + 1}`,
        name: cluster.locationName || `Địa điểm thường xuyên #${suggestions.length + 1}`,
        center: {
          latitude: cluster.center.latitude,
          longitude: cluster.center.longitude
        },
        visitCount: cluster.visitCount,
        suggestedType: 'safe'
      });
    }

    res.json({ success: true, data: { suggestions } });
  } catch (error) {
    console.error('❌ [Geofence Suggestions GET] Error:', error);
    res.status(500).json({ error: error.message || 'Lỗi khi lấy gợi ý vùng' });
  }
};

/**
 * @route   POST /api/geofence/suggestions/dismiss
 * @desc    Dismiss a geofence suggestion
 * @access  Private (parent only)
 */
exports.dismissSuggestion = async (req, res) => {
  try {
    const parentId = req.userId;
    const { childId, location } = req.body;

    // Verify parent owns child
    const parent = await User.findById(parentId);
    if (!parent) {
      return res.status(404).json({ error: 'Người dùng không tồn tại' });
    }

    if (!parent.linkedChildren.includes(childId)) {
      return res.status(403).json({ error: 'Không có quyền ẩn gợi ý cho trẻ này' });
    }

    // Validate location
    if (!location || typeof location.latitude !== 'number' || typeof location.longitude !== 'number') {
      return res.status(400).json({ error: 'Tọa độ không hợp lệ' });
    }

    // Create dismissed record
    await DismissedSuggestion.create({
      parentId,
      childId,
      location: {
        latitude: location.latitude,
        longitude: location.longitude
      },
      dismissedAt: new Date()
    });

    res.json({ success: true, message: 'Gợi ý đã được ẩn' });
  } catch (error) {
    console.error('❌ [Geofence Suggestions Dismiss] Error:', error);
    res.status(500).json({ error: error.message || 'Lỗi khi ẩn gợi ý' });
  }
};

module.exports = exports;
/**
 * @route   GET /api/geofence/alerts
 * @desc    Get geofence alerts for parent's linked children with filters
 * @access  Private (parent only)
 */
exports.getAlerts = async (req, res) => {
  try {
    const parentId = req.userId;
    const { startDate, endDate, childId, geofenceId } = req.query;
    const limit = Math.min(parseInt(req.query.limit || '50', 10), 100);
    const skip = Math.max(parseInt(req.query.skip || '0', 10), 0);

    const parent = await User.findById(parentId);
    if (!parent) {
      return res.status(404).json({ error: 'Người dùng không tồn tại' });
    }
    if (parent.role !== 'parent') {
      return res.status(403).json({ error: 'Chỉ phụ huynh mới có thể xem lịch sử cảnh báo' });
    }

    let validChildIds = (parent.linkedChildren || []).map(id => id.toString());
    if (childId) {
      if (!validChildIds.includes(childId)) {
        return res.status(403).json({ error: 'Không có quyền xem cảnh báo của trẻ này' });
      }
      validChildIds = [childId];
    }

    const query = { childId: { $in: validChildIds } };
    if (geofenceId) query.geofenceId = geofenceId;

    if (startDate || endDate) {
      query.timestamp = {};
      if (startDate) query.timestamp.$gte = new Date(startDate);
      if (endDate) query.timestamp.$lte = new Date(endDate);
    }

    const [alerts, total] = await Promise.all([
      GeofenceAlert.find(query)
        .populate('childId', 'fullName name')
        .populate('geofenceId', 'name type')
        .sort({ timestamp: -1 })
        .skip(skip)
        .limit(limit),
      GeofenceAlert.countDocuments(query)
    ]);

    res.json({
      success: true,
      data: {
        alerts,
        total,
        hasMore: skip + alerts.length < total
      }
    });
  } catch (error) {
    console.error('❌ [Geofence Alerts GET] Error:', error);
    res.status(500).json({ error: error.message || 'Lỗi khi lấy lịch sử cảnh báo' });
  }
};

/**
 * @route   GET /api/geofence/alerts/stats
 * @desc    Get alerts statistics for parent's linked children
 * @access  Private (parent only)
 */
exports.getAlertStats = async (req, res) => {
  try {
    const parentId = req.userId;
    const { startDate, endDate } = req.query;

    const parent = await User.findById(parentId);
    if (!parent) {
      return res.status(404).json({ error: 'Người dùng không tồn tại' });
    }
    if (parent.role !== 'parent') {
      return res.status(403).json({ error: 'Chỉ phụ huynh mới có thể xem thống kê cảnh báo' });
    }

    const childIds = (parent.linkedChildren || []).map(id => id.toString());
    if (childIds.length === 0) {
      return res.json({ success: true, data: { total: 0, mostTriggeredGeofence: null, mostActiveChild: null } });
    }

    // Default to last 7 days if not provided
    let timeFilter = {};
    if (startDate || endDate) {
      timeFilter = { timestamp: {} };
      if (startDate) timeFilter.timestamp.$gte = new Date(startDate);
      if (endDate) timeFilter.timestamp.$lte = new Date(endDate);
    } else {
      timeFilter = { timestamp: { $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) } };
    }

    const match = { childId: { $in: childIds }, ...timeFilter };

    const [total, geofenceAgg, childAgg] = await Promise.all([
      GeofenceAlert.countDocuments(match),
      GeofenceAlert.aggregate([
        { $match: match },
        { $group: { _id: '$geofenceId', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $limit: 1 },
        { $lookup: { from: 'geofences', localField: '_id', foreignField: '_id', as: 'geofence' } },
        { $unwind: { path: '$geofence', preserveNullAndEmptyArrays: true } },
        { $project: { _id: 0, geofenceId: '$_id', name: '$geofence.name', type: '$geofence.type', count: 1 } }
      ]),
      GeofenceAlert.aggregate([
        { $match: match },
        { $group: { _id: '$childId', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $limit: 1 },
        { $lookup: { from: 'users', localField: '_id', foreignField: '_id', as: 'child' } },
        { $unwind: { path: '$child', preserveNullAndEmptyArrays: true } },
        { $project: { _id: 0, childId: '$_id', name: { $ifNull: ['$child.fullName', '$child.name'] }, count: 1 } }
      ])
    ]);

    res.json({
      success: true,
      data: {
        total,
        mostTriggeredGeofence: geofenceAgg[0] || null,
        mostActiveChild: childAgg[0] || null
      }
    });
  } catch (error) {
    console.error('❌ [Geofence Alerts Stats GET] Error:', error);
    res.status(500).json({ error: error.message || 'Lỗi khi lấy thống kê cảnh báo' });
  }
};
