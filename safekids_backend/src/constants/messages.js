/**
 * Message Constants for Multi-language Support
 * Vietnamese language definitions for geofence alerts
 */

const GeofenceMessages = {
  // Notification titles
  NOTIFICATION_TITLE: 'Cảnh Báo Vùng',
  
  // Action text in Vietnamese
  ACTIONS: {
    EXIT: 'đã rời khỏi',
    ENTER: 'đã vào'
  },
  
  // Geofence type examples (common locations)
  ZONE_TYPES: {
    SAFE_EXAMPLES: ['Trường học', 'Nhà', 'Quán cafe', 'Thư viện', 'Công viên'],
    DANGER_EXAMPLES: ['Khu vực nguy hiểm', 'Chỗ tối', 'Cấm phận', 'Vùng hạn chế']
  },
  
  // Message templates
  buildAlertMessage: (childName, action, zoneName) => {
    const actionText = action === 'exit' ? GeofenceMessages.ACTIONS.EXIT : GeofenceMessages.ACTIONS.ENTER;
    return `${childName} ${actionText} ${zoneName}`;
  },
  
  // Error messages
  ERRORS: {
    FCM_FAILED: 'Không thể gửi thông báo đẩy',
    TOKEN_INVALID: 'FCM token không hợp lệ',
    NETWORK_ERROR: 'Lỗi kết nối mạng',
    DATABASE_ERROR: 'Lỗi cơ sở dữ liệu'
  },
  
  // Success messages  
  SUCCESS: {
    SENT: 'Thông báo đã được gửi thành công',
    LOGGED: 'Cảnh báo đã được ghi lại'
  }
};

module.exports = {
  GeofenceMessages
};
