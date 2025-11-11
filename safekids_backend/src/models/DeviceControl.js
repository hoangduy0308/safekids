const mongoose = require('mongoose');

const deviceControlSchema = new mongoose.Schema(
  {
    childId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
    },
    isLocked: {
      type: Boolean,
      default: false,
    },
    lockedAt: Date,
    lockedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    unlockedAt: Date,
    unlockedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    },
    lockReason: String,
    screenOffAt: Date,
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('DeviceControl', deviceControlSchema);
