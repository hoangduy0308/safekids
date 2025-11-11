/**
 * SOS Controller
 * Handles emergency alert triggers and management
 */

const SOS = require('../models/SOS');
const User = require('../models/User');
const notificationService = require('../services/notification.service');

// Time limits for cancellation (Story 4.4)
const TIME_LIMITS = {
  CHILD_CANCEL: 5, // minutes
  PARENT_MARK_FALSE_ALARM: 30, // minutes
};

/**
 * @route   POST /api/sos/trigger
 * @desc    Trigger SOS emergency alert
 * @access  Private (child only)
 */
exports.triggerSOS = async (req, res) => {
  try {
    const childId = req.userId;
    const { location, batteryLevel, networkStatus, photoUrl, audioUrl } = req.body;

    console.log('[SOS Trigger] Child:', childId);
    console.log('[SOS Trigger] Location:', location);

    // Verify child user exists and has role 'child'
    const child = await User.findById(childId);
    if (!child) {
      return res.status(404).json({ error: 'User not found' });
    }

    if (child.role !== 'child') {
      return res.status(403).json({ error: 'Only children can trigger SOS' });
    }

    // Validate location
    if (!location || location.latitude === undefined || location.longitude === undefined) {
      return res.status(400).json({ error: 'Location (latitude, longitude) is required' });
    }

    if (location.latitude < -90 || location.latitude > 90 || 
        location.longitude < -180 || location.longitude > 180) {
      return res.status(400).json({ error: 'Invalid location coordinates' });
    }

    // Validate battery level (AC 4.1.3: Must be 0-100)
    if (batteryLevel !== null && batteryLevel !== undefined) {
      if (typeof batteryLevel !== 'number' || batteryLevel < 0 || batteryLevel > 100) {
        return res.status(400).json({ error: 'Battery level must be a number between 0-100' });
      }
    }

    // Create SOS document
    const sos = new SOS({
      childId,
      location: {
        latitude: location.latitude,
        longitude: location.longitude,
        accuracy: location.accuracy || null
      },
      timestamp: new Date(),
      batteryLevel: batteryLevel || null,
      networkStatus: networkStatus || 'unknown',
      photoUrl: photoUrl || null,
      audioUrl: audioUrl || null,
      status: 'active'
    });

    await sos.save();
    console.log('[SOS Trigger] SOS created:', sos._id);

    // Notify all linked parents
    try {
      await _notifyParents(child, sos);
    } catch (notifyError) {
      console.error('[SOS Trigger] Notification error:', notifyError);
      // Don't fail SOS if notification fails
    }

    // Emit Socket.io event for real-time alert
    try {
      const socketService = req.app.get('socketService');
      if (socketService) {
        await _emitSOSAlert(socketService, child, sos);
      }
    } catch (socketError) {
      console.error('[SOS Trigger] Socket error:', socketError);
    }

    res.status(201).json({
      success: true,
      data: {
        sosId: sos._id,
        status: sos.status,
        timestamp: sos.timestamp,
        message: 'SOS alert sent successfully'
      }
    });

  } catch (error) {
    console.error('[SOS Trigger] Error:', error);
    res.status(500).json({ error: error.message || 'Failed to trigger SOS' });
  }
};

/**
 * @route   GET /api/sos/active
 * @desc    Get active SOS alerts for parent
 * @access  Private (parent only)
 */
exports.getActiveSOS = async (req, res) => {
  try {
    const parentId = req.userId;

    // Verify parent
    const parent = await User.findById(parentId);
    if (!parent) {
      return res.status(404).json({ error: 'Parent not found' });
    }

    if (parent.role !== 'parent') {
      return res.status(403).json({ error: 'Only parents can view SOS alerts' });
    }

    // Get all SOS alerts for linked children
    const childIds = parent.linkedChildren;
    if (childIds.length === 0) {
      return res.json({ success: true, data: [] });
    }

    const alerts = await SOS.find({
      childId: { $in: childIds },
      status: 'active'
    })
      .populate('childId', 'name fullName email')
      .sort({ createdAt: -1 });

    console.log(`[Get Active SOS] Found ${alerts.length} active alerts for parent ${parentId}`);

    res.json({
      success: true,
      data: alerts
    });

  } catch (error) {
    console.error('[Get Active SOS] Error:', error);
    res.status(500).json({ error: error.message || 'Failed to get active SOS alerts' });
  }
};

