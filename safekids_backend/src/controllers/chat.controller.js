/**
 * Chat Controller
 * Handles messaging between parent and child
 */

const Message = require("../models/Message");
const Conversation = require("../models/Conversation");
const User = require("../models/User");

/**
 * Get or create conversation between parent and child
 */
exports.getConversation = async (req, res) => {
  try {
    const { conversationId } = req.params;
    const userId = req.user._id;

    const conversation = await Conversation.findById(conversationId)
      .populate("parentId", "name email avatar role")
      .populate("childId", "name email avatar role");

    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: "Conversation not found",
      });
    }

    // Verify user is part of this conversation
    if (
      conversation.parentId._id.toString() !== userId &&
      conversation.childId._id.toString() !== userId
    ) {
      return res.status(403).json({
        success: false,
        message: "Not authorized to access this conversation",
      });
    }

    res.status(200).json({
      success: true,
      data: conversation,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * Get or create conversation with specific user
 */
exports.getOrCreateConversation = async (req, res) => {
  try {
    const { participantId } = req.params;
    const userId = req.user._id;

    // Verify participant exists and is linked
    const participant = await User.findById(participantId);
    if (!participant) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      });
    }

    // Check if users are linked (parent-child relationship)
    const user = await User.findById(userId).populate('linkedChildren').populate('linkedParents');
    
    console.log(`[Chat] User ${userId} linkedChildren:`, user.linkedChildren?.map(c => c._id || c));
    console.log(`[Chat] User ${userId} linkedParents:`, user.linkedParents?.map(p => p._id || p));
    console.log(`[Chat] Checking if participant ${participantId} is linked`);
    
    // Check if participant is in linkedChildren or linkedParents
    // Convert both to string for comparison
    const participantIdStr = participantId.toString();
    const isLinked = 
      user.linkedChildren?.some((id) => {
        const idStr = id._id ? id._id.toString() : id.toString();
        return idStr === participantIdStr;
      }) ||
      user.linkedParents?.some((id) => {
        const idStr = id._id ? id._id.toString() : id.toString();
        return idStr === participantIdStr;
      });

    console.log(`[Chat] isLinked: ${isLinked}`);

    if (!isLinked) {
      return res.status(403).json({
        success: false,
        message: "Users are not linked",
      });
    }

    // Find or create conversation
    let conversation;
    const query = {
      $or: [
        { parentId: userId, childId: participantId },
        { parentId: participantId, childId: userId },
      ],
    };

    conversation = await Conversation.findOne(query)
      .populate("parentId", "name email avatar role")
      .populate("childId", "name email avatar role");

    if (!conversation) {
      // Determine who is parent and who is child based on roles
      const userRole = user.role;
      const participantRole = participant.role;

      let parentId, childId;
      if (userRole === "parent" && participantRole === "child") {
        parentId = userId;
        childId = participantId;
      } else if (userRole === "child" && participantRole === "parent") {
        parentId = participantId;
        childId = userId;
      } else {
        return res.status(400).json({
          success: false,
          message: "Invalid user roles for conversation",
        });
      }

      conversation = await Conversation.create({
        parentId,
        childId,
      });

      console.log(`[Chat] Created new conversation:`, conversation._id);

      conversation = await conversation
        .populate("parentId", "name email avatar role")
        .populate("childId", "name email avatar role");
    }

    console.log(`[Chat] Returning conversation:`, {
      _id: conversation._id,
      parentId: conversation.parentId._id || conversation.parentId,
      childId: conversation.childId._id || conversation.childId,
    });

    res.status(200).json({
      success: true,
      data: conversation,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * Get all conversations for user
 */
exports.getConversations = async (req, res) => {
  try {
    const userId = req.user._id;

    const conversations = await Conversation.find({
      $or: [{ parentId: userId }, { childId: userId }],
    })
      .populate("parentId", "name email avatar role")
      .populate("childId", "name email avatar role")
      .populate("lastMessage")
      .sort({ updatedAt: -1 });

    // Add other user info for frontend
    const enrichedConversations = conversations.map((conv) => ({
      ...conv.toObject(),
      otherUser:
        conv.parentId._id.toString() === userId ? conv.childId : conv.parentId,
    }));

    res.status(200).json({
      success: true,
      data: enrichedConversations,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * Get messages in conversation
 */
exports.getMessages = async (req, res) => {
  try {
    const { conversationId } = req.params;
    const { limit = 50, skip = 0 } = req.query;
    const userId = req.user._id;

    // Verify user is part of conversation
    const conversation = await Conversation.findById(conversationId);
    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: "Conversation not found",
      });
    }

    // Convert to string for comparison
    const userIdStr = userId.toString();
    const parentIdStr = conversation.parentId.toString();
    const childIdStr = conversation.childId.toString();
    
    console.log(`[Chat] getMessages - userIdStr: ${userIdStr}, parentId: ${parentIdStr}, childId: ${childIdStr}`);

    if (userIdStr !== parentIdStr && userIdStr !== childIdStr) {
      return res.status(403).json({
        success: false,
        message: "Not authorized",
      });
    }

    const messages = await Message.find({
      conversationId,
      isDeleted: false,
    })
      .populate("senderId", "name email avatar role")
      .populate("receiverId", "name email avatar role")
      .populate("replyTo")
      .sort({ createdAt: -1 })
      .limit(parseInt(limit))
      .skip(parseInt(skip));

    const total = await Message.countDocuments({
      conversationId,
      isDeleted: false,
    });

    res.status(200).json({
      success: true,
      data: messages.reverse(),
      pagination: {
        total,
        skip: parseInt(skip),
        limit: parseInt(limit),
        hasMore: skip + limit < total,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * Send message
 */
exports.sendMessage = async (req, res) => {
  try {
    const { conversationId, content, images } = req.body;
    const senderId = req.user._id;

    // Validate
    if (!conversationId) {
      return res.status(400).json({
        success: false,
        message: "Conversation ID is required",
      });
    }

    if (!content && (!images || images.length === 0)) {
      return res.status(400).json({
        success: false,
        message: "Message content or images are required",
      });
    }

    // Get conversation
    const conversation = await Conversation.findById(conversationId);
    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: "Conversation not found",
      });
    }

    // Verify sender is part of conversation
    const senderIdStr = senderId.toString();
    const parentIdStr = conversation.parentId.toString();
    const childIdStr = conversation.childId.toString();
    
    if (senderIdStr !== parentIdStr && senderIdStr !== childIdStr) {
      return res.status(403).json({
        success: false,
        message: "Not authorized",
      });
    }

    // Determine receiver
    const receiverId =
      conversation.parentId.toString() === senderId
        ? conversation.childId
        : conversation.parentId;

    // Create message
    const message = await Message.create({
      conversationId,
      senderId,
      receiverId,
      content,
      images: images || [],
    });

    // Populate sender/receiver info
    await message.populate("senderId", "name email avatar role");
    await message.populate("receiverId", "name email avatar role");

    // Update conversation
    await Conversation.findByIdAndUpdate(conversationId, {
      lastMessage: message._id,
      lastMessageText: content || `📷 (${images?.length || 1} image)`,
      lastMessageTime: message.createdAt,
      updatedAt: new Date(),
    });

    // Increment unread count for receiver
    const receiverIsParent = conversation.parentId.toString() === receiverId;
    await Conversation.findByIdAndUpdate(conversationId, {
      $inc: {
        [receiverIsParent ? "unreadCount.parent" : "unreadCount.child"]: 1,
      },
    });

    res.status(201).json({
      success: true,
      data: message,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * Mark messages as read
 */
exports.markAsRead = async (req, res) => {
  try {
    const { conversationId } = req.params;
    const userId = req.user._id;

    const conversation = await Conversation.findById(conversationId);
    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: "Conversation not found",
      });
    }

    // Update unread messages
    await Message.updateMany(
      {
        conversationId,
        receiverId: userId,
        isRead: false,
      },
      {
        isRead: true,
        readAt: new Date(),
      }
    );

    // Reset unread count
    const isParent = conversation.parentId.toString() === userId;
    await Conversation.findByIdAndUpdate(conversationId, {
      $set: {
        [isParent ? "unreadCount.parent" : "unreadCount.child"]: 0,
      },
    });

    res.status(200).json({
      success: true,
      message: "Messages marked as read",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * Delete message
 */
exports.deleteMessage = async (req, res) => {
  try {
    const { messageId } = req.params;
    const userId = req.user._id;

    const message = await Message.findById(messageId);
    if (!message) {
      return res.status(404).json({
        success: false,
        message: "Message not found",
      });
    }

    // Only sender or receiver can delete
    if (
      message.senderId.toString() !== userId &&
      message.receiverId.toString() !== userId
    ) {
      return res.status(403).json({
        success: false,
        message: "Not authorized",
      });
    }

    // Soft delete
    message.isDeleted = true;
    message.deletedAt = new Date();
    message.deletedBy = userId;
    await message.save();

    res.status(200).json({
      success: true,
      message: "Message deleted",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * Mute conversation
 */
exports.muteConversation = async (req, res) => {
  try {
    const { conversationId } = req.params;
    const userId = req.user._id;

    const conversation = await Conversation.findById(conversationId);
    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: "Conversation not found",
      });
    }

    const isParent = conversation.parentId.toString() === userId;
    await Conversation.findByIdAndUpdate(conversationId, {
      $set: {
        [isParent ? "isMuted.parent" : "isMuted.child"]: true,
      },
    });

    res.status(200).json({
      success: true,
      message: "Conversation muted",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

/**
 * Unmute conversation
 */
exports.unmuteConversation = async (req, res) => {
  try {
    const { conversationId } = req.params;
    const userId = req.user._id;

    const conversation = await Conversation.findById(conversationId);
    if (!conversation) {
      return res.status(404).json({
        success: false,
        message: "Conversation not found",
      });
    }

    const isParent = conversation.parentId.toString() === userId;
    await Conversation.findByIdAndUpdate(conversationId, {
      $set: {
        [isParent ? "isMuted.parent" : "isMuted.child"]: false,
      },
    });

    res.status(200).json({
      success: true,
      message: "Conversation unmuted",
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
