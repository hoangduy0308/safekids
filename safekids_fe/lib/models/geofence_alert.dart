class GeofenceAlertModel {
  final String id;
  final String action; // 'enter' | 'exit'
  final String geofenceId;
  final String geofenceName;
  final String geofenceType;
  final String childId;
  final String childName;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  GeofenceAlertModel({
    required this.id,
    required this.action,
    required this.geofenceId,
    required this.geofenceName,
    required this.geofenceType,
    required this.childId,
    required this.childName,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory GeofenceAlertModel.fromJson(Map<String, dynamic> json) {
    final geofence = json['geofenceId'];
    final child = json['childId'];
    return GeofenceAlertModel(
      id: json['_id'] as String,
      action: json['action'] as String,
      geofenceId: geofence is Map
          ? geofence['_id'] as String
          : geofence as String,
      geofenceName: geofence is Map
          ? (geofence['name'] as String? ?? 'Unknown')
          : 'Unknown',
      geofenceType: geofence is Map
          ? (geofence['type'] as String? ?? 'safe')
          : 'safe',
      childId: child is Map ? child['_id'] as String : child as String,
      childName: child is Map
          ? (child['fullName'] as String? ??
                child['name'] as String? ??
                'Unknown')
          : 'Unknown',
      latitude: (json['location']?['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['location']?['longitude'] as num?)?.toDouble() ?? 0,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