/**
 * @route   GET /api/sos/:sosId
 * @desc    Get SOS alert details (AC 4.2.3)
 * @access  Private (parent only, must be linked to child)
 */
exports.getSOSDetails = async (req, res) => {
  try {
    const parentId = req.userId;
    const { sosId } = req.params;

    // Verify parent user
    const parent = await User.findById(parentId);
    if (!parent) {
      return res.status(404).json({ error: 'Người dùng không tồn tại' });
    }

    // Only parents can access this endpoint
    if (parent.role !== 'parent') {
      return res.status(403).json({ error: 'Chỉ phụ huynh mới có thể xem chi tiết SOS' });
    }

    // Get SOS with child info
    const sos = await SOS.findById(sosId)
      .populate('childId', 'name fullName email phoneNumber')
      .populate('resolvedBy', 'name fullName');

    if (!sos) {
      return res.status(404).json({ error: 'Không tìm thấy cảnh báo SOS' });
    }

    // Verify parent has access to this child
    const isLinked = parent.linkedChildren.some(id => id.equals(sos.childId._id));
    if (!isLinked) {
      return res.status(403).json({ error: 'Bạn không có quyền xem SOS này' });
    }

    res.json({
      success: true,
      data: {
        ...sos.toObject(),
        child: sos.childId
      }
    });

  } catch (error) {
    console.error('[Get SOS Details] Error:', error);
    res.status(500).json({ error: error.message || 'Không thể lấy chi tiết SOS' });
  }
};

/**
 * @route   PUT /api/sos/:sosId/status
 * @desc    Update SOS status (AC 4.2.6)
 * @access  Private (parent only)
 */
exports.updateSOSStatus = async (req, res) => {
  try {
    const userId = req.userId;
    const { sosId } = req.params;
    const { status, notes, reason } = req.body;

    // Validate status
    if (!['resolved', 'false_alarm'].includes(status)) {
      return res.status(400).json({ error: 'Trạng thái không hợp lệ. Chỉ chấp nhận: resolved, false_alarm' });
    }

    // Get user and SOS
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ error: 'Người dùng không tồn tại' });
    }

    const sos = await SOS.findById(sosId).populate('childId', 'name fullName');
    if (!sos) {
      return res.status(404).json({ error: 'Không tìm thấy cảnh báo SOS' });
    }

    // Check authorization
    const isChild = sos.childId._id.equals(userId);
    const isParent = user.role === 'parent' && user.linkedChildren.some(id => id.equals(sos.childId._id));

    if (!isChild && !isParent) {
      return res.status(403).json({ error: 'Bạn không có quyền cập nhật SOS này' });
    }

    // Validate status transition
    if (sos.status !== 'active') {
      return res.status(400).json({ error: 'Chỉ có thể cập nhật SOS đang hoạt động' });
    }

    // Time limit check (AC 4.4.8)
    const timeSinceCreation = (Date.now() - new Date(sos.timestamp).getTime()) / 1000 / 60;
    const timeLimit = isChild ? TIME_LIMITS.CHILD_CANCEL : TIME_LIMITS.PARENT_MARK_FALSE_ALARM;

    if (status === 'false_alarm' && timeSinceCreation > timeLimit) {
      return res.status(400).json({ 
        error: `Không thể hủy SOS sau ${timeLimit} phút`,
        timeLimit,
        timeSince: Math.round(timeSinceCreation)
      });
    }

    // Update SOS
    sos.status = status;

    if (status === 'resolved') {
      sos.resolvedBy = userId;
      sos.resolvedAt = new Date();
      if (notes) sos.notes = notes;
    } else if (status === 'false_alarm') {
      sos.falseAlarmReason = reason || 'Not specified';
      sos.markedBy = userId;
      sos.markedAt = new Date();
      if (notes) sos.notes = notes;
    }

    await sos.save();

    console.log(`[Update SOS Status] SOS ${sosId} updated to ${status} by ${isChild ? 'child' : 'parent'} ${userId}`);

    // Send cancellation notification (AC 4.4.4)
    if (status === 'false_alarm') {
      await _sendCancellationNotification(sos, user, isChild);
    }

    // Populate fields for response
    await sos.populate('resolvedBy', 'name fullName');
    await sos.populate('markedBy', 'name fullName');

    res.json({
      success: true,
      data: sos,
      message: status === 'false_alarm' ? 'Đã đánh dấu báo nhầm' : 'Đã xử lý SOS'
    });

  } catch (error) {
    console.error('[Update SOS Status] Error:', error);
    res.status(500).json({ error: error.message || 'Không thể cập nhật trạng thái SOS' });
  }
};

