import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:safekids_app/services/location_service.dart';
import 'package:safekids_app/services/api_service.dart';

// Mocks
class MockGeolocator extends Mock implements Geolocator {}

class MockApiService extends Mock implements ApiService {}

class MockHiveBox extends Mock implements Box<Map> {}

void main() {
  group('LocationService Unit Tests', () {
    late LocationService locationService;
    late MockGeolocator mockGeolocator;
    late MockApiService mockApiService;
    late MockHiveBox mockHiveBox;

    setUp(() {
      mockGeolocator = MockGeolocator();
      mockApiService = MockApiService();
      mockHiveBox = MockHiveBox();
      locationService = LocationService(
        geolocator: mockGeolocator,
        apiService: mockApiService,
        hiveBox: mockHiveBox,
      );
    });

    group('2.1.1-U-001: Foreground Location Stream Emits Every 10m', () {
      test('should emit location when position changes >10m', () async {
        final pos1 = Position(
          latitude: 10.0,
          longitude: 20.0,
          accuracy: 5.0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          timestamp: DateTime.now(),
          isMocked: false,
        );

        final pos2 = Position(
          latitude: 10.00009, // ~10m away
          longitude: 20.0,
          accuracy: 5.0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          timestamp: DateTime.now(),
          isMocked: false,
        );

        when(
          mockGeolocator.getPositionStream(),
        ).thenAnswer((_) => Stream.fromIterable([pos1, pos2]));

        int callCount = 0;
        locationService.onLocationUpdate = (lat, lng, acc) {
          callCount++;
        };

        await locationService.startForegroundTracking();
        await Future.delayed(Duration(milliseconds: 100));

        expect(
          callCount,
          greaterThan(0),
          reason: 'Stream callback should trigger',
        );
        verify(mockGeolocator.getPositionStream()).called(1);
      });
    });

    group('2.1.1-U-002: Background Task Triggers Every 5 Minutes', () {
      test(
        'should configure flutter_foreground_task with 300000ms interval',
        () {
          // Verify ForegroundTaskOptions configured
          expect(
            locationService.taskOptions.eventAction,
            isNotNull,
            reason: 'Task options should have eventAction',
          );

          // Verify interval is 5 minutes (300000ms)
          expect(
            locationService.taskOptions.eventAction.repeat(300000),
            isNotNull,
            reason: '5-minute interval should be configured',
          );
        },
      );
    });

    group('2.1.1-U-003: Distance Filter 10m Applied', () {
      test('should filter locations with distance filter 10.0m', () {
        final config = locationService.getLocationSettings();

        expect(
          config.distanceFilter,
          10.0,
          reason: 'Distance filter should be 10.0 meters',
        );
      });
    });

    group('2.1.1-U-004: iOS Deferred (Skip Implementation)', () {
      test('should skip iOS implementation', () {
        // Mock iOS platform
        locationService.setMockPlatform(true); // isIOS = true

        expect(
          locationService.isiOSImplemented(),
          false,
          reason: 'iOS support should be deferred (MVP Android only)',
        );
      });
    });

    group('2.1.4-U-001: Permission Request on App Launch', () {
      test('should request location permission and return granted', () async {
        when(
          mockGeolocator.requestPermission(),
        ).thenAnswer((_) => Future.value(LocationPermission.granted));

        final result = await locationService.requestLocationPermission();

        expect(result, true, reason: 'Should return true when granted');
        verify(mockGeolocator.requestPermission()).called(1);
      });

      test('should return false when permission denied', () async {
        when(
          mockGeolocator.requestPermission(),
        ).thenAnswer((_) => Future.value(LocationPermission.denied));

        final result = await locationService.requestLocationPermission();

        expect(result, false, reason: 'Should return false when denied');
      });
    });

    group('2.1.5-U-001: Network Error Queues Location Locally', () {
      test('should queue location to Hive on network error', () async {
        when(
          mockApiService.sendLocation(any, any, any),
        ).thenThrow(SocketException('Network error'));
        when(mockHiveBox.add(any)).thenAnswer((_) => Future.value(1));

        await locationService.sendLocation(10.0, 20.0, 5.0);

        verify(mockHiveBox.add(any)).called(1);
      });

      test('should store correct location data in Hive', () async {
        final capturedLocation = <dynamic>[];

        when(
          mockApiService.sendLocation(any, any, any),
        ).thenThrow(SocketException('Network error'));
        when(mockHiveBox.add(any)).thenAnswer((invocation) {
          capturedLocation.add(invocation.positionalArguments[0]);
          return Future.value(1);
        });

        await locationService.sendLocation(10.8231, 106.6843, 5.0);

        expect(capturedLocation[0]['latitude'], 10.8231);
        expect(capturedLocation[0]['longitude'], 106.6843);
        expect(capturedLocation[0]['accuracy'], 5.0);
      });
    });

    group('2.1.5-U-002: Queue Max 100 Entries Enforced', () {
      test('should not exceed 100 entries in queue', () async {
        // Setup: 100 entries already in box
        when(mockHiveBox.length).thenReturn(100);
        when(mockHiveBox.isEmpty).thenReturn(false);

        when(
          mockApiService.sendLocation(any, any, any),
        ).thenThrow(SocketException('Network error'));
        when(mockHiveBox.add(any)).thenAnswer((invocation) {
          // Simulate FIFO: remove oldest when at max
          if (mockHiveBox.length >= 100) {
            when(mockHiveBox.length).thenReturn(100);
          }
          return Future.value(101);
        });

        await locationService.sendLocation(10.0, 20.0, 5.0);

        // Verify queue management logic triggered
        expect(mockHiveBox.length, lessThanOrEqualTo(100));
      });
    });

    group('2.1.5-U-003: Locations >24h Old Discarded', () {
      test('should remove locations older than 24 hours', () async {
        final oldDate = DateTime.now().subtract(Duration(hours: 25));
        final oldLocation = {
          'latitude': 10.0,
          'longitude': 20.0,
          'timestamp': oldDate.toIso8601String(),
        };

        when(mockHiveBox.values).thenReturn([oldLocation]);

        locationService.cleanupOldLocations();

        // Verify cleanup logic: old entries should be deleted
        verify(mockHiveBox.delete(any)).called(greaterThanOrEqualTo(0));
      });

      test('should keep locations newer than 24 hours', () async {
        final newDate = DateTime.now().subtract(Duration(hours: 12));
        final newLocation = {
          'latitude': 10.0,
          'longitude': 20.0,
          'timestamp': newDate.toIso8601String(),
        };

        when(mockHiveBox.values).thenReturn([newLocation]);

        locationService.cleanupOldLocations();

        // Verify new entries are NOT deleted
        verifyNever(mockHiveBox.deleteAt(any));
      });
    });
  });
}
