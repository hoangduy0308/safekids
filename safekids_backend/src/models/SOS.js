/**
 * SOS Emergency Alert Model
 * Represents emergency alerts sent by children
 */

const mongoose = require("mongoose");

const sosSchema = new mongoose.Schema(
  {
    childId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: [true, "Child ID is required"],
      index: true,
    },

    location: {
      latitude: {
        type: Number,
        required: [true, "Latitude is required"],
        min: -90,
        max: 90,
      },
      longitude: {
        type: Number,
        required: [true, "Longitude is required"],
        min: -180,
        max: 180,
      },
      accuracy: {
        type: Number,
        default: null,
      },
    },

    timestamp: {
      type: Date,
      required: [true, "Timestamp is required"],
      default: Date.now,
    },

    status: {
      type: String,
      enum: ["active", "resolved", "false_alarm"],
      default: "active",
      index: true,
    },

    batteryLevel: {
      type: Number,
      min: 0,
      max: 100,
    },

    networkStatus: {
      type: String,
      enum: ["wifi", "mobile", "unknown"],
      default: "unknown",
    },

    photoUrl: {
      type: String,
      default: null,
    },

    audioUrl: {
      type: String,
      default: null,
    },

    resolvedAt: {
      type: Date,
      default: null,
    },

    resolvedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
    },

    notes: {
      type: String,
      default: null,
    },

    // False alarm tracking (Story 4.4)
    falseAlarmReason: {
      type: String,
      enum: ["accidental", "test", "other", "Not specified", null],
      default: null,
    },

    markedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
    },

    markedAt: {
      type: Date,
      default: null,
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

// Compound index for querying active SOS alerts
sosSchema.index({ childId: 1, status: 1, createdAt: -1 });

// Virtual for display name
sosSchema.virtual("displayStatus").get(function () {
  const statusMap = {
    active: "🚨 Đang hoạt động",
    resolved: "✅ Đã xử lý",
    false_alarm: "⚠️ Cảnh báo giả",
  };
  return statusMap[this.status] || this.status;
});

module.exports = mongoose.model("SOS", sosSchema);
