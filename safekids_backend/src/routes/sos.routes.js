/**
 * SOS Routes - Việt hóa
 * @swagger
 * tags:
 *   name: SOS khẩn cấp
 *   description: Quản lý cảnh báo SOS khẩn cấp
 */

const express = require("express");
const router = express.Router();
const sosController = require("../controllers/sos.controller");
const { auth } = require("../middleware/auth");
const sosRateLimit = require("../middleware/sos-rate-limit");

/**
 * @swagger
 * /api/sos/trigger:
 *   post:
 *     summary: Kích hoạt cảnh báo SOS (giới hạn tần suất 1 lần/30 giây)
 *     tags: [SOS khẩn cấp]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               location:
 *                 type: object
 *                 properties:
 *                   latitude:
 *                     type: number
 *                   longitude:
 *                     type: number
 *               message:
 *                 type: string
 *     responses:
 *       201:
 *         description: Cảnh báo SOS đã được kích hoạt thành công
 *       429:
 *         description: Quá nhiều yêu cầu SOS (bị giới hạn tần suất)
 */
router.post("/trigger", auth, sosRateLimit, sosController.triggerSOS);

/**
 * @swagger
 * /api/sos/active:
 *   get:
 *     summary: Lấy các cảnh báo SOS đang hoạt động cho phụ huynh
 *     tags: [SOS khẩn cấp]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Mảng các cảnh báo SOS đang hoạt động
 */
router.get("/active", auth, sosController.getActiveSOS);

/**
 * @swagger
 * /api/sos/history:
 *   get:
 *     summary: Lấy lịch sử SOS của tất cả trẻ em
 *     tags: [SOS khẩn cấp]
 *     security:
 *       - bearerAuth: []
 *     parameters:
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
 *         description: Mảng các bản ghi lịch sử SOS
 */
router.get("/history", auth, sosController.getAllSOSHistory);

/**
 * @swagger
 * /api/sos/history/{childId}:
 *   get:
 *     summary: Lấy lịch sử SOS của một trẻ em cụ thể
 *     tags: [SOS khẩn cấp]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: childId
 *         schema:
 *           type: string
 *         required: true
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
 *         description: Mảng lịch sử SOS của trẻ em
 */
router.get("/history/:childId", auth, sosController.getSOSHistory);

/**
 * @swagger
 * /api/sos/stats:
 *   get:
 *     summary: Lấy thống kê SOS
 *     tags: [SOS khẩn cấp]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Thống kê SOS
 */
router.get("/stats", auth, sosController.getSOSStats);

/**
 * @swagger
 * /api/sos/{sosId}:
 *   get:
 *     summary: Lấy chi tiết cảnh báo SOS
 *     tags: [SOS khẩn cấp]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: sosId
 *         schema:
 *           type: string
 *         required: true
 *     responses:
 *       200:
 *         description: Chi tiết cảnh báo SOS
 *       404:
 *         description: Không tìm thấy cảnh báo SOS
 */
router.get("/:sosId", auth, sosController.getSOSDetails);

/**
 * @swagger
 * /api/sos/{sosId}/status:
 *   put:
 *     summary: Cập nhật trạng thái cảnh báo SOS
 *     tags: [SOS khẩn cấp]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: sosId
 *         schema:
 *           type: string
 *         required: true
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [status]
 *             properties:
 *               status:
 *                 type: string
 *                 enum: [responded, resolved, acknowledged]
 *     responses:
 *       200:
 *         description: Trạng thái SOS đã được cập nhật
 */
router.put("/:sosId/status", auth, sosController.updateSOSStatus);

/**
 * @swagger
 * /api/sos/{sosId}/resolve:
 *   post:
 *     summary: Giải quyết một cảnh báo SOS
 *     tags: [SOS khẩn cấp]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: sosId
 *         schema:
 *           type: string
 *         required: true
 *     requestBody:
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               notes:
 *                 type: string
 *     responses:
 *       200:
 *         description: Cảnh báo SOS đã được giải quyết
 */
router.post("/:sosId/resolve", auth, sosController.resolveSOSAlert);

module.exports = router;
