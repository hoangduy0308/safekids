/**
 * Socket.IO Service
 * Handles real-time communication between parent and child apps
 */

let io;
const connectedUsers = new Map(); // Map userId to socketId

/**
 * Initialize Socket.IO
 */
exports.initialize = (socketIO) => {
  io = socketIO;
  
  io.on('connection', (socket) => {
    console.log(`[Socket] Client connected: ${socket.id}`);
    
    // Auto-register parent user from auth handshake
    const userId = socket.handshake.auth?.userId;
    if (userId) {
      connectedUsers.set(userId, socket.id);
      console.log(`[Socket] User ${userId} auto-registered (from handshake)`);
      console.log(`[Socket] Total connected users: ${connectedUsers.size}`);
    }
    
    // Handle user registration (fallback for client-side register event)
    socket.on('register', (userId) => {
      connectedUsers.set(userId, socket.id);
      console.log(`[Socket] User ${userId} registered (from event)`);
      console.log(`[Socket] Total connected users: ${connectedUsers.size}`);
    });
    
    // Handle location updates from child
    socket.on('locationUpdate', (data) => {
      const { childId, parentIds, location } = data;
      
      // Broadcast to all linked parents
      if (parentIds && Array.isArray(parentIds)) {
        parentIds.forEach(parentId => {
          const parentSocketId = connectedUsers.get(parentId);
          if (parentSocketId) {
            io.to(parentSocketId).emit('childLocationUpdate', {
              childId,
              location,
              timestamp: new Date()
            });
          }
        });
      }
    });
    
    // Handle geofence alerts
    socket.on('geofenceAlert', (data) => {
      const { childId, parentIds, geofence, alertType } = data;
      
      // Notify parents
      if (parentIds && Array.isArray(parentIds)) {
        parentIds.forEach(parentId => {
          const parentSocketId = connectedUsers.get(parentId);
          if (parentSocketId) {
            io.to(parentSocketId).emit('geofenceAlert', {
              childId,
              geofence,
              alertType, // 'entered' or 'exited'
              timestamp: new Date()
            });
          }
        });
      }
    });
    
    // Handle SOS alerts
    socket.on('sosAlert', (data) => {
      const { childId, parentIds, location } = data;
      
      // Critical: Notify all parents immediately
      if (parentIds && Array.isArray(parentIds)) {
        parentIds.forEach(parentId => {
          const parentSocketId = connectedUsers.get(parentId);
          if (parentSocketId) {
            io.to(parentSocketId).emit('sosAlert', {
              childId,
              location,
              timestamp: new Date(),
              priority: 'critical'
            });
          }
        });
      }
    });
    
    // Handle screen time warnings
    socket.on('screentimeWarning', (data) => {
      const { childId, parentIds, usage, limit } = data;
      
      // Notify parents
      if (parentIds && Array.isArray(parentIds)) {
        parentIds.forEach(parentId => {
          const parentSocketId = connectedUsers.get(parentId);
          if (parentSocketId) {
            io.to(parentSocketId).emit('screentimeWarning', {
              childId,
              usage,
              limit,
              percentage: (usage / limit) * 100,
              timestamp: new Date()
            });
          }
        });
      }
    });

    // Handle chat messages
    socket.on('chatMessage', (data) => {
      const { conversationId, receiverId, message } = data;
      const receiverSocketId = connectedUsers.get(receiverId);
      
      if (receiverSocketId) {
        io.to(receiverSocketId).emit('newMessage', {
          conversationId,
          message,
          timestamp: new Date()
        });
      }
    });

    // Handle typing indicator - broadcast to both sender and receiver
    socket.on('userTyping', (data) => {
      const { conversationId, receiverId, senderId, isTyping } = data;
      const receiverSocketId = connectedUsers.get(receiverId);
      const senderSocketId = connectedUsers.get(senderId);
      
      const typingEvent = {
        conversationId,
        senderId,
        isTyping,
        timestamp: new Date()
      };
      
      // Send to receiver
      if (receiverSocketId) {
        io.to(receiverSocketId).emit('userTyping', typingEvent);
      }
      
      // Also send back to sender (for local UI feedback)
      if (senderSocketId) {
        io.to(senderSocketId).emit('userTyping', typingEvent);
      }
    });

    // Handle message read receipt
    socket.on('messageRead', (data) => {
      const { conversationId, senderId, receiverId } = data;
      const senderSocketId = connectedUsers.get(senderId);
      
      if (senderSocketId) {
        io.to(senderSocketId).emit('messageRead', {
          conversationId,
          receiverId,
          timestamp: new Date()
        });
      }
    });

    // Handle message delete
    socket.on('messageDeleted', (data) => {
      const { conversationId, messageId, senderId, receiverId } = data;
      const receiverSocketId = connectedUsers.get(receiverId);
      
      if (receiverSocketId) {
        io.to(receiverSocketId).emit('messageDeleted', {
          conversationId,
          messageId,
          timestamp: new Date()
        });
      }
    });

    // Handle incoming call
    socket.on('incomingCall', (data) => {
      const { callerId, receiverId, conversationId } = data;
      
      // Convert to string for lookup
      const receiverIdStr = receiverId.toString ? receiverId.toString() : receiverId;
      const callerIdStr = callerId.toString ? callerId.toString() : callerId;
      
      console.log(`[Socket] Incoming call from ${callerIdStr} to ${receiverIdStr}`);
      console.log(`[Socket] Connected users:`, Array.from(connectedUsers.keys()));
      
      const receiverSocketId = connectedUsers.get(receiverIdStr);
      
      if (receiverSocketId) {
        console.log(`[Socket] Found receiver socket ${receiverSocketId}, sending incomingCall event`);
        io.to(receiverSocketId).emit('incomingCall', {
          callerId: callerIdStr,
          conversationId,
          timestamp: new Date()
        });
      } else {
        console.log(`[Socket] Receiver ${receiverIdStr} not connected`);
      }
    });

    // Handle call accepted
    socket.on('callAccepted', (data) => {
      const { callerId, receiverId, conversationId } = data;
      const callerIdStr = callerId.toString ? callerId.toString() : callerId;
      const receiverIdStr = receiverId.toString ? receiverId.toString() : receiverId;
      const callerSocketId = connectedUsers.get(callerIdStr);
      
      console.log(`[Socket] Call accepted by ${receiverIdStr}`);
      if (callerSocketId) {
        io.to(callerSocketId).emit('callAccepted', {
          receiverId: receiverIdStr,
          conversationId,
          timestamp: new Date()
        });
      } else {
        console.log(`[Socket] Caller ${callerIdStr} not connected`);
      }
    });

    // Handle call rejected
    socket.on('callRejected', (data) => {
      const { callerId, receiverId, conversationId } = data;
      const callerIdStr = callerId.toString ? callerId.toString() : callerId;
      const receiverIdStr = receiverId.toString ? receiverId.toString() : receiverId;
      const callerSocketId = connectedUsers.get(callerIdStr);
      
      console.log(`[Socket] Call rejected by ${receiverIdStr}`);
      if (callerSocketId) {
        io.to(callerSocketId).emit('callRejected', {
          receiverId: receiverIdStr,
          conversationId,
          timestamp: new Date()
        });
      } else {
        console.log(`[Socket] Caller ${callerIdStr} not connected`);
      }
    });

    // Handle call ended
    socket.on('callEnded', (data) => {
      const { senderId, receiverId, conversationId } = data;
      const senderIdStr = senderId.toString ? senderId.toString() : senderId;
      const receiverIdStr = receiverId.toString ? receiverId.toString() : receiverId;
      
      console.log(`[Socket] Call ended between ${senderIdStr} and ${receiverIdStr}`);
      
      // Send to receiver
      const receiverSocketId = connectedUsers.get(receiverIdStr);
      if (receiverSocketId) {
        io.to(receiverSocketId).emit('callEnded', {
          conversationId,
          timestamp: new Date()
        });
      }
      
      // Also send back to sender to ensure both close
      io.to(socket.id).emit('callEnded', {
        conversationId,
        timestamp: new Date()
      });
    });
    
    // Handle disconnect
    socket.on('disconnect', () => {
      // Remove from connected users
      for (const [userId, socketId] of connectedUsers.entries()) {
        if (socketId === socket.id) {
          connectedUsers.delete(userId);
          console.log(`[Socket] User ${userId} disconnected`);
          break;
        }
      }
      console.log(`[Socket] Total connected users: ${connectedUsers.size}`);
    });
  });
  
  console.log('[Socket] Socket.IO service initialized');
};

