/**
 * Chat Routes - Việt hóa
 * @swagger
 * tags:
 *   name: Trò chuyện
 *   description: Nhắn tin giữa phụ huynh và trẻ em
 */

const router = require("express").Router();
const { auth } = require("../middleware/auth");
const chatController = require("../controllers/chat.controller");

/**
 * @swagger
 * /api/chat/conversations:
 *   get:
 *     summary: Lấy tất cả các cuộc trò chuyện
 *     tags: [Trò chuyện]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Mảng các cuộc trò chuyện
 *   post:
 *     summary: Lấy hoặc tạo cuộc trò chuyện với người dùng
 *     tags: [Trò chuyện]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [participantId]
 *             properties:
 *               participantId:
 *                 type: string
 *     responses:
 *       200:
 *         description: Chi tiết cuộc trò chuyện
 */
router.get("/conversations", auth, chatController.getConversations);
router.post("/conversations/:participantId", auth, chatController.getOrCreateConversation);

/**
 * @swagger
 * /api/chat/conversations/{conversationId}:
 *   get:
 *     summary: Lấy cuộc trò chuyện cụ thể
 *     tags: [Trò chuyện]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: conversationId
 *         schema:
 *           type: string
 *         required: true
 *     responses:
 *       200:
 *         description: Chi tiết cuộc trò chuyện
 */
router.get("/conversations/:conversationId", auth, chatController.getConversation);

/**
 * @swagger
 * /api/chat/conversations/{conversationId}/messages:
 *   get:
 *     summary: Lấy các tin nhắn trong cuộc trò chuyện
 *     tags: [Trò chuyện]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: conversationId
 *         schema:
 *           type: string
 *         required: true
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 50
 *       - in: query
 *         name: skip
 *         schema:
 *           type: integer
 *           default: 0
 *     responses:
 *       200:
 *         description: Mảng các tin nhắn
 *   post:
 *     summary: Gửi một tin nhắn
 *     tags: [Trò chuyện]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: conversationId
 *         schema:
 *           type: string
 *         required: true
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [content]
 *             properties:
 *               content:
 *                 type: string
 *               media:
 *                 type: array
 *                 items:
 *                   type: string
 *     responses:
 *       201:
 *         description: Tin nhắn đã được gửi
 */
router.get("/conversations/:conversationId/messages", auth, chatController.getMessages);
router.post("/conversations/:conversationId/messages", auth, chatController.sendMessage);

/**
 * @swagger
 * /api/chat/conversations/{conversationId}/mark-read:
 *   put:
 *     summary: Đánh dấu tin nhắn đã đọc
 *     tags: [Trò chuyện]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: conversationId
 *         schema:
 *           type: string
 *         required: true
 *     responses:
 *       200:
 *         description: Tin nhắn đã được đánh dấu đã đọc
 */
router.put("/conversations/:conversationId/mark-read", auth, chatController.markAsRead);

/**
 * @swagger
 * /api/chat/messages/{messageId}:
 *   delete:
 *     summary: Xóa một tin nhắn
 *     tags: [Trò chuyện]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: messageId
 *         schema:
 *           type: string
 *         required: true
 *     responses:
 *       200:
 *         description: Tin nhắn đã được xóa
 */
router.delete("/messages/:messageId", auth, chatController.deleteMessage);

/**
 * @swagger
 * /api/chat/conversations/{conversationId}/mute:
 *   put:
 *     summary: Tắt tiếng một cuộc trò chuyện
 *     tags: [Trò chuyện]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: conversationId
 *         schema:
 *           type: string
 *         required: true
 *     responses:
 *       200:
 *         description: Cuộc trò chuyện đã được tắt tiếng
 */
router.put("/conversations/:conversationId/mute", auth, chatController.muteConversation);

/**
 * @swagger
 * /api/chat/conversations/{conversationId}/unmute:
 *   put:
 *     summary: Bật tiếng một cuộc trò chuyện
 *     tags: [Trò chuyện]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: conversationId
 *         schema:
 *           type: string
 *         required: true
 *     responses:
 *       200:
 *         description: Cuộc trò chuyện đã được bật tiếng
 */
router.put("/conversations/:conversationId/unmute", auth, chatController.unmuteConversation);

module.exports = router;
