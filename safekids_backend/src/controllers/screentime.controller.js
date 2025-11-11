/**
 * Screen Time Controller
 * Handles screen time configuration and suggestions
 */

const User = require('../models/User');

const ScreenTimeConfig = require('../models/ScreenTimeConfig');
const ScreenTimeUsage = require('../models/ScreenTimeUsage');

/**
 * Get smart suggestions for screen time limits
 * GET /api/screentime/suggestions/:childId
 */
exports.getSuggestions = async (req, res) => {
  try {
    const parentId = req.userId;
    const { childId } = req.params;
    
    // Verify parent linked to child
    const parent = await User.findById(parentId);
    if (!parent.linkedUsers || !parent.linkedUsers.includes(childId)) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    
    // Get child
    const child = await User.findById(childId);
    if (!child) {
      return res.status(404).json({ message: 'Child not found' });
    }
    
    // Get current config
    let config = null;
    try {
      config = await ScreenTimeConfig.findOne({ childId });
    } catch (error) {
      // Model might not exist yet, continue with null config
    }
    const currentLimit = config?.dailyLimit || 120;
    
    // Get last 7 days usage
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    const startDate = sevenDaysAgo.toISOString().split('T')[0];
    const endDate = new Date().toISOString().split('T')[0];
    
    let usageHistory = [];
    try {
      usageHistory = await ScreenTimeUsage.find({
        childId,
        date: { $gte: startDate, $lte: endDate }
      });
    } catch (error) {
      // Model might not exist yet, continue with empty history
    }
    
    // Calculate suggestions
    const suggestions = {};
    
    // 1. Suggested limit (based on average usage)
    if (usageHistory.length > 0) {
      const totalMinutes = usageHistory.reduce((sum, r) => sum + r.totalMinutes, 0);
      const avgUsage = Math.round(totalMinutes / usageHistory.length);
      
      // Suggest 10% buffer above average
      suggestions.suggestedLimit = Math.round(avgUsage * 1.1);
      suggestions.reasoning = `Dựa trên mức dùng trung bình 7 ngày qua (${Math.floor(avgUsage/60)}h ${avgUsage%60}p)`;
    } else {
      suggestions.suggestedLimit = 120; // Default 2 hours
      suggestions.reasoning = 'Chưa có dữ liệu. Đề xuất mức mặc định';
    }
    
    // 2. Adjustment recommendation
    if (usageHistory.length >= 5 && config) {
      const daysOverLimit = usageHistory.filter(r => r.totalMinutes > currentLimit).length;
      const percentOverLimit = (daysOverLimit / usageHistory.length) * 100;
      
      if (percentOverLimit > 80) {
        // Frequently over limit
        suggestions.adjustmentRecommendation = {
          type: 'increase',
          message: 'Con thường vượt giới hạn. Có thể tăng lên hoặc giám sát chặt hơn',
          newLimit: Math.round(currentLimit * 1.2),
        };
      } else if (percentOverLimit < 20) {
        // Rarely over limit
        const avgUsage = usageHistory.reduce((sum, r) => sum + r.totalMinutes, 0) / usageHistory.length;
        if (avgUsage < currentLimit * 0.7) {
          suggestions.adjustmentRecommendation = {
            type: 'reduce',
            message: 'Con thường dùng ít hơn giới hạn. Có thể giảm xuống',
            newLimit: Math.round(avgUsage * 1.1),
          };
        }
      }
    }
    
    // 3. Age-based guideline
    const age = child.age || 10; // Default if not set
    let ageMin, ageMax, ageMessage;
    
    if (age >= 6 && age <= 8) {
      ageMin = 60; ageMax = 120;
      ageMessage = 'Khuyến nghị cho 6-8 tuổi: 1-2 giờ/ngày';
    } else if (age >= 9 && age <= 12) {
      ageMin = 120; ageMax = 180;
      ageMessage = 'Khuyến nghị cho 9-12 tuổi: 2-3 giờ/ngày';
    } else if (age >= 13 && age <= 17) {
      ageMin = 180; ageMax = 240;
      ageMessage = 'Khuyến nghị cho 13-17 tuổi: 3-4 giờ/ngày';
    } else {
      ageMin = 120; ageMax = 180;
      ageMessage = 'Khuyến nghị chung: 2-3 giờ/ngày';
    }
    
    suggestions.ageGuideline = { min: ageMin, max: ageMax, message: ageMessage };
    
    // 4. Bedtime suggestion
    if (!config || !config.bedtimeEnabled) {
      // Analyze when child typically stops using device
      // Simple heuristic: Find latest session end time across days
      let latestHour = 21; // Default 21:00
      
      if (usageHistory.length > 0) {
        const latestTimes = usageHistory.map(record => {
          if (record.sessions && record.sessions.length > 0) {
            const lastSession = record.sessions[record.sessions.length - 1];
            const endTime = new Date(lastSession.endTime);
            return endTime.getHours();
          }
          return 21;
        });
        
        latestHour = Math.round(latestTimes.reduce((sum, h) => sum + h, 0) / latestTimes.length);
      }
      
      suggestions.bedtimeSuggestion = {
        enabled: false,
        suggestedStart: `${latestHour}:00`,
        suggestedEnd: '07:00',
        reasoning: `Con thường ngừng dùng thiết bị lúc ${latestHour}:30`,
      };
    }
    
    res.json({ 
      success: true, 
      data: suggestions 
    });
    
  } catch (error) {
    console.error('Get suggestions error:', error);
    res.status(500).json({ message: 'Failed to get suggestions' });
  }
};

