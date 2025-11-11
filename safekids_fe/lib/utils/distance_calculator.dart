import 'dart:math';
import '../models/location.dart';

/// Calculates the distance between two locations in kilometers using the Haversine formula.
double calculateHaversineDistance(Location loc1, Location loc2) {
  const R = 6371; // Earth's radius in kilometers
  final dLat = (loc2.latitude - loc1.latitude) * pi / 180;
  final dLon = (loc2.longitude - loc1.longitude) * pi / 180;
  final lat1Rad = loc1.latitude * pi / 180;
  final lat2Rad = loc2.latitude * pi / 180;

  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1Rad) * cos(lat2Rad) * sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return R * c; // Distance in km
}

/// Distance calculator utility class (Task 7 - for path details)
class DistanceCalculator {
  /// Calculate distance between two lat/lng coordinates in kilometers
  ///
  /// Uses Haversine formula
  static double haversine(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371; // Earth's radius in kilometers
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lng2 - lng1) * pi / 180;
    final lat1Rad = lat1 * pi / 180;
    final lat2Rad = lat2 * pi / 180;

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c; // Distance in km
  }
}
