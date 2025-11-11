/**
 * Parent Routes - Việt hóa
 * @swagger
 * tags:
 *   name: Phụ huynh
 *   description: Các endpoint dành riêng cho phụ huynh quản lý trẻ em
 */

const express = require('express');
const router = express.Router();
const parentController = require('../controllers/parent.controller');
const { auth } = require('../middleware/auth');

/**
 * @swagger
 * /api/parent/children:
 *   get:
 *     summary: Lấy tất cả trẻ em đã liên kết
 *     tags: [Phụ huynh]
 *     security:
 *       - bearerAuth: []
 *     description: Trả về danh sách tất cả tài khoản trẻ em được liên kết với phụ huynh
 *     responses:
 *       200:
 *         description: Mảng trẻ em với thông tin chi tiết của họ
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                 data:
 *                   type: object
 *                   properties:
 *                     children:
 *                       type: array
 *                       items:
 *                         $ref: '#/components/schemas/User'
 *       401:
 *         description: Chưa xác thực
 *       403:
 *         description: Chỉ phụ huynh mới có thể truy cập endpoint này
 */
router.get('/children', auth, parentController.getMyChildren);

module.exports = router;
