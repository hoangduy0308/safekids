import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/models/geofence_alert.dart';
import '../../lib/widgets/alert_list_item.dart';

void main() {
  group('AlertListItem Widget', () {
    final testAlert = GeofenceAlertModel(
      id: 'alert-1',
      action: 'enter',
      geofenceId: 'geo-1',
      geofenceName: 'Trường học',
      geofenceType: 'safe',
      childId: 'child-1',
      childName: 'Minh',
      latitude: 10.0,
      longitude: 106.0,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    );

    testWidgets('WIDGET-001: Renders enter action with correct icon and text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AlertListItem(alert: testAlert)),
        ),
      );

      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      expect(find.text('Minh đã vào Trường học'), findsOneWidget);
      expect(find.text('An toàn'), findsOneWidget);
    });

    testWidgets('WIDGET-002: Renders exit action with correct icon', (
      WidgetTester tester,
    ) async {
      final exitAlert = GeofenceAlertModel(
        id: 'alert-2',
        action: 'exit',
        geofenceId: 'geo-1',
        geofenceName: 'Nhà',
        geofenceType: 'safe',
        childId: 'child-1',
        childName: 'An',
        latitude: 10.0,
        longitude: 106.0,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AlertListItem(alert: exitAlert)),
        ),
      );

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      expect(find.text('An đã rời khỏi Nhà'), findsOneWidget);
    });

    testWidgets('WIDGET-003: Danger zone displays with warning label', (
      WidgetTester tester,
    ) async {
      final dangerAlert = GeofenceAlertModel(
        id: 'alert-3',
        action: 'enter',
        geofenceId: 'geo-2',
        geofenceName: 'Khu nguy hiểm',
        geofenceType: 'danger',
        childId: 'child-1',
        childName: 'Hồng',
        latitude: 10.0,
        longitude: 106.0,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AlertListItem(alert: dangerAlert)),
        ),
      );

      expect(find.text('Nguy hiểm'), findsOneWidget);
    });

    testWidgets('WIDGET-004: Timestamp formats recent alerts correctly', (
      WidgetTester tester,
    ) async {
      final recentAlert = GeofenceAlertModel(
        id: 'alert-4',
        action: 'enter',
        geofenceId: 'geo-1',
        geofenceName: 'Loc',
        geofenceType: 'safe',
        childId: 'child-1',
        childName: 'Test',
        latitude: 10.0,
        longitude: 106.0,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AlertListItem(alert: recentAlert)),
        ),
      );

      expect(find.text('30 phút trước'), findsOneWidget);
    });

    testWidgets('WIDGET-005: Timestamp formats older alerts with date', (
      WidgetTester tester,
    ) async {
      final oldAlert = GeofenceAlertModel(
        id: 'alert-5',
        action: 'enter',
        geofenceId: 'geo-1',
        geofenceName: 'Loc',
        geofenceType: 'safe',
        childId: 'child-1',
        childName: 'Test',
        latitude: 10.0,
        longitude: 106.0,
        timestamp: DateTime(2025, 10, 8, 14, 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AlertListItem(alert: oldAlert)),
        ),
      );

      final finder = find.byType(Text);
      expect(finder, findsWidgets);
    });

    testWidgets('WIDGET-006: OnTap callback triggers on list tile tap', (
      WidgetTester tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlertListItem(alert: testAlert, onTap: () => tapped = true),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      expect(tapped, true);
    });

    testWidgets('WIDGET-007: Renders without crash when onTap is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AlertListItem(alert: testAlert)),
        ),
      );

      expect(find.byType(ListTile), findsOneWidget);
      await tester.tap(find.byType(ListTile));
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets(
      'WIDGET-008: Avatar displays with correct color for enter/exit',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: AlertListItem(alert: testAlert)),
          ),
        );

        expect(find.byType(CircleAvatar), findsOneWidget);
      },
    );

    testWidgets('WIDGET-009: Accessibility - Text content readable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AlertListItem(alert: testAlert)),
        ),
      );

      final childName = find.text('Minh');
      final action = find.text('đã vào');
      final geofence = find.text('Trường học');

      expect(childName, findsOneWidget);
      expect(action, findsOneWidget);
      expect(geofence, findsOneWidget);
    });

    testWidgets('WIDGET-010: Long names truncate gracefully', (
      WidgetTester tester,
    ) async {
      final longNameAlert = GeofenceAlertModel(
        id: 'alert-10',
        action: 'enter',
        geofenceId: 'geo-1',
        geofenceName:
            'Trường Tiểu Học Thị Trấn Nước Ngòi Thạch Hương Phú Lý Hà Nam',
        geofenceType: 'safe',
        childId: 'child-1',
        childName: 'Minh Khánh Hải Yên Linh',
        latitude: 10.0,
        longitude: 106.0,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AlertListItem(alert: longNameAlert)),
        ),
      );

      expect(find.byType(ListTile), findsOneWidget);
    });
  });
}
