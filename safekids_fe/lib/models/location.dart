/// Data model for a single location point.
class Location {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;

  Location({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['_id'],
      userId: json['userId'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
