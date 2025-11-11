/**
 * Screen Time Routes - Việt hóa
 * @swagger
 * tags:
 *   name: Thời gian màn hình
 *   description: Quản lý và theo dõi thời gian sử dụng màn hình
 */

const express = require("express");
const router = express.Router();
const { auth } = require("../middleware/auth");
const screentimeController = require("../controllers/screentime.controller");

const requireParent = async (req, res, next) => {
  try {
    const User = require('../models/User');
    const user = await User.findById(req.userId);
    
    if (user.role !== 'parent') {
      return res.status(403).json({ message: 'Chỉ phụ huynh mới có thể truy cập cài đặt thời gian màn hình' });
    }
    
    next();
  } catch (error) {
    res.status(500).json({ message: 'Xác thực thất bại' });
  }
};

/**
 * @swagger
 * /api/screentime/suggestions/{childId}:
 *   get:
 *     summary: Lấy gợi ý thời gian màn hình cho một trẻ em
 *     tags: [Thời gian màn hình]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: childId
 *         schema:
 *           type: string
 *         required: true
 *     responses:
 *       200:
 *         description: Gợi ý thời gian màn hình
 */
router.get('/suggestions/:childId', auth, requireParent, screentimeController.getSuggestions);

/**
 * @swagger
 * /api/screentime/config:
 *   post:
 *     summary: Lưu cấu hình thời gian màn hình
 *     tags: [Thời gian màn hình]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [childId, dailyLimit]
 *             properties:
 *               childId:
 *                 type: string
 *               dailyLimit:
 *                 type: number
 *                 description: Giới hạn hàng ngày tính bằng phút
 *               schedules:
 *                 type: array
 *                 items:
 *                   type: object
 *     responses:
 *       201:
 *         description: Cấu hình đã được lưu
 */
router.post('/config', auth, requireParent, screentimeController.saveConfig);

/**
 * @swagger
 * /api/screentime/config/{childId}:
 *   get:
 *     summary: Lấy cấu hình thời gian màn hình cho một trẻ em
 *     tags: [Thời gian màn hình]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: childId
 *         schema:
 *           type: string
 *         required: true
 *     responses:
 *       200:
 *         description: Cấu hình thời gian màn hình
 */
router.get('/config/:childId', auth, requireParent, screentimeController.getConfig);

/**
 * @swagger
 * /api/screentime/usage:
 *   post:
 *     summary: Ghi nhận sử dụng thời gian màn hình
 *     tags: [Thời gian màn hình]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [duration]
 *             properties:
 *               duration:
 *                 type: number
 *                 description: Thời lượng tính bằng phút
 *               app:
 *                 type: string
 *               category:
 *                 type: string
 *     responses:
 *       201:
 *         description: Sử dụng đã được ghi nhận
 */
router.post('/usage', auth, screentimeController.recordUsage);

/**
 * @swagger
 * /api/screentime/usage/{childId}/today:
 *   get:
 *     summary: Lấy sử dụng thời gian màn hình hôm nay
 *     tags: [Thời gian màn hình]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: childId
 *         schema:
 *           type: string
 *         required: true
 *     responses:
 *       200:
 *         description: Dữ liệu sử dụng hôm nay
 */
router.get('/usage/:childId/today', auth, screentimeController.getTodayUsage);

/**
 * @swagger
 * /api/screentime/usage/{childId}/stats:
 *   get:
 *     summary: Lấy thống kê sử dụng thời gian màn hình
 *     tags: [Thời gian màn hình]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: childId
 *         schema:
 *           type: string
 *         required: true
 *       - in: query
 *         name: period
 *         schema:
 *           type: string
 *           enum: [day, week, month]
 *           default: week
 *     responses:
 *       200:
 *         description: Thống kê sử dụng
 */
router.get('/usage/:childId/stats', auth, requireParent, screentimeController.getUsageStats);

/**
 * @swagger
 * /api/screentime/usage/{childId}/history:
 *   get:
 *     summary: Lấy lịch sử sử dụng thời gian màn hình
 *     tags: [Thời gian màn hình]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: childId
 *         schema:
 *           type: string
 *         required: true
 *       - in: query
 *         name: startDate
 *         schema:
 *           type: string
 *           format: date-time
 *       - in: query
 *         name: endDate
 *         schema:
 *           type: string
 *           format: date-time
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Lịch sử sử dụng
 */
router.get('/usage/:childId/history', auth, requireParent, screentimeController.getUsageHistory);

module.exports = router;