/**
 * Emit event to specific user
 */
exports.emitToUser = (userId, event, data) => {
  const socketId = connectedUsers.get(userId);
  if (socketId) {
    io.to(socketId).emit(event, data);
    return true;
  }
  return false;
};

/**
 * Emit event to multiple users
 */
exports.emitToUsers = (userIds, event, data) => {
  let sentCount = 0;
  userIds.forEach(userId => {
    if (exports.emitToUser(userId, event, data)) {
      sentCount++;
    }
  });
  return sentCount;
};

/**
 * Get connected users count
 */
exports.getConnectedUsersCount = () => {
  return connectedUsers.size;
};

/**
 * Emit geofence alert to linked parents
 */
exports.emitGeofenceAlert = async (parentIds, alertData) => {
  try {
    if (!parentIds || parentIds.length === 0) {
      console.log('[Socket] No parent IDs provided for geofence alert');
      return 0;
    }

    console.log(`[Socket] Emitting geofence alert to ${parentIds.length} parents`);
    
    let emitCount = 0;
    parentIds.forEach(parentId => {
      const socketId = connectedUsers.get(parentId);
      if (socketId && io) {
        io.to(socketId).emit('geofenceAlert', alertData);
        emitCount++;
        console.log(`[Socket] Sent geofence alert to parent ${parentId}`);
      }
    });
    
    console.log(`[Socket] Emitted geofence alert to ${emitCount}/${parentIds.length} connected parents`);
    return emitCount;
  } catch (error) {
    console.error('[Socket] Geofence alert emit error:', error);
    return 0;
  }
};

