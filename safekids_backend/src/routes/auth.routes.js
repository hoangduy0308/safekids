/**
 * Authentication Routes - Việt hóa
 * @swagger
 * tags:
 *   name: Xác thực
 *   description: Đăng ký, đăng nhập và quản lý tài khoản người dùng
 */

const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const { auth } = require('../middleware/auth');

/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     summary: Đăng ký tài khoản mới (phụ huynh hoặc trẻ em)
 *     tags: [Xác thực]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [fullName, email, password, phone, role]
 *             properties:
 *               fullName:
 *                 type: string
 *                 example: "Nguyễn Văn A"
 *               email:
 *                 type: string
 *                 format: email
 *                 example: "user@example.com"
 *               password:
 *                 type: string
 *                 minLength: 6
 *                 example: "password123"
 *               phone:
 *                 type: string
 *                 example: "0912345678"
 *               role:
 *                 type: string
 *                 enum: [parent, child]
 *                 example: "parent"
 *               age:
 *                 type: number
 *                 description: Bắt buộc nếu vai trò là child, phải từ 6-17 tuổi
 *                 example: 12
 *     responses:
 *       201:
 *         description: Đăng ký thành công
 *       400:
 *         description: Lỗi xác thực hoặc thiếu thông tin
 *       409:
 *         description: Email đã được đăng ký
 */
router.post('/register', authController.register);

/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     summary: Đăng nhập
 *     tags: [Xác thực]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [email, password]
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 example: "user@example.com"
 *               password:
 *                 type: string
 *                 example: "password123"
 *               fcmToken:
 *                 type: string
 *                 description: Token Firebase để nhận thông báo đẩy (tùy chọn)
 *     responses:
 *       200:
 *         description: Đăng nhập thành công, trả về JWT token
 *       401:
 *         description: Email hoặc mật khẩu không chính xác
 *       403:
 *         description: Email chưa được xác thực
 */
router.post('/login', authController.login);

/**
 * @swagger
 * /api/auth/verify-email:
 *   get:
 *     summary: Xác thực email bằng token từ đường dẫn email
 *     tags: [Xác thực]
 *     parameters:
 *       - in: query
 *         name: token
 *         schema:
 *           type: string
 *         required: true
 *         description: Token xác thực từ email
 *     responses:
 *       200:
 *         description: Xác thực email thành công
 *       400:
 *         description: Token không hợp lệ hoặc đã hết hạn
 */
router.get('/verify-email', authController.verifyEmail);

/**
 * @swagger
 * /api/auth/resend-verification:
 *   post:
 *     summary: Gửi lại email xác thực
 *     tags: [Xác thực]
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
 *       200:
 *         description: Email xác thực đã được gửi lại
 *       404:
 *         description: Không tìm thấy tài khoản
 */
router.post('/resend-verification', authController.resendVerification);

/**
 * @swagger
 * /api/auth/forgot-password:
 *   post:
 *     summary: Gửi mã OTP đặt lại mật khẩu qua email hoặc SMS
 *     tags: [Xác thực]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [method]
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 description: Bắt buộc nếu phương thức là email
 *               phone:
 *                 type: string
 *                 description: Bắt buộc nếu phương thức là sms
 *               method:
 *                 type: string
 *                 enum: [email, sms]
 *     responses:
 *       200:
 *         description: Mã OTP đã được gửi thành công
 *       404:
 *         description: Không tìm thấy tài khoản
 */
router.post('/forgot-password', authController.forgotPassword);

/**
 * @swagger
 * /api/auth/reset-password:
 *   post:
 *     summary: Đặt lại mật khẩu bằng mã OTP
 *     tags: [Xác thực]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [otp, newPassword]
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *               phone:
 *                 type: string
 *               otp:
 *                 type: string
 *                 example: "123456"
 *               newPassword:
 *                 type: string
 *                 minLength: 6
 *     responses:
 *       200:
 *         description: Đặt lại mật khẩu thành công
 *       400:
 *         description: Mã OTP không hợp lệ hoặc đã hết hạn
 */
router.post('/reset-password', authController.resetPassword);

/**
 * @swagger
 * /api/auth/me:
 *   get:
 *     summary: Lấy thông tin tài khoản hiện tại (bao gồm tài khoản liên kết)
 *     tags: [Xác thực]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Thông tin hồ sơ người dùng
 *       404:
 *         description: Không tìm thấy tài khoản
 */
router.get('/me', auth, authController.getMe);

/**
 * @swagger
 * /api/auth/profile:
 *   get:
 *     summary: Lấy thông tin hồ sơ người dùng
 *     tags: [Xác thực]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Thông tin hồ sơ
 *       404:
 *         description: Không tìm thấy tài khoản
 *   put:
 *     summary: Cập nhật thông tin hồ sơ (họ tên và số điện thoại)
 *     tags: [Xác thực]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               fullName:
 *                 type: string
 *               phone:
 *                 type: string
 *     responses:
 *       200:
 *         description: Thông tin hồ sơ đã cập nhật
 *       400:
 *         description: Lỗi xác thực
 */
router.get('/profile', auth, authController.getProfile);
router.put('/profile', auth, authController.updateProfile);

/**
 * @swagger
 * /api/auth/link:
 *   post:
 *     summary: Liên kết tài khoản phụ huynh và trẻ em
 *     tags: [Xác thực]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               childEmail:
 *                 type: string
 *                 format: email
 *               targetUserId:
 *                 type: string
 *     responses:
 *       200:
 *         description: Tài khoản đã liên kết thành công
 *       403:
 *         description: Chỉ phụ huynh mới có thể liên kết tài khoản
 *       404:
 *         description: Không tìm thấy tài khoản trẻ em
 */
router.post('/link', auth, authController.linkAccounts);

/**
 * @swagger
 * /api/auth/update-fcm-token:
 *   post:
 *     summary: Cập nhật FCM token cho thông báo đẩy
 *     tags: [Xác thực]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [fcmToken]
 *             properties:
 *               fcmToken:
 *                 type: string
 *     responses:
 *       200:
 *         description: FCM token đã cập nhật
 */
router.post('/update-fcm-token', auth, authController.updateFCMToken);

/**
 * @swagger
 * /api/auth/location-settings:
 *   put:
 *     summary: Cập nhật cài đặt chia sẻ vị trí của trẻ em
 *     tags: [Xác thực]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               sharingEnabled:
 *                 type: boolean
 *               trackingInterval:
 *                 type: string
 *                 enum: [continuous, normal, battery-saver]
 *               pausedUntil:
 *                 type: string
 *                 format: date-time
 *     responses:
 *       200:
 *         description: Cài đặt vị trí đã cập nhật
 *       403:
 *         description: Chỉ trẻ em mới có thể cập nhật cài đặt vị trí
 */
router.put('/location-settings', auth, authController.updateLocationSettings);

module.exports = router;
