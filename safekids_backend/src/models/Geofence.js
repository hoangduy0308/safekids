const mongoose = require('mongoose');

const geofenceSchema = new mongoose.Schema({
  parentId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  
  name: {
    type: String,
    required: [true, 'Tên vùng là bắt buộc'],
    maxlength: [50, 'Tên vùng không vượt quá 50 ký tự'],
    trim: true
  },
  
  type: {
    type: String,
    enum: ['safe', 'danger'],
    required: [true, 'Loại vùng là bắt buộc']
  },
  
  center: {
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
  
  radius: {
    type: Number,
    required: true,
    min: [50, 'Bán kính tối thiểu là 50m'],
    max: [1000, 'Bán kính tối đa là 1000m']
  },
  
  activeHours: {
    start: String,
    end: String,
    _id: false
  },
  
  linkedChildren: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  
  createdAt: {
    type: Date,
    default: Date.now,
    index: true
  },
  
  updatedAt: {
    type: Date,
    default: Date.now
  },
  
  active: {
    type: Boolean,
    default: true,
    index: true
  }
}, {
  timestamps: true
});

// Compound index for efficient queries
geofenceSchema.index({ parentId: 1, linkedChildren: 1 });

module.exports = mongoose.model('Geofence', geofenceSchema);
