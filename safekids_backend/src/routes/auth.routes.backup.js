/**
 * Authentication Routes
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
 *                 example: "Nguyen Van A"
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
 *                 description: Required if role is 'child', must be 6-17
 *                 example: 12
 *     responses:
 *       201:
 *         description: User registered successfully
 *       400:
 *         description: Validation error or missing fields
 *       409:
 *         description: Email already registered
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
 *                 description: Optional Firebase Cloud Messaging token for push notifications
 *     responses:
 *       200:
 *         description: Login successful, returns JWT token
 *       401:
 *         description: Invalid email or password
 *       403:
 *         description: Email not verified
 */
router.post('/login', authController.login);

/**
 * @swagger
 * /api/auth/verify-email:
 *   get:
 *     summary: Verify email with token from email link
 *     tags: [Authentication]
 *     parameters:
 *       - in: query
 *         name: token
 *         schema:
 *           type: string
 *         required: true
 *         description: Verification token from email
 *     responses:
 *       200:
 *         description: Email verified successfully
 *       400:
 *         description: Invalid or expired token
 */
router.get('/verify-email', authController.verifyEmail);

/**
 * @swagger
 * /api/auth/resend-verification:
 *   post:
 *     summary: Resend verification email
 *     tags: [Authentication]
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
 *         description: Verification email resent
 *       404:
 *         description: User not found
 */
router.post('/resend-verification', authController.resendVerification);

/**
 * @swagger
 * /api/auth/forgot-password:
 *   post:
 *     summary: Send password reset OTP via email or SMS
 *     tags: [Authentication]
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
 *                 description: Required if method is 'email'
 *               phone:
 *                 type: string
 *                 description: Required if method is 'sms'
 *               method:
 *                 type: string
 *                 enum: [email, sms]
 *     responses:
 *       200:
 *         description: OTP sent successfully
 *       404:
 *         description: User not found
 */
router.post('/forgot-password', authController.forgotPassword);

/**
 * @swagger
 * /api/auth/reset-password:
 *   post:
 *     summary: Reset password with OTP
 *     tags: [Authentication]
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
 *         description: Password reset successfully
 *       400:
 *         description: Invalid or expired OTP
 */
router.post('/reset-password', authController.resetPassword);

/**
 * @swagger
 * /api/auth/me:
 *   get:
 *     summary: Get current user profile with linked accounts
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User profile returned
 *       404:
 *         description: User not found
 */
router.get('/me', auth, authController.getMe);

/**
 * @swagger
 * /api/auth/profile:
 *   get:
 *     summary: Get user profile
 *     tags: [Authentication]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: User profile
 *       404:
 *         description: User not found
 */
router.get('/profile', auth, authController.getProfile);

/**
 * @swagger
 * /api/auth/profile:
 *   put:
 *     summary: Update user profile (fullName and phone only)
 *     tags: [Authentication]
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
 *         description: Profile updated
 *       400:
 *         description: Validation error
 */
router.put('/profile', auth, authController.updateProfile);

/**
 * @swagger
 * /api/auth/link:
 *   post:
 *     summary: Link parent and child accounts
 *     tags: [Authentication]
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
 *         description: Accounts linked successfully
 *       403:
 *         description: Only parent can link accounts
 *       404:
 *         description: Child account not found
 */
router.post('/link', auth, authController.linkAccounts);

/**
 * @swagger
 * /api/auth/update-fcm-token:
 *   post:
 *     summary: Update FCM token for push notifications
 *     tags: [Authentication]
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
 *         description: FCM token updated
 */
router.post('/update-fcm-token', auth, authController.updateFCMToken);

/**
 * @swagger
 * /api/auth/location-settings:
 *   put:
 *     summary: Update child's location sharing settings
 *     tags: [Authentication]
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
 *         description: Location settings updated
 *       403:
 *         description: Only child users can update location settings
 */
router.put('/location-settings', auth, authController.updateLocationSettings);

module.exports = router;
