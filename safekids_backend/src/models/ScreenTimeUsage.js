/**
 * Screen Time Usage Model
 * Tracks daily screen time usage for each child
 */

const mongoose = require('mongoose');

const sessionSchema = new mongoose.Schema({
  startTime: {
    type: Date,
    required: true
  },
  endTime: {
    type: Date,
    required: true
  },
  duration: {
    type: Number, // duration in minutes
    required: true,
    min: 0
  },
  app: {
    type: String,
    required: true
  },
  appPackage: {
    type: String,
    required: true
  }
}, { _id: false });

const screenTimeUsageSchema = new mongoose.Schema({
  childId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'Child ID is required']
  },
  
  date: {
    type: String,
    required: [true, 'Date is required'],
    validate: {
      validator: function(v) {
        // Validate YYYY-MM-DD format
        return /^\d{4}-\d{2}-\d{2}$/.test(v);
      },
      message: 'Date must be in YYYY-MM-DD format'
    }
  },
  
  totalMinutes: {
    type: Number,
    required: [true, 'Total minutes is required'],
    min: 0,
    default: 0
  },
  
  sessions: {
    type: [sessionSchema],
    default: []
  },
  
  // App-wise usage breakdown
  appUsage: [{
    app: { type: String, required: true },
    appPackage: { type: String, required: true },
    totalMinutes: { type: Number, required: true, min: 0 },
    sessionCount: { type: Number, required: true, min: 0 }
  }],
  
  // Time of day breakdown (hourly)
  hourlyUsage: [{
    hour: { type: Number, min: 0, max: 23, required: true },
    minutes: { type: Number, min: 0, required: true }
  }],
  
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

// Compound index for unique child-date combination
screenTimeUsageSchema.index({ childId: 1, date: 1 }, { unique: true });

// Update 'updatedAt' field before saving
screenTimeUsageSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

// Static method to calculate app usage from sessions
screenTimeUsageSchema.statics.calculateAppUsage = function(sessions) {
  const appMap = new Map();
  
  sessions.forEach(session => {
    const app = session.app;
    const appPackage = session.appPackage;
    const duration = session.duration;
    
    if (appMap.has(appPackage)) {
      const existing = appMap.get(appPackage);
      existing.totalMinutes += duration;
      existing.sessionCount += 1;
    } else {
      appMap.set(appPackage, {
        app,
        appPackage,
        totalMinutes: duration,
        sessionCount: 1
      });
    }
  });
  
  return Array.from(appMap.values());
};

// Static method to calculate hourly usage from sessions
screenTimeUsageSchema.statics.calculateHourlyUsage = function(sessions) {
  const hourlyData = Array.from({ length: 24 }, (_, i) => ({
    hour: i,
    minutes: 0
  }));
  
  sessions.forEach(session => {
    const startHour = new Date(session.startTime).getHours();
    const endHour = new Date(session.endTime).getHours();
    
    // Simple approximation: add full duration to start hour
    if (startHour >= 0 && startHour < 24) {
      hourlyData[startHour].minutes += session.duration;
    }
  });
  
  return hourlyData.filter(hour => hour.minutes > 0);
};

// Instance method to recalculate totals from sessions
screenTimeUsageSchema.methods.recalculateFromSessions = function() {
  // Calculate total minutes from sessions
  this.totalMinutes = this.sessions.reduce((sum, session) => sum + session.duration, 0);
  
  // Calculate app usage
  this.appUsage = this.constructor.calculateAppUsage(this.sessions);
  
  // Calculate hourly usage
  this.hourlyUsage = this.constructor.calculateHourlyUsage(this.sessions);
  
  return this;
};

module.exports = mongoose.model('ScreenTimeUsage', screenTimeUsageSchema);