/**
 * Save screen time configuration
 * POST /api/screentime/config
 */
exports.saveConfig = async (req, res) => {
  try {
    const parentId = req.userId;
    const { childId, dailyLimit, bedtimeEnabled, bedtimeStart, bedtimeEnd } = req.body;
    
    // Verify parent linked to child
    const parent = await User.findById(parentId);
    if (!parent.linkedUsers || !parent.linkedUsers.includes(childId)) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    
    // Get child
    const child = await User.findById(childId);
    if (!child) {
      return res.status(404).json({ message: 'Child not found' });
    }
    
    // Update or create config
    const config = await ScreenTimeConfig.findOneAndUpdate(
      { childId },
      {
        childId,
        dailyLimit,
        bedtimeEnabled,
        bedtimeStart,
        bedtimeEnd,
        updatedAt: new Date()
      },
      { upsert: true, new: true }
    );
    
    res.json({
      success: true,
      data: config
    });
    
  } catch (error) {
    console.error('Save config error:', error);
    res.status(500).json({ message: 'Failed to save configuration' });
  }
};

/**
 * Get screen time configuration for a child
 * GET /api/screentime/config/:childId
 */
exports.getConfig = async (req, res) => {
  try {
    const parentId = req.userId;
    const { childId } = req.params;
    
    // Verify parent linked to child
    const parent = await User.findById(parentId);
    if (!parent.linkedUsers || !parent.linkedUsers.includes(childId)) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    
    const config = await ScreenTimeConfig.findOne({ childId });
    
    if (!config) {
      return res.json({
        success: true,
        data: {
          childId,
          dailyLimit: 120, // Default 2 hours
          bedtimeEnabled: false,
          bedtimeStart: '21:00',
          bedtimeEnd: '07:00'
        }
      });
    }
    
    res.json({
      success: true,
      data: config
    });
    
  } catch (error) {
    console.error('Get config error:', error);
    res.status(500).json({ message: 'Failed to get configuration' });
  }
};

/**
 * Record screen time usage (AC 5.2.5, 5.2.7)
 * POST /api/screentime/usage
 */
exports.recordUsage = async (req, res) => {
  try {
    const { childId, date, totalMinutes, sessions } = req.body;
    
    // Verify child exists
    const child = await User.findById(childId);
    if (!child) {
      return res.status(404).json({ error: 'Child not found' });
    }
    
    // Create or update usage record
    const usage = await ScreenTimeUsage.findOneAndUpdate(
      { childId, date },
      {
        childId,
        date,
        totalMinutes,
        sessions,
        updatedAt: new Date()
      },
      { upsert: true, new: true }
    );
    
    // Check limits and send notifications (AC 5.2.7)
    const config = await ScreenTimeConfig.findOne({ childId });
    if (config && config.dailyLimit > 0) {
      const limitPercent = (totalMinutes / config.dailyLimit) * 100;
      
      // Find all parents
      const parents = await User.find({ 
        role: 'parent', 
        linkedUsers: childId 
      });
      
      const notificationService = require('../services/notification.service');
      
      // 90% warning
      if (limitPercent >= 90 && limitPercent < 100) {
        const title = '⚠️ Cảnh Báo Thời Gian Màn Hình';
        const body = `${child.fullName || child.name} đã dùng 90% thời gian màn hình`;
        const data = {
          type: 'screentime_warning',
          childId: childId.toString(),
          percent: '90',
        };
        
        for (const parent of parents) {
          if (parent.fcmToken) {
            await notificationService.sendNotification(parent.fcmToken, title, body, data);
          }
        }
        
        console.log(`[Screen Time] 90% warning sent for child ${childId}`);
      }
      
      // 100% exceeded
      if (limitPercent >= 100) {
        const title = '🚫 Vượt Giới Hạn Thời Gian';
        const body = `${child.fullName || child.name} đã vượt giới hạn thời gian màn hình`;
        const data = {
          type: 'screentime_exceeded',
          childId: childId.toString(),
        };
        
        for (const parent of parents) {
          if (parent.fcmToken) {
            await notificationService.sendNotification(parent.fcmToken, title, body, data);
          }
        }
        
        console.log(`[Screen Time] 100% exceeded notification sent for child ${childId}`);
      }
    }
    
    res.json({
      success: true,
      data: usage
    });
    
  } catch (error) {
    console.error('Record usage error:', error);
    res.status(500).json({ message: 'Failed to record usage' });
  }
};

/**
 * Get today's usage (AC 5.2.6) - Story 5.2
 * GET /api/screentime/usage/:childId/today
 */
