const mongoose = require('mongoose');

const linkRequestSchema = new mongoose.Schema({
  sender: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  receiver: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  status: {
    type: String,
    enum: ['pending', 'accepted', 'rejected'],
    default: 'pending',
    index: true
  },
  type: {
    type: String,
    enum: ['parent_to_child', 'child_to_parent'],
    required: true
  },
  message: {
    type: String,
    maxlength: 200
  }
}, {
  timestamps: true
});

// Compound indexes
linkRequestSchema.index({ receiver: 1, status: 1 });
linkRequestSchema.index({ sender: 1, receiver: 1 });

// Prevent duplicate pending requests
linkRequestSchema.index(
  { sender: 1, receiver: 1, status: 1 },
  { unique: true, partialFilterExpression: { status: 'pending' } }
);

module.exports = mongoose.model('LinkRequest', linkRequestSchema);