/**
 * @route   POST /api/sos/:sosId/resolve
 * @desc    Resolve SOS alert (legacy endpoint)
 * @access  Private (parent only)
 */
exports.resolveSOSAlert = async (req, res) => {
  try {
    const parentId = req.userId;
    const { sosId } = req.params;
    const { status, notes } = req.body; // status: 'resolved' or 'false_alarm'

    // Verify parent
    const parent = await User.findById(parentId);
    if (!parent || parent.role !== 'parent') {
      return res.status(403).json({ error: 'Only parents can resolve SOS alerts' });
    }

    const sos = await SOS.findById(sosId);
    if (!sos) {
      return res.status(404).json({ error: 'SOS alert not found' });
    }

    // Verify child is linked to parent
    const isLinked = parent.linkedChildren.some(id => id.equals(sos.childId));
    if (!isLinked) {
      return res.status(403).json({ error: 'Not authorized to resolve this SOS' });
    }

    // Update SOS
    sos.status = status || 'resolved';
    sos.resolvedAt = new Date();
    sos.resolvedBy = parentId;
    sos.notes = notes || null;
    await sos.save();

    console.log(`[Resolve SOS] Alert ${sosId} resolved by parent ${parentId}`);

    res.json({
      success: true,
      data: sos,
      message: 'SOS alert resolved'
    });

  } catch (error) {
    console.error('[Resolve SOS] Error:', error);
    res.status(500).json({ error: error.message || 'Failed to resolve SOS alert' });
  }
};

/**
 * @route   GET /api/sos/history
 * @desc    Get SOS history for all or filtered children (AC 4.3.6)
 * @access  Private (parent only)
 */
exports.getAllSOSHistory = async (req, res) => {
  try {
    const parentId = req.userId;
    const { childId, status, startDate, endDate, limit = 50, skip = 0 } = req.query;

    // Verify parent
    const parent = await User.findById(parentId);
    if (!parent || parent.role !== 'parent') {
      return res.status(403).json({ error: 'Chỉ phụ huynh mới có thể xem lịch sử SOS' });
    }

    // Get parent's linked children
    let validChildIds = parent.linkedChildren;

    // If childId specified, filter to that child only
    if (childId) {
      const isLinked = validChildIds.some(id => id.equals(childId));
      if (!isLinked) {
        return res.status(403).json({ error: 'Bạn không có quyền xem SOS của trẻ này' });
      }
      validChildIds = [childId];
    }

    // Build query
    const query = { childId: { $in: validChildIds } };

    // Filter by status
    if (status && ['active', 'resolved', 'false_alarm'].includes(status)) {
      query.status = status;
    }

    // Filter by date range
    if (startDate || endDate) {
      query.timestamp = {};
      if (startDate) query.timestamp.$gte = new Date(startDate);
      if (endDate) query.timestamp.$lte = new Date(endDate);
    }

    // Fetch SOS with populated fields
    const sosList = await SOS.find(query)
      .populate('childId', 'name fullName email photoUrl')
      .populate('resolvedBy', 'name fullName')
      .sort({ timestamp: -1 })
      .skip(parseInt(skip))
      .limit(Math.min(parseInt(limit), 100)); // Max 100 per request

    const total = await SOS.countDocuments(query);
    const hasMore = (parseInt(skip) + sosList.length) < total;

    console.log(`[Get All SOS History] Found ${sosList.length}/${total} SOS for parent ${parentId}`);

    res.json({
      success: true,
      data: {
        sosList,
        total,
        hasMore
      }
    });

  } catch (error) {
    console.error('[Get All SOS History] Error:', error);
    res.status(500).json({ error: error.message || 'Không thể lấy lịch sử SOS' });
  }
};

