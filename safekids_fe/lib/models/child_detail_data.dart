import './location.dart' as location_model;

/// Data class for child detail
class ChildDetailData {
  final String childId;
  final String name;
  final int? batteryLevel;
  final String lastSeen;
  final String locationName;
  final bool isInSafeZone;
  final int screenTimeMinutes;
  final int screenTimeLimit;
  final location_model.Location? selectedLocation;

  ChildDetailData({
    required this.childId,
    required this.name,
    this.batteryLevel,
    required this.lastSeen,
    required this.locationName,
    required this.isInSafeZone,
    required this.screenTimeMinutes,
    required this.screenTimeLimit,
    this.selectedLocation,
  });
}
