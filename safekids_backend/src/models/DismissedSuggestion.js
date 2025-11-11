const mongoose = require('mongoose');

const dismissedSuggestionSchema = new mongoose.Schema({
  parentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  childId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  location: {
    latitude: {
      type: Number,
      required: true,
      min: -90,
      max: 90
    },
    longitude: {
      type: Number,
      required: true,
      min: -180,
      max: 180
    }
  },
  dismissedAt: {
    type: Date,
    default: Date.now,
    index: true
  }
});

// Compound index for efficient queries
dismissedSuggestionSchema.index({ parentId: 1, childId: 1 });

// TTL index: auto-delete after 90 days
dismissedSuggestionSchema.index({ dismissedAt: 1 }, { expireAfterSeconds: 90 * 24 * 60 * 60 });

module.exports = mongoose.model('DismissedSuggestion', dismissedSuggestionSchema);