/**
 * @route   GET /api/sos/history/:childId
 * @desc    Get SOS history for specific child (legacy endpoint)
 * @access  Private (parent only)
 */
exports.getSOSHistory = async (req, res) => {
  try {
    const parentId = req.userId;
    const { childId } = req.params;
    const { limit = 50, skip = 0 } = req.query;

    // Verify parent
    const parent = await User.findById(parentId);
    if (!parent || parent.role !== 'parent') {
      return res.status(403).json({ error: 'Only parents can view SOS history' });
    }

    // Verify child is linked to parent
    const isLinked = parent.linkedChildren.some(id => id.equals(childId));
    if (!isLinked) {
      return res.status(403).json({ error: 'Not authorized to view this child\'s SOS history' });
    }

    const alerts = await SOS.find({ childId })
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(skip));

    const total = await SOS.countDocuments({ childId });

    res.json({
      success: true,
      data: {
        alerts,
        total,
        limit: parseInt(limit),
        skip: parseInt(skip)
      }
    });

  } catch (error) {
    console.error('[Get SOS History] Error:', error);
    res.status(500).json({ error: error.message || 'Failed to get SOS history' });
  }
};

/**
 * @route   GET /api/sos/stats
 * @desc    Get SOS statistics (AC 4.3.7 - Optional)
 * @access  Private (parent only)
 */
