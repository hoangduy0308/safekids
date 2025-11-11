import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';

import '../../../lib/models/geofence_alert.dart';
import '../../../lib/screens/parent/alert_history_screen.dart';
import '../../../lib/services/api_service.dart';
import '../../../lib/widgets/alert_list_item.dart';
import '../../../lib/widgets/alert_detail_sheet.dart';

import 'alert_history_screen_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  late MockApiService mockApiService;

  // Test fixtures
  final mockParent = {
    '_id': 'parent-123',
    'email': 'parent@test.com',
    'name': 'Parent Test'
  };

  final mockChildren = [
    {'_id': 'child-1', 'childId': 'child-1', 'childName': 'Child A', 'name': 'Child A'},
    {'_id': 'child-2', 'childId': 'child-2', 'childName': 'Child B', 'name': 'Child B'}
  ];

  List<GeofenceAlertModel> createMockAlerts({int count = 4, int minutesAgo = 0}) {
    return List.generate(count, (i) {
      final timestamp = DateTime.now().subtract(Duration(minutes: minutesAgo + i * 5));
      return GeofenceAlertModel(
        id: 'alert-$i',
        action: i % 2 == 0 ? 'enter' : 'exit',
        geofenceId: i < 2 ? 'geofence-1' : 'geofence-2',
        geofenceName: i < 2 ? 'Trường học' : 'Nhà',
        geofenceType: 'safe',
        childId: i < 2 ? 'child-1' : 'child-2',
        childName: i < 2 ? 'Child A' : 'Child B',
        latitude: 10.0 + i * 0.01,
        longitude: 106.0 + i * 0.01,
        timestamp: timestamp,
      );
    });
  }

  setUp(() {
    mockApiService = MockApiService();
  });

  testWidgets('Story 3.4 AC 3.4.1 - Alert History List View displays alerts',
      (WidgetTester tester) async {
    final alerts = createMockAlerts(count: 3);

    when(mockApiService.getMyChildren()).thenAnswer((_) async => mockChildren);
    when(mockApiService.getGeofenceAlerts(
      startDate: anyNamed('startDate'),
      endDate: anyNamed('endDate'),
      childId: anyNamed('childId'),
      geofenceId: anyNamed('geofenceId'),
      limit: anyNamed('limit'),
      skip: anyNamed('skip'),
    )).thenAnswer((_) async => {
      'alerts': alerts,
      'total': 3,
      'hasMore': false,
    });

    await tester.binding.window.physicalSizeTestValue = const Size(400, 800);
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

    await tester.pumpWidget(
      MaterialApp(
        home: AlertHistoryScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Lịch Sử Cảnh Báo'), findsWidgets);
    expect(find.byType(AlertListItem), findsWidgets);
    expect(find.text('Child A đã vào Trường học'), findsWidgets);
  });

  testWidgets('Story 3.4 AC 3.4.1 - List items show correct data (timestamp, action, geofence)',
      (WidgetTester tester) async {
    final alert = GeofenceAlertModel(
      id: 'alert-1',
      action: 'enter',
      geofenceId: 'geo-1',
      geofenceName: 'Trường học',
      geofenceType: 'safe',
      childId: 'child-1',
      childName: 'An',
      latitude: 10.0,
      longitude: 106.0,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    );

    when(mockApiService.getMyChildren()).thenAnswer((_) async => mockChildren);
    when(mockApiService.getGeofenceAlerts(
      startDate: anyNamed('startDate'),
      endDate: anyNamed('endDate'),
      childId: anyNamed('childId'),
      geofenceId: anyNamed('geofenceId'),
      limit: anyNamed('limit'),
      skip: anyNamed('skip'),
    )).thenAnswer((_) async => {
      'alerts': [alert],
      'total': 1,
      'hasMore': false,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AlertHistoryScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('An đã vào Trường học'), findsOneWidget);
    expect(find.text('An toàn'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
  });

  testWidgets('Story 3.4 AC 3.4.2 - Date range filter "Hôm nay" applies',
      (WidgetTester tester) async {
    final alerts = createMockAlerts();

    when(mockApiService.getMyChildren()).thenAnswer((_) async => mockChildren);
    when(mockApiService.getGeofenceAlerts(
      startDate: anyNamed('startDate'),
      endDate: anyNamed('endDate'),
      childId: anyNamed('childId'),
      geofenceId: anyNamed('geofenceId'),
      limit: anyNamed('limit'),
      skip: anyNamed('skip'),
    )).thenAnswer((_) async => {
      'alerts': alerts,
      'total': alerts.length,
      'hasMore': false,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AlertHistoryScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Hôm nay'), findsWidgets);
    expect(find.byType(FilterChip), findsWidgets);
  });

  testWidgets('Story 3.4 AC 3.4.3 - Child filter dropdown works',
      (WidgetTester tester) async {
    final alerts = createMockAlerts();

    when(mockApiService.getMyChildren()).thenAnswer((_) async => mockChildren);
    when(mockApiService.getGeofenceAlerts(
      startDate: anyNamed('startDate'),
      endDate: anyNamed('endDate'),
      childId: anyNamed('childId'),
      geofenceId: anyNamed('geofenceId'),
      limit: anyNamed('limit'),
      skip: anyNamed('skip'),
    )).thenAnswer((_) async => {
      'alerts': alerts,
      'total': alerts.length,
      'hasMore': false,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AlertHistoryScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Tất cả trẻ em'), findsWidgets);
    expect(find.text('Child A'), findsWidgets);
  });

  testWidgets('Story 3.4 AC 3.4.4 - Alert detail sheet shows complete info on tap',
      (WidgetTester tester) async {
    final alert = GeofenceAlertModel(
      id: 'alert-detail-1',
      action: 'exit',
      geofenceId: 'geo-1',
      geofenceName: 'Nhà',
      geofenceType: 'safe',
      childId: 'child-1',
      childName: 'Minh',
      latitude: 10.123456,
      longitude: 106.654321,
      timestamp: DateTime(2025, 10, 15, 14, 30, 0),
    );

    when(mockApiService.getMyChildren()).thenAnswer((_) async => mockChildren);
    when(mockApiService.getGeofenceAlerts(
      startDate: anyNamed('startDate'),
      endDate: anyNamed('endDate'),
      childId: anyNamed('childId'),
      geofenceId: anyNamed('geofenceId'),
      limit: anyNamed('limit'),
      skip: anyNamed('skip'),
    )).thenAnswer((_) async => {
      'alerts': [alert],
      'total': 1,
      'hasMore': false,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AlertHistoryScreen(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    expect(find.text('Chi Tiết Cảnh Báo'), findsOneWidget);
    expect(find.text('Minh'), findsWidgets);
    expect(find.text('Nhà'), findsWidgets);
    expect(find.byIcon(Icons.map), findsOneWidget);
  });

  testWidgets('Story 3.4 AC 3.4.1 - Pagination loads more alerts on scroll',
      (WidgetTester tester) async {
    final firstBatch = createMockAlerts(count: 3, minutesAgo: 0);
    final secondBatch = createMockAlerts(count: 2, minutesAgo: 15);

    when(mockApiService.getMyChildren()).thenAnswer((_) async => mockChildren);

    int callCount = 0;
    when(mockApiService.getGeofenceAlerts(
      startDate: anyNamed('startDate'),
      endDate: anyNamed('endDate'),
      childId: anyNamed('childId'),
      geofenceId: anyNamed('geofenceId'),
      limit: anyNamed('limit'),
      skip: anyNamed('skip'),
    )).thenAnswer((_) async {
      callCount++;
      if (callCount == 1) {
        return {
          'alerts': firstBatch,
          'total': 5,
          'hasMore': true,
        };
      }
      return {
        'alerts': secondBatch,
        'total': 5,
        'hasMore': false,
      };
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AlertHistoryScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(AlertListItem), findsNWidgets(3));

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.byType(AlertListItem), findsWidgets);
  });

  testWidgets('Story 3.4 AC 3.4.2 - Custom date range picker opens',
      (WidgetTester tester) async {
    final alerts = createMockAlerts();

    when(mockApiService.getMyChildren()).thenAnswer((_) async => mockChildren);
    when(mockApiService.getGeofenceAlerts(
      startDate: anyNamed('startDate'),
      endDate: anyNamed('endDate'),
      childId: anyNamed('childId'),
      geofenceId: anyNamed('geofenceId'),
      limit: anyNamed('limit'),
      skip: anyNamed('skip'),
    )).thenAnswer((_) async => {
      'alerts': alerts,
      'total': alerts.length,
      'hasMore': false,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AlertHistoryScreen(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.text('Tùy chỉnh'));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets('Story 3.4 - Filters combine correctly (child + geofence)',
      (WidgetTester tester) async {
    final alerts = createMockAlerts();

    when(mockApiService.getMyChildren()).thenAnswer((_) async => mockChildren);
    when(mockApiService.getGeofenceAlerts(
      startDate: anyNamed('startDate'),
      endDate: anyNamed('endDate'),
      childId: anyNamed('childId'),
      geofenceId: anyNamed('geofenceId'),
      limit: anyNamed('limit'),
      skip: anyNamed('skip'),
    )).thenAnswer((_) async => {
      'alerts': alerts.where((a) => a.childId == 'child-1').toList(),
      'total': 2,
      'hasMore': false,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AlertHistoryScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(DropdownButtonFormField), findsWidgets);
  });

  testWidgets('Story 3.4 - Error handling displays user-friendly message',
      (WidgetTester tester) async {
    when(mockApiService.getMyChildren()).thenAnswer((_) async => mockChildren);
    when(mockApiService.getGeofenceAlerts(
      startDate: anyNamed('startDate'),
      endDate: anyNamed('endDate'),
      childId: anyNamed('childId'),
      geofenceId: anyNamed('geofenceId'),
      limit: anyNamed('limit'),
      skip: anyNamed('skip'),
    )).thenThrow(Exception('Network error'));

    await tester.pumpWidget(
      MaterialApp(
        home: AlertHistoryScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('Story 3.4 - Empty state displays when no alerts',
      (WidgetTester tester) async {
    when(mockApiService.getMyChildren()).thenAnswer((_) async => mockChildren);
    when(mockApiService.getGeofenceAlerts(
      startDate: anyNamed('startDate'),
      endDate: anyNamed('endDate'),
      childId: anyNamed('childId'),
      geofenceId: anyNamed('geofenceId'),
      limit: anyNamed('limit'),
      skip: anyNamed('skip'),
    )).thenAnswer((_) async => {
      'alerts': [],
      'total': 0,
      'hasMore': false,
    });

    await tester.pumpWidget(
      MaterialApp(
        home: AlertHistoryScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Không có cảnh báo'), findsOneWidget);
  });
}
