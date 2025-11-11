/**
 * Link Routes - Việt hóa
 * @swagger
 * tags:
 *   name: Liên kết
 *   description: Quản lý liên kết tài khoản phụ huynh-trẻ em và kết nối
 */

const express = require('express');
const router = express.Router();
const linkController = require('../controllers/link.controller');
const { auth } = require('../middleware/auth');

/**
 * @swagger
 * /api/link/request:
 *   post:
 *     summary: Gửi yêu cầu liên kết cho người dùng khác
 *     tags: [Liên kết]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email]
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *     responses:
 *       201:
 *         description: Yêu cầu liên kết đã được gửi
 *       404:
 *         description: Không tìm thấy tài khoản
 */
router.post('/request', auth, linkController.sendRequest);

/**
 * @swagger
 * /api/link/accept/{requestId}:
 *   post:
 *     summary: Chấp nhận yêu cầu liên kết
 *     tags: [Liên kết]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: requestId
 *         schema:
 *           type: string
 *         required: true
 *     responses:
 *       200:
 *         description: Yêu cầu liên kết đã được chấp nhận
 */
router.post('/accept/:requestId', auth, linkController.acceptRequest);

/**
 * @swagger
 * /api/link/reject/{requestId}:
 *   post:
 *     summary: Từ chối yêu cầu liên kết
 *     tags: [Liên kết]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: requestId
 *         schema:
 *           type: string
 *         required: true
 *     responses:
 *       200:
 *         description: Yêu cầu liên kết đã được từ chối
 */
router.post('/reject/:requestId', auth, linkController.rejectRequest);

/**
 * @swagger
 * /api/link/requests:
 *   get:
 *     summary: Lấy các yêu cầu liên kết đang chờ
 *     tags: [Liên kết]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [pending, accepted, rejected]
 *     responses:
 *       200:
 *         description: Mảng các yêu cầu liên kết
 */
router.get('/requests', auth, linkController.getRequests);

/**
 * @swagger
 * /api/link/remove/{childId}:
 *   delete:
 *     summary: Xóa liên kết tài khoản trẻ em/phụ huynh
 *     tags: [Liên kết]
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
 *         description: Liên kết đã được xóa
 *       403:
 *         description: Không có quyền truy cập
 */
router.delete('/remove/:childId', auth, linkController.removeLink);

module.exports = router;
