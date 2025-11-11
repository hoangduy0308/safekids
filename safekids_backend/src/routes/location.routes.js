/**
 * Location Routes - Việt hóa
 * @swagger
 * tags:
 *   name: Vị trí
 *   description: Theo dõi vị trí và quản lý lịch sử vị trí
 */

const express = require('express');
const router = express.Router();
const locationController = require('../controllers/location.controller');
const { auth } = require('../middleware/auth');

/**
 * @swagger
 * /api/location:
 *   post:
 *     summary: Tạo bản ghi vị trí mới
 *     tags: [Vị trí]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [latitude, longitude]
 *             properties:
 *               latitude:
 *                 type: number
 *                 example: 21.0285
 *               longitude:
 *                 type: number
 *                 example: 105.8542
 *               accuracy:
 *                 type: number
 *                 description: Độ chính xác GPS (tính bằng mét)
 *               address:
 *                 type: string
 *     responses:
 *       201:
 *         description: Vị trí đã được tạo
 *       400:
 *         description: Lỗi xác thực
 */
router.post('/', auth, locationController.createLocation);

/**
 * @swagger
 * /api/location/my-children:
 *   get:
 *     summary: Lấy vị trí mới nhất của tất cả trẻ em
 *     tags: [Vị trí]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Mảng trẻ em có vị trí mới nhất của họ
 */
router.get('/my-children', auth, locationController.getAllChildrenLocations);

/**
 * @swagger
 * /api/location/child/{childId}/latest:
 *   get:
 *     summary: Lấy vị trí mới nhất của một trẻ em
 *     tags: [Vị trí]
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
 *         description: Vị trí mới nhất của trẻ em
 */
router.get('/child/:childId/latest', auth, locationController.getLatestLocation);

/**
 * @swagger
 * /api/location/{userId}:
 *   get:
 *     summary: Lấy danh sách vị trí của người dùng
 *     tags: [Vị trí]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: userId
 *         schema:
 *           type: string
 *         required: true
 *     responses:
 *       200:
 *         description: Mảng các vị trí
 */
router.get('/:userId', auth, locationController.getLocations);

/**
 * @swagger
 * /api/location/child/{childId}/history:
 *   get:
 *     summary: Lấy lịch sử vị trí của một trẻ em
 *     tags: [Vị trí]
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
 *         description: Lịch sử vị trí
 */
router.get('/child/:childId/history', auth, locationController.getLocationHistory);

/**
 * @swagger
 * /api/location/child/{childId}/stats:
 *   get:
 *     summary: Lấy thống kê vị trí cho một trẻ em
 *     tags: [Vị trí]
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
 *         description: Thống kê vị trí
 */
router.get('/child/:childId/stats', auth, locationController.getLocationStats);

module.exports = router;
