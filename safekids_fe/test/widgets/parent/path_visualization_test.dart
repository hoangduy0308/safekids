import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:safekids_app/utils/path_simplifier.dart';

void main() {
  group('PathSimplifier.simplify', () {
    test('returns endpoints when intermediate points within tolerance', () {
      final points = [
        const LatLng(10.0, 106.0),
        const LatLng(10.00005, 106.00005),
        const LatLng(10.0001, 106.0001),
      ];

      final simplified = PathSimplifier.simplify(points, tolerance: 0.0002);

      expect(simplified.length, 2);
      expect(simplified.first, equals(points.first));
      expect(simplified.last, equals(points.last));
    });

    test('keeps significant points above tolerance', () {
      final points = [
        const LatLng(10.0, 106.0),
        const LatLng(10.005, 106.005),
        const LatLng(10.01, 106.01),
      ];

      final simplified = PathSimplifier.simplify(points, tolerance: 0.0001);

      expect(simplified, contains(const LatLng(10.005, 106.005)));
      expect(simplified.length, 3);
    });
  });

  group('PathSimplifier.sampleEveryNth', () {
    test('samples every nth point including ends', () {
      final points = List.generate(
        10,
        (index) => LatLng(10.0 + index * 0.001, 106.0 + index * 0.001),
      );

      final sampled = PathSimplifier.sampleEveryNth(points, 3);

      expect(sampled.first, equals(points.first));
      expect(sampled.last, equals(points.last));
      expect(sampled.length, greaterThan(2));
    });
  });
}
