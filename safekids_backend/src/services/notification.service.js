let admin = null;

try {
  admin = require('firebase-admin');
} catch (e) {
  console.warn('[Notification] Firebase-admin not configured');
}

/**
 * Notification Service
 * Handles Firebase Cloud Messaging (FCM) notifications to users
 */
class NotificationService {
  constructor() {
    this.initialized = false;
    this.firebaseAvailable = false;
  }

  /**
   * Initialize Firebase Admin SDK (if available)
   */
  initialize() {
    try {
      if (admin && admin.apps && admin.apps.length > 0) {
        this.firebaseAvailable = true;
        console.log('✅ [Notification] Firebase Admin SDK initialized');
      } else if (admin) {
        // Try to initialize if not already done
        console.log('⚠️ [Notification] Firebase Admin SDK present but no apps initialized');
        console.log('   (Notifications will be logged to console only)');
      } else {
        console.warn('⚠️ [Notification] Firebase Admin SDK not available');
        console.warn('   (Notifications will be logged to console only)');
      }
      this.initialized = true;
    } catch (error) {
      console.error('[Notification] Init error:', error);
      this.initialized = true;
    }
  }

  /**
   * Send notification via FCM
   * @param {string} fcmToken - Device FCM token
   * @param {string} title - Notification title
   * @param {string} body - Notification body
   * @param {object} data - Custom data
   */
  async sendNotification(fcmToken, title, body, data = {}) {
    try {
      if (!fcmToken) {
        console.warn('[Notification] No FCM token provided');
        return false;
      }

      // If Firebase available, send real notification
      if (this.firebaseAvailable && admin && admin.messaging) {
        const message = {
          token: fcmToken,
          notification: {
            title,
            body,
          },
          data,
          android: {
            priority: 'high',
            ttl: 3600,
          },
          apns: {
            headers: {
              'apns-priority': '10',
            },
          },
        };

        const response = await admin.messaging().send(message);
        console.log(`✅ [Notification] FCM sent: ${body}`);
        console.log(`   Token: ${fcmToken.substring(0, 30)}...`);
        console.log(`   Message ID: ${response}`);
        return true;
      } else {
        // Fallback: just log notification (for development)
        console.log(`📬 [Notification] (Console Notification)`);
        console.log(`   Title: ${title}`);
        console.log(`   Body: ${body}`);
        console.log(`   Token: ${fcmToken.substring(0, 30)}...`);
        console.log(`   Data: ${JSON.stringify(data)}`);
        return true;
      }
    } catch (error) {
      console.error('[Notification] Send error:', error.message);
      return false;
    }
  }

  /**
   * Send multi-cast notification
   * @param {array} fcmTokens - Array of FCM tokens
   * @param {string} title - Notification title
   * @param {string} body - Notification body
   * @param {object} data - Custom data
   */
  async sendMulticastNotification(fcmTokens, title, body, data = {}) {
    try {
      if (!fcmTokens || fcmTokens.length === 0) {
        console.warn('[Notification] No FCM tokens provided');
        return 0;
      }

      // If Firebase available, send real notifications
      if (this.firebaseAvailable && admin && admin.messaging) {
        const message = {
          notification: {
            title,
            body,
          },
          data,
          android: {
            priority: 'high',
          },
          apns: {
            headers: {
              'apns-priority': '10',
            },
          },
        };

        const response = await admin.messaging().sendMulticast({
          ...message,
          tokens: fcmTokens,
        });

        console.log(`✅ [Notification] FCM sent to ${response.successCount}/${fcmTokens.length}: ${body}`);
        if (response.failureCount > 0) {
          console.warn(`⚠️ [Notification] Failed: ${response.failureCount} devices`);
        }
        return response.successCount;
      } else {
        // Fallback: log notifications
        console.log(`📬 [Notification] (Console Notification to ${fcmTokens.length} users)`);
        console.log(`   Title: ${title}`);
        console.log(`   Body: ${body}`);
        console.log(`   Data: ${JSON.stringify(data)}`);
        return fcmTokens.length;
      }
    } catch (error) {
      console.error('[Notification] Multicast error:', error.message);
      return 0;
    }
  }
}

/**
 * Real notification sender (for testing staging environment)
 */
class NotificationServiceWithMethod extends NotificationService {
  
  async __realSendNotification(fcmToken, title, body, data = {}) {
    // In production, this would always use real Firebase
    if (this.firebaseAvailable && admin && admin.messaging) {
      try {
        const message = {
          token: fcmToken,
          notification: {
            title,
            body,
          },
          data,
          android: {
            priority: 'high',
            ttl: 3600,
          },
          apns: {
            headers: {
              'apns-priority': '10',
            },
          },
        };

        const response = await admin.messaging().send(message);
        console.log(`✅ [Notification] Real FCM sent: ${body}`);
        return true;
      } catch (error) {
        console.error('[Notification] Real FCM error:', error.message);
        return false;
      }
    }
    
    // Fallback to console logging
    console.log(`📬 [Notification] Console fallback: ${title} - ${body}`);
    return true;
  }
}

module.exports = new NotificationServiceWithMethod();
