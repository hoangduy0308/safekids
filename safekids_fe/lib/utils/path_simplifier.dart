import 'package:latlong2/latlong.dart';
import 'dart:math';

/// Path simplification using Douglas-Peucker algorithm (Task 5 - AC 2.4.6)
class PathSimplifier {
  /// Simplify path by reducing number of points while preserving shape
  ///
  /// Returns simplified list of LatLng points
  static List<LatLng> simplify(
    List<LatLng> points, {
    double tolerance = 0.0001,
  }) {
    if (points.length <= 2) return points;

    // Douglas-Peucker algorithm
    return _douglasPeucker(points, 0, points.length - 1, tolerance);
  }

  /// Recursive Douglas-Peucker implementation
  static List<LatLng> _douglasPeucker(
    List<LatLng> points,
    int start,
    int end,
    double tolerance,
  ) {
    double maxDistance = 0;
    int maxIndex = 0;

    // Find point with maximum distance from line segment (start -> end)
    for (int i = start + 1; i < end; i++) {
      final distance = _perpendicularDistance(
        points[i],
        points[start],
        points[end],
      );
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    // If max distance exceeds tolerance, recursively simplify both segments
    if (maxDistance > tolerance) {
      final left = _douglasPeucker(points, start, maxIndex, tolerance);
      final right = _douglasPeucker(points, maxIndex, end, tolerance);

      // Merge results (exclude duplicate middle point)
      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      // All points within tolerance, return only endpoints
      return [points[start], points[end]];
    }
  }

  /// Calculate perpendicular distance from point to line
  ///
  /// Uses formula: distance = |ax + by + c| / sqrt(a² + b²)
  /// where line is defined by two points (lineStart, lineEnd)
  static double _perpendicularDistance(
    LatLng point,
    LatLng lineStart,
    LatLng lineEnd,
  ) {
    // Direction vector of the line
    final dx = lineEnd.latitude - lineStart.latitude;
    final dy = lineEnd.longitude - lineStart.longitude;

    // Vector from line start to point
    final px = point.latitude - lineStart.latitude;
    final py = point.longitude - lineStart.longitude;

    // Cross product magnitude
    final numerator = (px * dy - py * dx).abs();

    // Line segment length
    final denominator = sqrt(dx * dx + dy * dy);

    // Avoid division by zero
    if (denominator == 0) {
      return sqrt(px * px + py * py);
    }

    return numerator / denominator;
  }

  /// Sample every Nth point (alternative to Douglas-Peucker for quick reduction)
  ///
  /// Use when you need faster simplification without preserving exact shape
  static List<LatLng> sampleEveryNth(List<LatLng> points, int n) {
    if (points.length <= n) return points;

    final sampled = <LatLng>[points.first]; // Always include first point

    for (int i = n; i < points.length - 1; i += n) {
      sampled.add(points[i]);
    }

    sampled.add(points.last); // Always include last point

    return sampled;
  }
}
