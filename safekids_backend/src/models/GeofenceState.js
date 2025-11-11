const mongoose = require('mongoose');

const geofenceStateSchema = new mongoose.Schema({
  childId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  geofenceId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Geofence', 
    required: true 
  },
  isInside: { 
    type: Boolean, 
    required: true 
  },
  lastCheck: { 
    type: Date, 
    default: Date.now 
  }
});

geofenceStateSchema.index({ childId: 1, geofenceId: 1 }, { unique: true });

module.exports = mongoose.model('GeofenceState', geofenceStateSchema);
