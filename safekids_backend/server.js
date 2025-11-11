/**
 * SafeKids Backend Server
 * Main entry point for the application
 */

require('dotenv').config({ path: __dirname + '/.env' });
const express = require('express');
const cors = require('cors');
const http = require('http');
const { Server } = require('socket.io');
const path = require('path');
const admin = require('firebase-admin');
const swaggerUi = require('swagger-ui-express');
const swaggerSpec = require('./src/config/swagger');
const connectDB = require('./src/config/database');
const socketService = require('./src/services/socket.service');
const notificationService = require('./src/services/notification.service');
const emailService = require('./src/services/email.service');
const smsService = require('./src/services/sms.service');

// Initialize Firebase Admin SDK
try {
  const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
  const serviceAccount = require(serviceAccountPath);
  
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: serviceAccount.project_id,
  });
  
  console.log('✅ Firebase Admin SDK initialized');
} catch (error) {
  console.warn('⚠️ Firebase Admin SDK not initialized:', error.message);
  console.warn('   Notifications will use console fallback mode');
}

// Import routes
const authRoutes = require('./src/routes/auth.routes');
const linkRoutes = require('./src/routes/link.routes');
const locationRoutes = require('./src/routes/location.routes');
const geofenceRoutes = require('./src/routes/geofence.routes');
const sosRoutes = require('./src/routes/sos.routes');
const screentimeRoutes = require('./src/routes/screentime.routes');
const parentRoutes = require('./src/routes/parent.routes');
const chatRoutes = require('./src/routes/chat.routes');
const deviceRoutes = require('./src/routes/device.routes');

// Initialize Express app
const app = express();
const server = http.createServer(app);

// Initialize Socket.IO
const io = new Server(server, {
  cors: {
    origin: process.env.FRONTEND_URL || '*',
    methods: ['GET', 'POST'],
    credentials: true
  }
});

// Connect to MongoDB
connectDB();

// Middleware
// CORS config để support cả Azure và ngrok URLs
const corsOptions = {
  origin: function (origin, callback) {
    // Allow requests with no origin (mobile apps, Postman, etc.)
    if (!origin) return callback(null, true);
    
    const allowedOrigins = [
      'http://localhost:3000',
      'http://localhost:8080',
      process.env.FRONTEND_URL,
      process.env.AZURE_URL,
    ];
    
    // Allow all ngrok URLs for development
    if (origin.includes('ngrok') || origin.includes('ngrok-free.app')) {
      return callback(null, true);
    }
    
    if (allowedOrigins.indexOf(origin) !== -1 || !origin) {
      callback(null, true);
    } else {
      callback(null, true); // Be permissive during development
    }
  },
  credentials: true
};

app.use(cors(corsOptions));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Swagger Documentation
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
  swaggerOptions: {
    persistAuthorization: true,
    displayRequestDuration: true
  },
  customCss: '.swagger-ui .topbar { display: none }'
}));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'SafeKids Backend is running!',
    timestamp: new Date().toISOString()
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/link', linkRoutes);
app.use('/api/location', locationRoutes);
app.use('/api/geofence', geofenceRoutes);
app.use('/api/sos', sosRoutes);
app.use('/api/screentime', screentimeRoutes);
app.use('/api/parent', parentRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/device', deviceRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('Error:', err.stack);
  res.status(err.status || 500).json({
    error: err.message || 'Internal Server Error',
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
});

// Initialize Socket.IO service
socketService.initialize(io);

// Make socketService available to controllers
app.set('socketService', socketService);

// Initialize Notification service
notificationService.initialize();

// Make notificationService available to controllers
app.set('notificationService', notificationService);

// Initialize Email service (Gmail SMTP)
emailService.init();

// Initialize SMS service (Twilio)
smsService.init();

// Start server (skip auto-listen during tests)
const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';

if (process.env.NODE_ENV === 'test') {
  if (process.env.START_SERVER === 'true') {
    server.listen(PORT, HOST, () => {
      console.log(`🚀 SafeKids Backend running on ${HOST}:${PORT}`);
      console.log(`📡 Socket.IO ready for real-time connections`);
      console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
    });
  }
} else {
  server.listen(PORT, HOST, () => {
    console.log(`🚀 SafeKids Backend running on ${HOST}:${PORT}`);
    console.log(`📡 Socket.IO ready for real-time connections`);
    console.log(`🌍 Environment: ${process.env.NODE_ENV || 'development'}`);
    if (process.env.NODE_ENV === 'development') {
      console.log(`💡 For ngrok: Run 'ngrok http ${PORT}' in another terminal`);
    }
  });
}

module.exports = { app, server, io };
