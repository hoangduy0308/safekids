const mongoose = require('mongoose');

const geofenceAlertSchema = new mongoose.Schema({
  geofenceId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Geofence', 
    required: true 
  },
  childId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  action: { 
    type: String, 
    enum: ['enter', 'exit'], 
    required: true 
  },
  location: {
    latitude: { 
      type: Number, 
      required: true 
    },
    longitude: { 
      type: Number, 
      required: true 
    }
  },
  timestamp: { 
    type: Date, 
    default: Date.now 
  },
  notified: { 
    type: Boolean, 
    default: false 
  }
});

geofenceAlertSchema.index({ childId: 1, timestamp: -1 });
geofenceAlertSchema.index({ timestamp: 1 }, { expireAfterSeconds: 7776000 }); // 90 days TTL

module.exports = mongoose.model('GeofenceAlert', geofenceAlertSchema);
