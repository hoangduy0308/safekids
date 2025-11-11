/**
 * Conversation Model
 * Represents a chat conversation between parent and child
 */

const mongoose = require("mongoose");

const conversationSchema = new mongoose.Schema(
  {
    parentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: [true, "Parent ID is required"],
      index: true,
    },

    childId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: [true, "Child ID is required"],
      index: true,
    },

    lastMessage: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Message",
      default: null,
    },

    lastMessageText: {
      type: String,
      default: "",
    },

    lastMessageTime: {
      type: Date,
      default: null,
    },

    unreadCount: {
      parent: {
        type: Number,
        default: 0,
      },
      child: {
        type: Number,
        default: 0,
      },
    },

    isPinned: {
      type: Boolean,
      default: false,
    },

    isMuted: {
      parent: {
        type: Boolean,
        default: false,
      },
      child: {
        type: Boolean,
        default: false,
      },
    },

    createdAt: {
      type: Date,
      default: Date.now,
      index: true,
    },

    updatedAt: {
      type: Date,
      default: Date.now,
    },
  },
  {
    timestamps: true,
  }
);

// Unique compound index - only one conversation per parent-child pair
conversationSchema.index({ parentId: 1, childId: 1 }, { unique: true });

// Index for getting all conversations for a user
conversationSchema.index({ parentId: 1, updatedAt: -1 });
conversationSchema.index({ childId: 1, updatedAt: -1 });

module.exports = mongoose.model("Conversation", conversationSchema);