/**
 * Emit location update to linked parents
 */
exports.emitLocationUpdate = async (locationData) => {
  const { userId, latitude, longitude, accuracy, timestamp, address } = locationData;
  
  try {
    console.log(`[Socket] emitLocationUpdate for child ${userId}`);
    console.log(`[Socket] Connected users map:`, Array.from(connectedUsers.entries()));
    
    const User = require('../models/User');
    const child = await User.findById(userId).populate('linkedParents');
    
    if (child && child.linkedParents) {
      const parentIds = child.linkedParents.map(p => p._id.toString());
      console.log(`[Socket] Linked parents: ${parentIds.join(', ')}`);
      
      // If address not provided, reverse geocode using Nominatim (FREE)
      let finalAddress = address;
      if (!finalAddress) {
        try {
          const geocodingService = require('../utils/geocoding.service');
          finalAddress = await geocodingService.reverseGeocode(latitude, longitude);
        } catch (error) {
          console.warn('[Socket] Geocoding failed, using coordinates:', error.message);
          finalAddress = `${latitude.toFixed(4)}, ${longitude.toFixed(4)}`;
        }
      }
      
      let emitCount = 0;
      parentIds.forEach(parentId => {
        const socketId = connectedUsers.get(parentId);
        console.log(`[Socket] Parent ${parentId} → socketId: ${socketId}`);
        if (socketId && io) {
          io.to(socketId).emit('locationUpdate', {
            childId: userId,
            latitude,
            longitude,
            accuracy,
            timestamp,
            address: finalAddress  // ← NEW: Include address
          });
          emitCount++;
        }
      });
      console.log(`[Socket] Emitted to ${emitCount}/${parentIds.length} parents (${finalAddress})`);
    } else {
      console.log(`[Socket] Child not found or no linked parents`);
    }
  } catch (error) {
    console.error('[Socket] Location emit error:', error);
  }
};

module.exports = exports;
