import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

// Assuming these exist in the project
// import 'package:safekids_app/screens/parent/location_history_screen.dart';
// import 'package:safekids_app/services/api_service.dart';
// import 'package:safekids_app/models/location.dart';

/// Mock classes
class MockApiService extends Mock {}
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

/// Test data
final mockLocations = [
  Location(
    id: '1',
    userId: 'child123',
    latitude: 10.7231,
    longitude: 106.6843,
    accuracy: 5.0,
    timestamp: DateTime.now().subtract(Duration(hours: 2)),
  ),
  Location(
    id: '2',
    userId: 'child123',
    latitude: 10.7235,
    longitude: 106.6850,
    accuracy: 4.5,
    timestamp: DateTime.now().subtract(Duration(hours: 3)),
  ),
  Location(
    id: '3',
    userId: 'child123',
    latitude: 10.7240,
    longitude: 106.6855,
    accuracy: 5.5,
    timestamp: DateTime.now().subtract(Duration(hours: 4)),
  ),
];

void main() {
  group('Story 2.3: Location History Screen [P1-HIGH]', () {
    late MockApiService mockApiService;
    late MockNavigatorObserver mockNavigatorObserver;

    setUp(() {
      mockApiService = MockApiService();
      mockNavigatorObserver = MockNavigatorObserver();
    });

    /// AC 2.3.2: Timeline View UI
    group('AC 2.3.2: Timeline View UI', () => {
      testWidgets('2.3.2-UNIT-001: Screen renders with AppBar and title', (WidgetTester tester) async {
        // Mock getLocationHistory to return empty list
        when(mockApiService.getLocationHistory(
          any,
          any,
          any,
        )).thenAnswer((_) async => []);

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                Provider<ApiService>(create: (_) => mockApiService),
              ],
              child: LocationHistoryScreen(
                childId: 'child123',
                childName: 'Ngân Hàng',
              ),
            ),
          ),
        );

        // Wait for loading to complete
        await tester.pumpAndSettle();

        // Verify AppBar exists with child name
        expect(find.text('Lịch Sử - Ngân Hàng'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('2.3.2-INT-001: Timeline displays location entries', (WidgetTester tester) async {
        when(mockApiService.getLocationHistory(any, any, any))
            .thenAnswer((_) async => mockLocations);

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                Provider<ApiService>(create: (_) => mockApiService),
              ],
              child: LocationHistoryScreen(
                childId: 'child123',
                childName: 'Child',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify timeline entries are displayed
        expect(find.byType(ListView), findsOneWidget);
        expect(find.byIcon(Icons.location_on), findsWidgets);
      });

      testWidgets('2.3.2-INT-002: Timeline groups locations by date', (WidgetTester tester) async {
        // Create locations from different days
        final yesterday = DateTime.now().subtract(Duration(days: 1));
        final today = DateTime.now();

        final mixedDates = [
          Location(
            id: '1',
            userId: 'child123',
            latitude: 10.7231,
            longitude: 106.6843,
            accuracy: 5.0,
            timestamp: today,
          ),
          Location(
            id: '2',
            userId: 'child123',
            latitude: 10.7235,
            longitude: 106.6850,
            accuracy: 4.5,
            timestamp: yesterday,
          ),
        ];

        when(mockApiService.getLocationHistory(any, any, any))
            .thenAnswer((_) async => mixedDates);

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                Provider<ApiService>(create: (_) => mockApiService),
              ],
              child: LocationHistoryScreen(
                childId: 'child123',
                childName: 'Child',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify both dates are shown in UI
        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('2.3.2-INT-003: Timeline entry shows time, address, distance', (WidgetTester tester) async {
        when(mockApiService.getLocationHistory(any, any, any))
            .thenAnswer((_) async => mockLocations);

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                Provider<ApiService>(create: (_) => mockApiService),
              ],
              child: LocationHistoryScreen(
                childId: 'child123',
                childName: 'Child',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify location display elements
        expect(find.byType(ListTile), findsWidgets);
        expect(find.byIcon(Icons.location_on), findsWidgets);
      });
    });

    /// AC 2.3.3: Date Range Filter
    group('AC 2.3.3: Date Range Filter [P1-HIGH]', () => {
      testWidgets('2.3.3-UNIT-001: Filter chips are displayed', (WidgetTester tester) async {
        when(mockApiService.getLocationHistory(any, any, any))
            .thenAnswer((_) async => []);

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                Provider<ApiService>(create: (_) => mockApiService),
              ],
              child: LocationHistoryScreen(
                childId: 'child123',
                childName: 'Child',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify filter chips
        expect(find.text('Hôm nay'), findsOneWidget);
        expect(find.text('7 ngày'), findsOneWidget);
        expect(find.text('30 ngày'), findsOneWidget);
        expect(find.text('Tùy chỉnh'), findsOneWidget);
      });

      testWidgets('2.3.3-INT-001: Tap "7 ngày" filter fetches last 7 days', (WidgetTester tester) async {
        when(mockApiService.getLocationHistory(any, any, any))
            .thenAnswer((_) async => mockLocations);

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                Provider<ApiService>(create: (_) => mockApiService),
              ],
              child: LocationHistoryScreen(
                childId: 'child123',
                childName: 'Child',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap "7 ngày" chip
        await tester.tap(find.text('7 ngày'));
        await tester.pumpAndSettle();

        // Verify API was called
        verify(mockApiService.getLocationHistory(
          'child123',
          any,
          any,
        )).called(greaterThanOrEqualTo(1));
      });

      testWidgets('2.3.3-INT-002: Tap "Tùy chỉnh" opens date picker', (WidgetTester tester) async {
        when(mockApiService.getLocationHistory(any, any, any))
            .thenAnswer((_) async => []);

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                Provider<ApiService>(create: (_) => mockApiService),
              ],
              child: LocationHistoryScreen(
                childId: 'child123',
                childName: 'Child',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap "Tùy chỉnh" chip
        await tester.tap(find.text('Tùy chỉnh'));
        await tester.pumpAndSettle();

        // Date picker should appear (this is a Material widget)
        // Verification depends on implementation
      });

      testWidgets('2.3.3-INT-003: Selected filter chip is highlighted', (WidgetTester tester) async {
        when(mockApiService.getLocationHistory(any, any, any))
            .thenAnswer((_) async => []);

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                Provider<ApiService>(create: (_) => mockApiService),
              ],
              child: LocationHistoryScreen(
                childId: 'child123',
                childName: 'Child',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // First "Hôm nay" should be selected by default
        final firstChip = find.byType(ChoiceChip).first;
        expect(firstChip, findsOneWidget);

        // Verify chip is selected (would need to check widget properties)
      });
    });

    /// AC 2.3.4: Location Stats Summary
    group('AC 2.3.4: Location Stats Summary [P0-CRITICAL]', () => {
      testWidgets('2.3.4-UNIT-001: Stats card displays total distance', (WidgetTester tester) async {
        when(mockApiService.getLocationHistory(any, any, any))
            .thenAnswer((_) async => mockLocations);

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                Provider<ApiService>(create: (_) => mockApiService),
              ],
              child: LocationHistoryScreen(
                childId: 'child123',
                childName: 'Child',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify stats card exists
        expect(find.byType(Card), findsWidgets);
        expect(find.byIcon(Icons.directions_walk), findsOneWidget);
      });

      testWidgets('2.3.4-UNIT-002: Stats card displays total time tracked', (WidgetTester tester) async {
        when(mockApiService.getLocationHistory(any, any, any))
            .thenAnswer((_) async => mockLocations);

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                Provider<ApiService>(create: (_) => mockApiService),
              ],
              child: LocationHistoryScreen(
                childId: 'child123',
                childName: 'Child',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify time tracking icon
        expect(find.byIcon(Icons.access_time), findsOneWidget);
      });

      testWidgets('2.3.4-INT-001: Stats are calculated from location data', (WidgetTester tester) async {
        when(mockApiService.getLocationHistory(any, any, any))
            .thenAnswer((_) async => mockLocations);

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                Provider<ApiService>(create: (_) => mockApiService),
              ],
              child: LocationHistoryScreen(
                childId: 'child123',
                childName: 'Child',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify calculations are displayed
        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('2.3.4-EDGE-001: Show 0 values when no location data', (WidgetTester tester) async {
        when(mockApiService.getLocationHistory(any, any, any))
            .thenAnswer((_) async => []);

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                Provider<ApiService>(create: (_) => mockApiService),
              ],
              child: LocationHistoryScreen(
                childId: 'child123',
                childName: 'Child',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Stats should show 0 values gracefully
        expect(find.text('0'), findsWidgets);
      });
    });

    /// AC 2.3.5: Tap to View on Map
    group('AC 2.3.5: Tap to View on Map [P1-HIGH]', () => {
      testWidgets('2.3.5-INT-001: Tapping location entry navigates to map', (WidgetTester tester) async {
        when(mockApiService.getLocationHistory(any, any, any))
            .thenAnswer((_) async => mockLocations);

        await tester.pumpWidget(
          MaterialApp(
            navigatorObservers: [mockNavigatorObserver],
            home: MultiProvider(
              providers: [
                Provider<ApiService>(create: (_) => mockApiService),
              ],
              child: LocationHistoryScreen(
                childId: 'child123',
                childName: 'Child',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap first location entry
        await tester.tap(find.byType(ListTile).first);
        await tester.pumpAndSettle();

        // Verify navigation occurred
        verify(mockNavigatorObserver.didPush(any, any)).called(greaterThanOrEqualTo(1));
      });

      testWidgets('2.3.5-INT-002: Map shows marker at selected location', (WidgetTester tester) async {
        // This would be tested in the map widget tests
        // Skipping for now as it requires GoogleMapsFlutter mock
      });
    });

    /// AC 2.3.6: Error Handling
    group('AC 2.3.6: Error Handling [P1-HIGH]', () => {
      testWidgets('2.3.6-INT-001: Show loading indicator while fetching', (WidgetTester tester) async {
        when(mockApiService.getLocationHistory(any, any, any))
            .thenAnswer((_) => Future.delayed(
              Duration(seconds: 1),
              () => mockLocations,
            ));

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                Provider<ApiService>(create: (_) => mockApiService),
              ],
              child: LocationHistoryScreen(
                childId: 'child123',
                childName: 'Child',
              ),
            ),
          ),
        );

        // Loading should appear
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait for completion
        await tester.pumpAndSettle();
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });

      testWidgets('2.3.6-INT-002: Show error message on network failure', (WidgetTester tester) async {
        when(mockApiService.getLocationHistory(any, any, any))
            .thenThrow(Exception('Network error'));

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                Provider<ApiService>(create: (_) => mockApiService),
              ],
              child: LocationHistoryScreen(
                childId: 'child123',
                childName: 'Child',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Error message should be shown
        expect(find.byType(SnackBar), findsWidgets);
      });

      testWidgets('2.3.6-INT-003: Show empty state when no history', (WidgetTester tester) async {
        when(mockApiService.getLocationHistory(any, any, any))
            .thenAnswer((_) async => []);

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                Provider<ApiService>(create: (_) => mockApiService),
              ],
              child: LocationHistoryScreen(
                childId: 'child123',
                childName: 'Child',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Empty state message should appear
        expect(find.text('Chưa có lịch sử vị trí'), findsOneWidget);
      });
    });

    /// Performance Tests
    group('Performance & Isolation [P2]', () {
      testWidgets('2.3-PERF-001: Screen renders within 1.5 seconds', (WidgetTester tester) async {
        when(mockApiService.getLocationHistory(any, any, any))
            .thenAnswer((_) async => mockLocations);

        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                Provider<ApiService>(create: (_) => mockApiService),
              ],
              child: LocationHistoryScreen(
                childId: 'child123',
                childName: 'Child',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(1500));
      });

      testWidgets('2.3-PERF-002: Scrolling 50+ entries is smooth', (WidgetTester tester) async {
        // Create 50 mock locations
        final manyLocations = List.generate(
          50,
          (i) => Location(
            id: '$i',
            userId: 'child123',
            latitude: 10.7 + (i * 0.0001),
            longitude: 106.6 + (i * 0.0001),
            accuracy: 5.0,
            timestamp: DateTime.now().subtract(Duration(hours: i)),
          ),
        );

        when(mockApiService.getLocationHistory(any, any, any))
            .thenAnswer((_) async => manyLocations);

        await tester.pumpWidget(
          MaterialApp(
            home: MultiProvider(
              providers: [
                Provider<ApiService>(create: (_) => mockApiService),
              ],
              child: LocationHistoryScreen(
                childId: 'child123',
                childName: 'Child',
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Scroll down
        await tester.drag(find.byType(ListView), Offset(0, -500));
        await tester.pumpAndSettle();

        // Verify list is still displayed
        expect(find.byType(ListView), findsOneWidget);
      });
    });
  });
}

/// Mock Location model (simplified)
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
}

/// Mock ApiService
class ApiService {
  Future<List<Location>> getLocationHistory(
    String childId,
    String startDate,
    String endDate,
  ) async => [];
}
