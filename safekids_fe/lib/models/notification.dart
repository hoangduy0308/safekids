enum NotificationCategory {
  alert, // Cảnh báo (đỏ)
  update, // Cập nhật (xanh dương)
  warning, // Chú ý (cam)
  general, // Thông thường (xám)
}

class NotificationItem {
  final String id;
  final String childId;
  final String childName;
  final NotificationCategory category;
  final String title;
  final String? description;
  final DateTime timestamp;
  final bool isRead;
  final String? actionLabel;
  final Function? onAction;
  final Map<String, dynamic>? metadata;

  NotificationItem({
    required this.id,
    required this.childId,
    required this.childName,
    required this.category,
    required this.title,
    this.description,
    required this.timestamp,
    this.isRead = false,
    this.actionLabel,
    this.onAction,
    this.metadata,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['_id'] ?? json['id'] ?? '',
      childId: json['childId'] ?? '',
      childName: json['childName'] ?? '',
      category: _parseCategory(json['category'] ?? 'general'),
      title: json['title'] ?? '',
      description: json['description'],
      timestamp: DateTime.parse(
        json['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
      isRead: json['isRead'] ?? false,
      actionLabel: json['actionLabel'],
      metadata: json['metadata'],
    );
  }

  static NotificationCategory _parseCategory(String value) {
    switch (value.toLowerCase()) {
      case 'alert':
        return NotificationCategory.alert;
      case 'update':
        return NotificationCategory.update;
      case 'warning':
        return NotificationCategory.warning;
      default:
        return NotificationCategory.general;
    }
  }

  NotificationItem copyWith({
    String? id,
    String? childId,
    String? childName,
    NotificationCategory? category,
    String? title,
    String? description,
    DateTime? timestamp,
    bool? isRead,
    String? actionLabel,
    Function? onAction,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionLabel: actionLabel ?? this.actionLabel,
      onAction: onAction ?? this.onAction,
      metadata: metadata ?? this.metadata,
    );
  }
}
