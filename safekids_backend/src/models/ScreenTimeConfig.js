/**
 * Screen Time Configuration Model
 * Stores screen time limits and settings for each child
 */

const mongoose = require('mongoose');

const screenTimeConfigSchema = new mongoose.Schema({
  childId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Child ID is required'],
    unique: true
  },
  
  dailyLimit: {
    type: Number,
    required: [true, 'Daily limit is required'],
    min: [30, 'Daily limit must be at least 30 minutes'],
    max: [480, 'Daily limit must be at most 8 hours (480 minutes)'],
    default: 120 // 2 hours default
  },
  
  bedtimeEnabled: {
    type: Boolean,
    default: false
  },
  
  bedtimeStart: {
    type: String,
    required: true,
    validate: {
      validator: function(v) {
        // Validate HH:MM format
        return /^([01]?[0-9]|2[0-3]):[0-5][0-9]$/.test(v);
      },
      message: 'Time must be in HH:MM format'
    },
    default: '21:00'
  },
  
  bedtimeEnd: {
    type: String,
    required: true,
    validate: {
      validator: function(v) {
        return /^([01]?[0-9]|2[0-3]):[0-5][0-9]$/.test(v);
      },
      message: 'Time must be in HH:MM format'
    },
    default: '07:00'
  },
  
  // Parent notifications settings
  notifications: {
    limitReached: { type: Boolean, default: true },
    dailyReport: { type: Boolean, default: true },
    weeklyReport: { type: Boolean, default: false }
  },
  
  createdAt: {
    type: Date,
    default: Date.now
  },
  
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Update 'updatedAt' field before saving
screenTimeConfigSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

// Index for faster lookups
screenTimeConfigSchema.index({ childId: 1 });

module.exports = mongoose.model('ScreenTimeConfig', screenTimeConfigSchema);
