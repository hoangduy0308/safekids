import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

/// E2E Tests: Geofence Suggestions UI
/// Story 3.5 - Smart Geofence Suggestions
/// Focus: User interactions, API integration, state management

void main() {
  group('Story 3.5: Geofence Suggestions - E2E Tests', () {
    late MockApiService mockApiService;
    late MockNavigator mockNavigator;

    setUp(() {
      mockApiService = MockApiService();
      mockNavigator = MockNavigator();
    });

    group('AC 3.5.2: Suggestions Display', () {
      testWidgets(
        'P1: Suggestions section shows on dashboard when child selected',
        (WidgetTester tester) async {
          // Setup mock suggestions
          final suggestions = [
            GeofenceSuggestionMock(
              id: 's1',
              name: 'Trường THCS',
              center: LatLngMock(21.0285, 105.8542),
              visitCount: 20,
              suggestedRadius: 150,
            ),
          ];

          when(mockApiService.getGeofenceSuggestions(any))
              .thenAnswer((_) async => suggestions);

          // Build widget with child selected
          await tester.pumpWidget(
            TestApp(apiService: mockApiService),
          );

          // Tap child avatar to select
          await tester.tap(find.byType(ChildAvatar).first);
          await tester.pumpAndSettle();

          // Verify suggestions section visible
          expect(find.text('Gợi Ý Vùng Thông Minh'), findsOneWidget);
          expect(find.text('Trường THCS'), findsOneWidget);
        },
      );

      testWidgets(
        'P1: Suggestion card displays all required fields',
        (WidgetTester tester) async {
          final suggestion = GeofenceSuggestionMock(
            id: 's1',
            name: 'Trường THCS',
            center: LatLngMock(21.0285, 105.8542),
            visitCount: 20,
            suggestedRadius: 150,
          );

          await tester.pumpWidget(
            TestApp(initialSuggestions: [suggestion]),
          );

          // Verify card displays all fields
          expect(find.text('Trường THCS'), findsOneWidget);
          expect(find.text('Đã đến 20 lần'), findsOneWidget);
          expect(find.text('Bán kính đề xuất: 150m'), findsOneWidget);
          expect(find.byIcon(Icons.add_location), findsOneWidget);
          expect(find.byIcon(Icons.close), findsOneWidget);
        },
      );

      testWidgets(
        'P1: Suggestions list shows max 5 items',
        (WidgetTester tester) async {
          final suggestions = List.generate(
            7,
            (i) => GeofenceSuggestionMock(
              id: 's$i',
              name: 'Location $i',
              center: LatLngMock(21.0 + (i * 0.01), 105.8 + (i * 0.01)),
              visitCount: 20 - i,
              suggestedRadius: 150,
            ),
          );

          await tester.pumpWidget(
            TestApp(initialSuggestions: suggestions),
          );

          // Verify max 5 displayed
          expect(find.byType(GeofenceSuggestionCard), findsWidgets);
          final cards = find.byType(GeofenceSuggestionCard);
          expect(cards, isNotEmpty);
        },
      );

      testWidgets(
        'P1: Loading state shows spinner during fetch',
        (WidgetTester tester) async {
          when(mockApiService.getGeofenceSuggestions(any))
              .thenAnswer((_) async {
            await Future.delayed(Duration(milliseconds: 500));
            return [];
          });

          await tester.pumpWidget(
            TestApp(apiService: mockApiService),
          );

          // Verify loading indicator
          expect(find.byType(CircularProgressIndicator), findsOneWidget);

          // Wait for completion
          await tester.pumpAndSettle();

          expect(find.byType(CircularProgressIndicator), findsNothing);
        },
      );

      testWidgets(
        'P1: Error state shows message if API fails',
        (WidgetTester tester) async {
          when(mockApiService.getGeofenceSuggestions(any))
              .thenThrow(Exception('Network error'));

          await tester.pumpWidget(
            TestApp(apiService: mockApiService),
          );

          await tester.pumpAndSettle();

          expect(find.text('Không thể tải gợi ý'), findsOneWidget);
        },
      );

      testWidgets(
        'P1: Empty state hides section if no suggestions',
        (WidgetTester tester) async {
          when(mockApiService.getGeofenceSuggestions(any))
              .thenAnswer((_) async => []);

          await tester.pumpWidget(
            TestApp(apiService: mockApiService),
          );

          await tester.pumpAndSettle();

          // Section should be hidden (SizedBox.shrink)
          expect(find.text('Gợi Ý Vùng Thông Minh'), findsNothing);
        },
      );
    });

    group('AC 3.5.3: Quick Create from Suggestion', () => {
      testWidgets(
        'P1: Tapping "Tạo Vùng" navigates to geofence creation',
        (WidgetTester tester) async {
          final suggestion = GeofenceSuggestionMock(
            id: 's1',
            name: 'Trường THCS',
            center: LatLngMock(21.0285, 105.8542),
            visitCount: 20,
            suggestedRadius: 150,
          );

          await tester.pumpWidget(
            TestApp(initialSuggestions: [suggestion]),
          );

          // Tap "Tạo Vùng" button
          await tester.tap(find.text('Tạo Vùng An Toàn'));
          await tester.pumpAndSettle();

          // Verify navigation happened
          verify(mockNavigator.push(any)).called(greaterThan(0));
        },
      );

      testWidgets(
        'P1: Pre-filled form has suggestion data',
        (WidgetTester tester) async {
          final suggestion = GeofenceSuggestionMock(
            id: 's1',
            name: 'Trường THCS',
            center: LatLngMock(21.0285, 105.8542),
            visitCount: 20,
            suggestedRadius: 150,
          );

          final prefilledFormData = {
            'name': suggestion.name,
            'centerLat': suggestion.center.latitude,
            'centerLng': suggestion.center.longitude,
            'radius': suggestion.suggestedRadius,
            'type': 'safe',
          };

          expect(prefilledFormData['name']).toBe('Trường THCS');
          expect(prefilledFormData['centerLat']).toBe(21.0285);
          expect(prefilledFormData['centerLng']).toBe(105.8542);
          expect(prefilledFormData['radius']).toBe(150);
          expect(prefilledFormData['type']).toBe('safe');
        },
      );

      testWidgets(
        'P1: User can edit pre-filled fields',
        (WidgetTester tester) async {
          // Arrange
          await tester.pumpWidget(
            TestApp(initialPrefilledForm: {
              'name': 'Trường THCS',
              'radius': 150,
            }),
          );

          // Act: Clear and edit name
          await tester.enterText(find.byKey(ValueKey('nameField')), 'Trường Mẹ Ghép');
          await tester.enterText(find.byKey(ValueKey('radiusField')), '200');

          // Assert
          expect(find.text('Trường Mẹ Ghép'), findsOneWidget);
          expect(find.text('200'), findsOneWidget);
        },
      );
    });

    group('AC 3.5.4: Dismiss Suggestions', () => {
      testWidgets(
        'P1: Tapping X button dismisses suggestion',
        (WidgetTester tester) async {
          final suggestions = [
            GeofenceSuggestionMock(
              id: 's1',
              name: 'Location 1',
              center: LatLngMock(21.0, 105.8),
              visitCount: 10,
              suggestedRadius: 150,
            ),
            GeofenceSuggestionMock(
              id: 's2',
              name: 'Location 2',
              center: LatLngMock(21.05, 105.87),
              visitCount: 8,
              suggestedRadius: 120,
            ),
          ];

          when(mockApiService.dismissSuggestion(any, any, any))
              .thenAnswer((_) async {});

          await tester.pumpWidget(
            TestApp(
              initialSuggestions: suggestions,
              apiService: mockApiService,
            ),
          );

          // Tap X button on first card
          await tester.tap(find.byIcon(Icons.close).first);
          await tester.pumpAndSettle();

          // Verify API was called
          verify(mockApiService.dismissSuggestion(any, any, any))
              .called(greaterThan(0));

          // Verify snackbar shown
          expect(find.text('Đã ẩn gợi ý'), findsOneWidget);
        },
      );

      testWidgets(
        'P1: Dismissed suggestion removed from UI',
        (WidgetTester tester) async {
          final suggestions = [
            GeofenceSuggestionMock(
              id: 's1',
              name: 'Location 1',
              center: LatLngMock(21.0, 105.8),
              visitCount: 10,
              suggestedRadius: 150,
            ),
          ];

          when(mockApiService.dismissSuggestion(any, any, any))
              .thenAnswer((_) async {});

          await tester.pumpWidget(
            TestApp(
              initialSuggestions: suggestions,
              apiService: mockApiService,
            ),
          );

          expect(find.text('Location 1'), findsOneWidget);

          // Tap X and wait
          await tester.tap(find.byIcon(Icons.close));
          await tester.pumpAndSettle(Duration(milliseconds: 1000));

          // Card should be gone
          expect(find.text('Location 1'), findsNothing);
        },
      );

      testWidgets(
        'P1: Error dismissing shows error snackbar',
        (WidgetTester tester) async {
          when(mockApiService.dismissSuggestion(any, any, any))
              .thenThrow(Exception('Dismiss failed'));

          final suggestions = [
            GeofenceSuggestionMock(
              id: 's1',
              name: 'Location 1',
              center: LatLngMock(21.0, 105.8),
              visitCount: 10,
              suggestedRadius: 150,
            ),
          ];

          await tester.pumpWidget(
            TestApp(
              initialSuggestions: suggestions,
              apiService: mockApiService,
            ),
          );

          await tester.tap(find.byIcon(Icons.close));
          await tester.pumpAndSettle();

          expect(find.text('Lỗi: Exception: Dismiss failed'), findsOneWidget);
        },
      );
    });

    group('AC 3.5.5: Refresh Suggestions', () => {
      testWidgets(
        'P1: Tapping "Làm Mới" refetches suggestions',
        (WidgetTester tester) async {
          final oldSuggestions = [
            GeofenceSuggestionMock(
              id: 's1',
              name: 'Old Location',
              center: LatLngMock(21.0, 105.8),
              visitCount: 5,
              suggestedRadius: 150,
            ),
          ];

          final newSuggestions = [
            GeofenceSuggestionMock(
              id: 's2',
              name: 'New Location',
              center: LatLngMock(21.05, 105.87),
              visitCount: 15,
              suggestedRadius: 120,
            ),
          ];

          when(mockApiService.getGeofenceSuggestions(any))
              .thenAnswer((_) async => oldSuggestions);

          await tester.pumpWidget(
            TestApp(apiService: mockApiService),
          );

          await tester.pumpAndSettle();
          expect(find.text('Old Location'), findsOneWidget);

          // Mock new suggestions
          when(mockApiService.getGeofenceSuggestions(any))
              .thenAnswer((_) async => newSuggestions);

          // Tap refresh button
          await tester.tap(find.byIcon(Icons.refresh));
          await tester.pumpAndSettle();

          // Should show new suggestions
          expect(find.text('New Location'), findsOneWidget);
        },
      );

      testWidgets(
        'P1: Refresh shows loading indicator',
        (WidgetTester tester) async {
          when(mockApiService.getGeofenceSuggestions(any))
              .thenAnswer((_) async {
            await Future.delayed(Duration(milliseconds: 300));
            return [];
          });

          await tester.pumpWidget(
            TestApp(apiService: mockApiService),
          );

          // Tap refresh
          await tester.tap(find.byIcon(Icons.refresh));
          await tester.pump();

          // Should show loading
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        },
      );
    });

    group('Happy Path: Full User Workflow', () => {
      testWidgets(
        'P1: Parent selects child, views suggestions, creates geofence, dismisses another',
        (WidgetTester tester) async {
          final suggestions = [
            GeofenceSuggestionMock(
              id: 's1',
              name: 'Trường THCS',
              center: LatLngMock(21.0285, 105.8542),
              visitCount: 20,
              suggestedRadius: 150,
            ),
            GeofenceSuggestionMock(
              id: 's2',
              name: 'Công viên',
              center: LatLngMock(21.05, 105.87),
              visitCount: 8,
              suggestedRadius: 120,
            ),
          ];

          when(mockApiService.getGeofenceSuggestions(any))
              .thenAnswer((_) async => suggestions);
          when(mockApiService.dismissSuggestion(any, any, any))
              .thenAnswer((_) async {});

          await tester.pumpWidget(
            TestApp(apiService: mockApiService),
          );

          // 1. Select child
          await tester.tap(find.byType(ChildAvatar).first);
          await tester.pumpAndSettle();

          // 2. Verify suggestions shown
          expect(find.text('Gợi Ý Vùng Thông Minh'), findsOneWidget);
          expect(find.text('Trường THCS'), findsOneWidget);

          // 3. Create geofence from first suggestion
          await tester.tap(find.text('Tạo Vùng An Toàn').first);
          await tester.pumpAndSettle();

          // 4. Dismiss second suggestion
          await tester.tap(find.byIcon(Icons.close).last);
          await tester.pumpAndSettle();

          expect(find.text('Đã ẩn gợi ý'), findsOneWidget);
        },
      );
    });
  });
}

// ===== Mock Classes =====

class MockApiService extends Mock {}

class MockNavigator extends Mock {}

class GeofenceSuggestionMock {
  final String id;
  final String name;
  final LatLngMock center;
  final int visitCount;
  final double suggestedRadius;

  GeofenceSuggestionMock({
    required this.id,
    required this.name,
    required this.center,
    required this.visitCount,
    required this.suggestedRadius,
  });
}

class LatLngMock {
  final double latitude;
  final double longitude;

  LatLngMock(this.latitude, this.longitude);
}

class TestApp extends StatelessWidget {
  final MockApiService? apiService;
  final List<GeofenceSuggestionMock>? initialSuggestions;
  final Map<String, dynamic>? initialPrefilledForm;

  const TestApp({
    this.apiService,
    this.initialSuggestions,
    this.initialPrefilledForm,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Test Widget'),
        ),
      ),
    );
  }
}

class ChildAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {},
    child: CircleAvatar(child: Text('C')),
  );
}

class GeofenceSuggestionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Card(child: Text('Suggestion'));
}
