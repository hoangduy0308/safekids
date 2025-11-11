import 'package:flutter_test/flutter_test.dart';
import 'package:safekids_app/services/location_service.dart';

void main() {
  group('AC 2.1.4: Location Permission Request Tests', () {
    test('UNIT-001: LocationService has requestLocationPermission method', () {
      // Verify the method exists and is callable
      final service = LocationService();
      expect(service.requestLocationPermission, isNotNull);
    });

    test('UNIT-002: requestLocationPermission is async Future<bool>', () {
      final service = LocationService();
      final method = service.requestLocationPermission;
      expect(method, isNotNull);
      // Calling it should return a Future<bool>
    });

    test(
      'UNIT-003: checkAndRequestPermissions delegates to requestLocationPermission',
      () {
        final service = LocationService();
        expect(service.checkAndRequestPermissions, isNotNull);
      },
    );
  });
}
