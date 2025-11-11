import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/geofence_alert.dart';

void main() {
  group('GeofenceAlertModel', () {
    group('fromJson - Story 3.4 P0', () {
      test('UNIT-001: Parse valid alert with all fields', () {
        final json = {
          '_id': 'alert-123',
          'action': 'enter',
          'geofenceId': {'_id': 'geo-1', 'name': 'Trường học', 'type': 'safe'},
          'childId': {'_id': 'child-1', 'fullName': 'Minh An', 'name': 'Minh'},
          'location': {'latitude': 10.123456, 'longitude': 106.654321},
          'timestamp': '2025-10-15T14:30:00.000Z',
        };

        final alert = GeofenceAlertModel.fromJson(json);

        expect(alert.id, 'alert-123');
        expect(alert.action, 'enter');
        expect(alert.geofenceId, 'geo-1');
        expect(alert.geofenceName, 'Trường học');
        expect(alert.geofenceType, 'safe');
        expect(alert.childId, 'child-1');
        expect(alert.childName, 'Minh An');
        expect(alert.latitude, 10.123456);
        expect(alert.longitude, 106.654321);
        expect(alert.timestamp.year, 2025);
      });

      test('UNIT-002: Parse alert with exit action', () {
        final json = {
          '_id': 'alert-exit',
          'action': 'exit',
          'geofenceId': {'_id': 'geo-2', 'name': 'Nhà', 'type': 'safe'},
          'childId': {'_id': 'child-2', 'fullName': 'Hồng Nhung'},
          'location': {'latitude': 10.1, 'longitude': 106.1},
          'timestamp': '2025-10-15T15:00:00.000Z',
        };

        final alert = GeofenceAlertModel.fromJson(json);

        expect(alert.action, 'exit');
        expect(alert.geofenceName, 'Nhà');
      });

      test('UNIT-003: Handle missing fullName fallback to name', () {
        final json = {
          '_id': 'alert-3',
          'action': 'enter',
          'geofenceId': {'_id': 'geo-1', 'name': 'Trường', 'type': 'safe'},
          'childId': {'_id': 'child-1', 'name': 'An'},
          'location': {'latitude': 10, 'longitude': 106},
          'timestamp': DateTime.now().toIso8601String(),
        };

        final alert = GeofenceAlertModel.fromJson(json);

        expect(alert.childName, 'An');
      });

      test('UNIT-004: Handle missing fields with defaults', () {
        final json = {
          '_id': 'alert-4',
          'action': 'enter',
          'geofenceId': {'_id': 'geo-1'},
          'childId': {'_id': 'child-1'},
          'timestamp': DateTime.now().toIso8601String(),
        };

        final alert = GeofenceAlertModel.fromJson(json);

        expect(alert.geofenceName, 'Unknown');
        expect(alert.childName, 'Unknown');
        expect(alert.geofenceType, 'safe');
        expect(alert.latitude, 0.0);
        expect(alert.longitude, 0.0);
      });

      test('UNIT-005: Handle string IDs instead of nested objects', () {
        final json = {
          '_id': 'alert-5',
          'action': 'enter',
          'geofenceId': 'geo-1-string',
          'childId': 'child-1-string',
          'timestamp': DateTime.now().toIso8601String(),
        };

        final alert = GeofenceAlertModel.fromJson(json);

        expect(alert.geofenceId, 'geo-1-string');
        expect(alert.childId, 'child-1-string');
      });

      test('UNIT-006: Parse danger type geofence', () {
        final json = {
          '_id': 'alert-6',
          'action': 'enter',
          'geofenceId': {
            '_id': 'geo-danger',
            'name': 'Khu nguy hiểm',
            'type': 'danger',
          },
          'childId': {'_id': 'child-1', 'fullName': 'An'},
          'location': {'latitude': 10, 'longitude': 106},
          'timestamp': DateTime.now().toIso8601String(),
        };

        final alert = GeofenceAlertModel.fromJson(json);

        expect(alert.geofenceType, 'danger');
      });

      test('UNIT-007: Preserve timestamp accuracy', () {
        final originalTime = DateTime(2025, 10, 15, 14, 30, 45, 123);
        final json = {
          '_id': 'alert-7',
          'action': 'enter',
          'geofenceId': {'_id': 'geo-1', 'name': 'Loc', 'type': 'safe'},
          'childId': {'_id': 'child-1', 'fullName': 'An'},
          'location': {'latitude': 10, 'longitude': 106},
          'timestamp': originalTime.toIso8601String(),
        };

        final alert = GeofenceAlertModel.fromJson(json);

        expect(alert.timestamp.year, originalTime.year);
        expect(alert.timestamp.month, originalTime.month);
        expect(alert.timestamp.day, originalTime.day);
      });
    });

    group('Coordinate validation - P1', () {
      test('INT-001: Valid coordinate ranges', () {
        final json = {
          '_id': 'alert-8',
          'action': 'enter',
          'geofenceId': {'_id': 'geo-1', 'name': 'Loc', 'type': 'safe'},
          'childId': {'_id': 'child-1', 'fullName': 'An'},
          'location': {'latitude': -90.0, 'longitude': -180.0},
          'timestamp': DateTime.now().toIso8601String(),
        };

        final alert = GeofenceAlertModel.fromJson(json);

        expect(alert.latitude, -90.0);
        expect(alert.longitude, -180.0);
      });

      test('INT-002: Handle null location gracefully', () {
        final json = {
          '_id': 'alert-9',
          'action': 'enter',
          'geofenceId': {'_id': 'geo-1', 'name': 'Loc', 'type': 'safe'},
          'childId': {'_id': 'child-1', 'fullName': 'An'},
          'location': null,
          'timestamp': DateTime.now().toIso8601String(),
        };

        final alert = GeofenceAlertModel.fromJson(json);

        expect(alert.latitude, 0.0);
        expect(alert.longitude, 0.0);
      });
    });
  });
}
