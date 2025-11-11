require('dotenv').config({ path: __dirname + '/../.env' });
const express = require('express');
const cors = require('cors');

// Routes
const authRoutes = require('./routes/auth.routes');
const linkRoutes = require('./routes/link.routes');
const locationRoutes = require('./routes/location.routes');
const geofenceRoutes = require('./routes/geofence.routes');
const sosRoutes = require('./routes/sos.routes');
const screentimeRoutes = require('./routes/screentime.routes');
const parentRoutes = require('./routes/parent.routes');
const chatRoutes = require('./routes/chat.routes');
const deviceRoutes = require('./routes/device.routes');

const app = express();

// CORS (permissive for tests/dev)
app.use(cors({ origin: true, credentials: true }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health
app.get('/health', (req, res) => {
  res.json({ status: 'OK', message: 'SafeKids App (app.js)', timestamp: new Date().toISOString() });
});

// API routes
app.use('/api/auth', authRoutes);
app.use('/api/link', linkRoutes);
app.use('/api/location', locationRoutes);
app.use('/api/geofence', geofenceRoutes);
app.use('/api/sos', sosRoutes);
app.use('/api/screentime', screentimeRoutes);
app.use('/api/parent', parentRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/device', deviceRoutes);

// 404
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err.stack);
  res.status(err.status || 500).json({ error: err.message || 'Internal Server Error' });
});

module.exports = app;