exports.getSOSStats = async (req, res) => {
  try {
    const parentId = req.userId;
    const { startDate, endDate } = req.query;

    // Verify parent
    const parent = await User.findById(parentId);
    if (!parent || parent.role !== 'parent') {
      return res.status(403).json({ error: 'Chỉ phụ huynh mới có thể xem thống kê SOS' });
    }

    // Get parent's linked children
    const validChildIds = parent.linkedChildren;

    // Build query
    const query = { childId: { $in: validChildIds } };

    if (startDate || endDate) {
      query.timestamp = {};
      if (startDate) query.timestamp.$gte = new Date(startDate);
      if (endDate) query.timestamp.$lte = new Date(endDate);
    }

    // Count total
    const total = await SOS.countDocuments(query);

    // Count by status
    const statusCounts = await SOS.aggregate([
      { $match: query },
      { $group: { _id: '$status', count: { $sum: 1 } } }
    ]);

    const stats = {
      total,
      active: 0,
      resolved: 0,
      false_alarm: 0
    };

    statusCounts.forEach(s => {
      stats[s._id] = s.count;
    });

    // Most frequent child
    const childCounts = await SOS.aggregate([
      { $match: query },
      { $group: { _id: '$childId', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 1 }
    ]);

    if (childCounts.length > 0) {
      const child = await User.findById(childCounts[0]._id);
      if (child) {
        stats.mostFrequentChild = child.fullName || child.name;
        stats.mostFrequentChildId = child._id;
      }
    }

    // Average response time (resolved SOS only)
    const resolvedSOS = await SOS.find({ ...query, status: 'resolved', resolvedAt: { $ne: null } });
    if (resolvedSOS.length > 0) {
      const totalResponseTime = resolvedSOS.reduce((sum, sos) => {
        const responseTime = (sos.resolvedAt - sos.timestamp) / 1000 / 60; // minutes
        return sum + responseTime;
      }, 0);
      stats.avgResponseTimeMinutes = Math.round(totalResponseTime / resolvedSOS.length);
    }

    console.log(`[Get SOS Stats] Stats for parent ${parentId}:`, stats);

    res.json({ success: true, data: stats });

  } catch (error) {
    console.error('[Get SOS Stats] Error:', error);
    res.status(500).json({ error: error.message || 'Không thể lấy thống kê SOS' });
  }
};

// ============ HELPER FUNCTIONS ============

/**
 * Notify all linked parents about SOS alert
 */
async function _notifyParents(child, sos) {
  try {
    // Find all parents linked to this child
    const parents = await User.find({
      linkedChildren: child._id,
      role: 'parent'
    });

    console.log(`[Notify Parents] Sending SOS to ${parents.length} parents`);

    // Collect FCM tokens from parents
    const fcmTokens = [];
    for (const parent of parents) {
      if (parent.fcmToken) {
        fcmTokens.push(parent.fcmToken);
      }
    }

    if (fcmTokens.length === 0) {
      console.warn('[Notify Parents] No FCM tokens available for parents');
      return;
    }

    // Send multicast notification to all parents
    const title = '🚨 CẢNH BÁO KHẨN CẤP';
    const body = `${child.fullName || child.name} đã gửi tín hiệu SOS!`;
    const data = {
      type: 'sos',
      sosId: sos._id.toString(),
      childId: child._id.toString(),
      childName: child.fullName || child.name,
      latitude: sos.location.latitude.toString(),
      longitude: sos.location.longitude.toString(),
      timestamp: sos.timestamp.toISOString()
    };

    const sent = await notificationService.sendMulticastNotification(fcmTokens, title, body, data);
    console.log(`[Notify Parents] Sent notifications to ${sent}/${parents.length} parents`);

  } catch (error) {
    console.error('[Notify Parents] Error:', error);
    throw error;
  }
}

/**
 * Send cancellation notification to all parents (AC 4.4.4)
 */
async function _sendCancellationNotification(sos, user, isChild) {
  try {
    const parents = await User.find({
      linkedChildren: sos.childId._id,
      role: 'parent'
    });

    if (parents.length === 0) {
      console.warn('[Cancel Notification] No parents found');
      return;
    }

    const fcmTokens = parents.map(p => p.fcmToken).filter(t => t);
    if (fcmTokens.length === 0) {
      console.warn('[Cancel Notification] No FCM tokens available');
      return;
    }

    const cancelledBy = isChild ? sos.childId.fullName : user.fullName;
    const title = '🔔 SOS Đã Hủy';
    const body = isChild 
      ? `${sos.childId.fullName} đã hủy cảnh báo SOS`
      : `${user.fullName} đã đánh dấu SOS là báo nhầm`;

    const data = {
      type: 'sos_cancelled',
      sosId: sos._id.toString(),
      childId: sos.childId._id.toString(),
      childName: sos.childId.fullName,
      cancelledBy: isChild ? 'child' : 'parent',
      cancelledByName: cancelledBy,
    };

    const sent = await notificationService.sendMulticastNotification(fcmTokens, title, body, data);
    console.log(`[Cancel Notification] Sent to ${sent}/${parents.length} parents`);

    // Emit Socket.io event (if socket service available)
    const socketService = req.app.locals.socketService;
    if (socketService) {
      socketService.emitToParents(parents.map(p => p._id.toString()), 'sosCancelled', data);
      console.log(`[Cancel Notification] Socket.io event emitted`);
    }

  } catch (error) {
    console.error('[Cancel Notification] Error:', error);
  }
}

/**
 * Emit SOS alert via Socket.io
 */
async function _emitSOSAlert(socketService, child, sos) {
  try {
    // Find all parents linked to this child
    const parents = await User.find({
      linkedChildren: child._id,
      role: 'parent'
    });

    console.log(`[Socket Alert] Emitting SOS to ${parents.length} parents`);

    const alertData = {
      type: 'sos',
      sosId: sos._id.toString(),
      childId: child._id.toString(),
      childName: child.fullName || child.name,
      location: {
        latitude: sos.location.latitude,
        longitude: sos.location.longitude,
        accuracy: sos.location.accuracy
      },
      timestamp: sos.timestamp,
      batteryLevel: sos.batteryLevel,
      networkStatus: sos.networkStatus
    };

    // Emit to each parent
    for (const parent of parents) {
      socketService.emitToUser(parent._id.toString(), 'sosAlert', alertData);
    }
  } catch (error) {
    console.error('[Socket Alert] Error:', error);
    throw error;
  }
}
