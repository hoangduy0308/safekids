import 'package:latlong2/latlong.dart';

class GeofenceSuggestion {
  final String id;
  final String name;
  final LatLng center;
  final int visitCount;
  final String suggestedType;

  GeofenceSuggestion({
    required this.id,
    required this.name,
    required this.center,
    required this.visitCount,
    this.suggestedType = 'safe',
  });

  factory GeofenceSuggestion.fromJson(Map<String, dynamic> json) {
    return GeofenceSuggestion(
      id: json['id'] as String,
      name: json['name'] as String,
      center: LatLng(
        (json['center']['latitude'] as num).toDouble(),
        (json['center']['longitude'] as num).toDouble(),
      ),
      visitCount: json['visitCount'] as int,
      suggestedType: json['suggestedType'] as String? ?? 'safe',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'center': {'latitude': center.latitude, 'longitude': center.longitude},
    'visitCount': visitCount,
    'suggestedType': suggestedType,
  };
}