exports.getTodayUsage = async (req, res) => {
  try {
    const userId = req.userId;
    const { childId } = req.params;
    
    // Verify access (child or linked parent)
    const user = await User.findById(userId);
    const isChild = childId === userId;
    const isParent = user.role === 'parent' && user.linkedUsers && user.linkedUsers.includes(childId);
    
    if (!isChild && !isParent) {
      return res.status(403).json({ error: 'Không có quyền truy cập' });
    }
    
    // Get today's date in YYYY-MM-DD format
    const today = new Date().toISOString().split('T')[0];
    
    // Get usage
    let usage = await ScreenTimeUsage.findOne({ childId, date: today });
    
    if (!usage) {
      usage = {
        totalMinutes: 0,
        sessions: [],
      };
    }
    
    res.json({ 
      success: true, 
      data: usage 
    });
    
  } catch (error) {
    console.error('[Get Today Usage] Error:', error);
    res.status(500).json({ error: error.message || 'Không thể lấy dữ liệu sử dụng' });
  }
};

/**
 * Get screen time usage history
 * GET /api/screentime/usage/:childId?startDate=...&endDate=...
 */
exports.getUsageHistory = async (req, res) => {
  try {
    const parentId = req.userId;
    const { childId } = req.params;
    const { startDate, endDate } = req.query;
    
    // Verify parent linked to child
    const parent = await User.findById(parentId);
    if (!parent.linkedUsers || !parent.linkedUsers.includes(childId)) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    
    const query = { childId };
    
    if (startDate || endDate) {
      query.date = {};
      if (startDate) query.date.$gte = startDate;
      if (endDate) query.date.$lte = endDate;
    }
    
    const usageHistory = await ScreenTimeUsage
      .find(query)
      .sort({ date: 1 })
      .select('date totalMinutes sessions');
    
    res.json({
      success: true,
      data: usageHistory
    });
    
  } catch (error) {
    console.error('Get usage history error:', error);
    res.status(500).json({ message: 'Failed to get usage history' });
  }
};

/**
 * Get usage stats (AC 5.4.6) - Story 5.4
 * GET /api/screentime/usage/:childId/stats?startDate=X&endDate=Y
 */
exports.getUsageStats = async (req, res) => {
  try {
    const parentId = req.userId;
    const { childId } = req.params;
    const { startDate, endDate } = req.query;
    
    // Verify parent linked to child
    const parent = await User.findById(parentId);
    if (!parent.linkedUsers || !parent.linkedUsers.includes(childId)) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    
    // Build query
    const query = { childId };
    if (startDate || endDate) {
      query.date = {};
      if (startDate) query.date.$gte = startDate;
      if (endDate) query.date.$lte = endDate;
    }
    
    // Get usage records
    const usageHistory = await ScreenTimeUsage.find(query);
    
    if (usageHistory.length === 0) {
      return res.json({
        success: true,
        data: {
          totalMinutes: 0,
          averageDaily: 0,
          daysOverLimit: 0,
          totalDays: 0,
          mostActiveDay: null,
          usageByDayOfWeek: {},
        }
      });
    }
    
    // Calculate total usage
    const totalMinutes = usageHistory.reduce((sum, record) => sum + record.totalMinutes, 0);
    
    // Calculate average daily
    const averageDaily = Math.round(totalMinutes / usageHistory.length);
    
    // Get daily limit
    const config = await ScreenTimeConfig.findOne({ childId });
    const dailyLimit = config?.dailyLimit || 120;
    
    // Count days over limit
    const daysOverLimit = usageHistory.filter(record => record.totalMinutes > dailyLimit).length;
    
    // Find most active day
    const mostActive = usageHistory.reduce((max, record) => 
      record.totalMinutes > max.totalMinutes ? record : max
    );
    
    // Usage by day of week
    const usageByDayOfWeek = { 0: [], 1: [], 2: [], 3: [], 4: [], 5: [], 6: [] };
    usageHistory.forEach(record => {
      const date = new Date(record.date);
      const dayOfWeek = date.getDay(); // 0 = Sunday
      usageByDayOfWeek[dayOfWeek].push(record.totalMinutes);
    });
    
    const avgByDayOfWeek = {};
    Object.keys(usageByDayOfWeek).forEach(day => {
      const dayUsages = usageByDayOfWeek[day];
      if (dayUsages.length > 0) {
        avgByDayOfWeek[day] = Math.round(
          dayUsages.reduce((sum, val) => sum + val, 0) / dayUsages.length
        );
      } else {
        avgByDayOfWeek[day] = 0;
      }
    });
    
    res.json({
      success: true,
      data: {
        totalMinutes,
        averageDaily,
        daysOverLimit,
        totalDays: usageHistory.length,
        mostActiveDay: {
          date: mostActive.date,
          minutes: mostActive.totalMinutes,
        },
        usageByDayOfWeek: avgByDayOfWeek,
      }
    });
    
  } catch (error) {
    console.error('Get usage stats error:', error);
    res.status(500).json({ message: 'Failed to get usage stats' });
  }
};
