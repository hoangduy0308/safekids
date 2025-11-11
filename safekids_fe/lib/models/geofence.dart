import 'package:latlong2/latlong.dart';

class Geofence {
  final String id;
  final String parentId;
  final String name;
  final String type;
  final GeofenceCenter center;
  final double radius;
  final ActiveHours? activeHours;
  final List<String> linkedChildren;
  final bool active;

  Geofence({
    required this.id,
    required this.parentId,
    required this.name,
    required this.type,
    required this.center,
    required this.radius,
    this.activeHours,
    required this.linkedChildren,
    this.active = true,
  });

  factory Geofence.fromJson(Map<String, dynamic> json) {
    // Handle linkedChildren - có thể là array of objects hoặc array of strings
    List<String> linkedChildrenIds = [];
    final linkedChildrenData = json['linkedChildren'] as List?;
    if (linkedChildrenData != null) {
      for (var item in linkedChildrenData) {
        if (item is String) {
          linkedChildrenIds.add(item);
        } else if (item is Map) {
          final map = Map<String, dynamic>.from(item as Map);
          dynamic idValue = map['_id'] ?? map['id'] ?? map['childId'];
          if (idValue == null && map['child'] is Map) {
            final nested = Map<String, dynamic>.from(map['child'] as Map);
            idValue = nested['_id'] ?? nested['id'] ?? nested['childId'];
          }
          if (idValue != null) {
            linkedChildrenIds.add(idValue.toString());
          }
        }
      }
    }

    return Geofence(
      id: json['_id'] as String,
      parentId: json['parentId'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      center: GeofenceCenter.fromJson(json['center']),
      radius: (json['radius'] as num).toDouble(),
      activeHours: json['activeHours'] != null
          ? ActiveHours.fromJson(json['activeHours'])
          : null,
      linkedChildren: linkedChildrenIds,
      active: json['active'] as bool? ?? true,
    );
  }

  LatLng get latLng => LatLng(center.latitude, center.longitude);

  bool get isSafeZone => type == 'safe';
  bool get isDangerZone => type == 'danger';
}

class GeofenceCenter {
  final double latitude;
  final double longitude;

  GeofenceCenter({required this.latitude, required this.longitude});

  factory GeofenceCenter.fromJson(Map<String, dynamic> json) {
    return GeofenceCenter(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

class ActiveHours {
  final String start;
  final String end;

  ActiveHours({required this.start, required this.end});

  factory ActiveHours.fromJson(Map<String, dynamic> json) {
    return ActiveHours(
      start: json['start'] as String,
      end: json['end'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'start': start, 'end': end};
}
