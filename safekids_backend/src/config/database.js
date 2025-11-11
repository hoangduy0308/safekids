/**
 * MongoDB Database Configuration
 */

const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });

    console.log(`âœ… MongoDB Connected: ${conn.connection.host}`);
    console.log(`ðŸ“¦ Database: ${conn.connection.name}`);

    // Handle connection events
    mongoose.connection.on('error', (err) => {
      console.error('âŒ MongoDB connection error:', err);
    });

    mongoose.connection.on('disconnected', () => {
      console.warn('âš ï¸  MongoDB disconnected. Attempting to reconnect...');
    });

    mongoose.connection.on('reconnected', () => {
      console.log('âœ… MongoDB reconnected!');
    });

  } catch (error) {
    console.error('âŒ MongoDB connection failed:', error.message);
    process.exit(1); // Exit process with failure
  }
};

module.exports = connectDB;
