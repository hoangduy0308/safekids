/**
 * User Model
 * Represents both Parent and Child users
 */

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  // Basic Info
  fullName: {
    type: String,
    trim: true,
    minlength: [2, 'Full name must be at least 2 characters']
  },
  
  // Keep 'name' field for backward compatibility and primary
  name: {
    type: String,
    required: [true, 'Name is required'],
    trim: true,
    minlength: [2, 'Name must be at least 2 characters']
  },
  
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^\S+@\S+\.\S+$/, 'Please provide a valid email']
  },
  
  username: {
    type: String,
    unique: true,
    sparse: true,
    lowercase: true,
    trim: true,
    minlength: [3, 'Username must be at least 3 characters']
  },
  
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: [6, 'Password must be at least 6 characters'],
    select: false // Don't return password by default in queries
  },
  
  phone: {
    type: String,
    required: [true, 'Phone number is required'],
    trim: true
  },
  
  // Role: parent or child
  role: {
    type: String,
    enum: ['parent', 'child'],
    required: [true, 'Role is required']
  },
  
  // Child-specific field
  age: {
    type: Number,
    min: [6, 'Age must be at least 6'],
    max: [17, 'Age must be at most 17'],
    required: function() {
      return this.role === 'child';
    }
  },
  
  // Avatar URL (optional)
  avatar: {
    type: String,
    default: null
  },
  
  // FCM Token for push notifications
  fcmToken: {
    type: String,
    default: null
  },
  
  // Linked users (parent-child relationships)
  linkedUsers: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  
  // Parent-specific: linked children
  linkedChildren: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  
  // Child-specific: linked parents
  linkedParents: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  
  // Location Settings (Task 2.5)
  locationSettings: {
    sharingEnabled: {
      type: Boolean,
      default: true
    },
    trackingInterval: {
      type: String,
      enum: ['continuous', 'normal', 'battery-saver'],
      default: 'continuous'
    },
    pausedUntil: {
      type: Date,
      default: null
    }
  },
  
  // Account status
  isActive: {
    type: Boolean,
    default: true
  },
  
  // Email verification
  isEmailVerified: {
    type: Boolean,
    default: false
  },
  
  emailVerificationToken: {
    type: String,
    select: false
  },
  
  emailVerificationExpires: {
    type: Date
  },
  
  // Password reset - OTP
  resetPasswordOTP: {
    type: String,
    select: false
  },
  
  resetPasswordExpires: {
    type: Date
  },
  
  resetPasswordMethod: {
    type: String,
    enum: {
      values: ['email', 'sms'],
      message: '{VALUE} is not a valid reset method'
    },
    required: false
  },
  
  // Timestamps
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

// ========== MIDDLEWARE ==========

// Hash password before saving
userSchema.pre('save', async function(next) {
  // Only hash if password is modified
  if (!this.isModified('password')) {
    return next();
  }
  
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Update 'updatedAt' field before saving
userSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

// ========== METHODS ==========

// Compare password for login
userSchema.methods.comparePassword = async function(candidatePassword) {
  try {
    return await bcrypt.compare(candidatePassword, this.password);
  } catch (error) {
    throw new Error('Password comparison failed');
  }
};

// Note: fullName is now a real field, no need for virtual

// Get public profile (without sensitive data)
userSchema.methods.toPublicJSON = function() {
  return {
    id: this._id,
    name: this.name,
    username: this.username,
    fullName: this.fullName || this.name,
    email: this.email,
    phone: this.phone,
    role: this.role,
    age: this.age,
    avatar: this.avatar,
    linkedUsers: this.linkedUsers,
    isActive: this.isActive,
    locationSettings: this.locationSettings,
    createdAt: this.createdAt
  };
};

// ========== INDEXES ==========
userSchema.index({ email: 1 });
userSchema.index({ username: 1 }, { sparse: true });
userSchema.index({ role: 1 });
userSchema.index({ linkedUsers: 1 });

module.exports = mongoose.model('User', userSchema);
