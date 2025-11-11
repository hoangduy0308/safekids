/**
 * Geofence Routes - Việt hóa
 * @swagger
 * tags:
 *   name: Ranh giới địa lý
 *   description: Quản lý ranh giới ảo (geofences) cho trẻ em
 */

const express = require("express");
const router = express.Router();
const { auth } = require("../middleware/auth");
const {
  createGeofence,
  getGeofences,
  updateGeofence,
  deleteGeofence,
  bulkDeleteGeofences,
  bulkUpdateGeofences,
  getAlerts,
  getAlertStats,
  getSuggestions,
  dismissSuggestion
} = require("../controllers/geofence.controller");

/**
 * @swagger
 * /api/geofence:
 *   get:
 *     summary: Lấy tất cả ranh giới địa lý
 *     tags: [Ranh giới địa lý]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Mảng các ranh giới địa lý
 *   post:
 *     summary: Tạo ranh giới địa lý mới
 *     tags: [Ranh giới địa lý]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [name, latitude, longitude, radius, childId]
 *             properties:
 *               name:
 *                 type: string
 *                 example: "Trường học"
 *               latitude:
 *                 type: number
 *               longitude:
 *                 type: number
 *               radius:
 *                 type: number
 *                 description: Bán kính tính bằng mét
 *               childId:
 *                 type: string
 *               color:
 *                 type: string
 *               description:
 *                 type: string
 *     responses:
 *       201:
 *         description: Ranh giới đã được tạo
 */
router.get("/", auth, getGeofences);
router.post("/", auth, createGeofence);

/**
 * @swagger
 * /api/geofence/{id}:
 *   put:
 *     summary: Cập nhật ranh giới địa lý
 *     tags: [Ranh giới địa lý]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               latitude:
 *                 type: number
 *               longitude:
 *                 type: number
 *               radius:
 *                 type: number
 *     responses:
 *       200:
 *         description: Ranh giới đã được cập nhật
 *   delete:
 *     summary: Xóa ranh giới địa lý
 *     tags: [Ranh giới địa lý]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: string
 *         required: true
 *     responses:
 *       200:
 *         description: Ranh giới đã được xóa
 */
router.put("/:id", auth, updateGeofence);
router.delete("/:id", auth, deleteGeofence);

/**
 * @swagger
 * /api/geofence/bulk-delete:
 *   post:
 *     summary: Xóa hàng loạt nhiều ranh giới địa lý
 *     tags: [Ranh giới địa lý]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [ids]
 *             properties:
 *               ids:
 *                 type: array
 *                 items:
 *                   type: string
 *     responses:
 *       200:
 *         description: Các ranh giới đã được xóa
 */
router.post("/bulk-delete", auth, bulkDeleteGeofences);

/**
 * @swagger
 * /api/geofence/bulk-update:
 *   post:
 *     summary: Cập nhật hàng loạt nhiều ranh giới địa lý
 *     tags: [Ranh giới địa lý]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [geofences]
 *             properties:
 *               geofences:
 *                 type: array
 *                 items:
 *                   type: object
 *     responses:
 *       200:
 *         description: Các ranh giới đã được cập nhật
 */
router.post("/bulk-update", auth, bulkUpdateGeofences);

/**
 * @swagger
 * /api/geofence/alerts:
 *   get:
 *     summary: Lấy lịch sử cảnh báo ranh giới địa lý
 *     tags: [Ranh giới địa lý]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: childId
 *         schema:
 *           type: string
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *       - in: query
 *         name: skip
 *         schema:
 *           type: integer
 *     responses:
 *       200:
 *         description: Mảng các cảnh báo
 */
router.get("/alerts", auth, getAlerts);

/**
 * @swagger
 * /api/geofence/alerts/stats:
 *   get:
 *     summary: Lấy thống kê cảnh báo ranh giới địa lý
 *     tags: [Ranh giới địa lý]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Thống kê cảnh báo
 */
router.get("/alerts/stats", auth, getAlertStats);

/**
 * @swagger
 * /api/geofence/suggestions/{childId}:
 *   get:
 *     summary: Lấy gợi ý ranh giới địa lý cho một trẻ em
 *     tags: [Ranh giới địa lý]
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
 *         description: Mảng các gợi ý
 */
router.get("/suggestions/:childId", auth, getSuggestions);

/**
 * @swagger
 * /api/geofence/suggestions/dismiss:
 *   post:
 *     summary: Loại bỏ một gợi ý ranh giới địa lý
 *     tags: [Ranh giới địa lý]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [suggestionId]
 *             properties:
 *               suggestionId:
 *                 type: string
 *     responses:
 *       200:
 *         description: Gợi ý đã được loại bỏ
 */
router.post("/suggestions/dismiss", auth, dismissSuggestion);

module.exports = router;
