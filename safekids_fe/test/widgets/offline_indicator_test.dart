import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safekids_app/widgets/common/offline_indicator.dart';

void main() {
  group('Offline Indicator Widget Tests', () {
    group('2.1.5-I-002: UI Indicator Shows Queue', () {
      testWidgets('should display OfflineIndicator when offline', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OfflineIndicator(
                isOffline: true,
                queuedLocations: 5,
                isSyncing: false,
              ),
            ),
          ),
        );

        expect(find.byType(OfflineIndicator), findsOneWidget);
      });

      testWidgets('should display queue count text', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OfflineIndicator(
                isOffline: true,
                queuedLocations: 5,
                isSyncing: false,
              ),
            ),
          ),
        );

        expect(find.text('5 vị trí chưa gửi'), findsOneWidget);
      });

      testWidgets('should display cloud icon', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OfflineIndicator(
                isOffline: true,
                queuedLocations: 5,
                isSyncing: false,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      });

      testWidgets('should display sync status when syncing', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OfflineIndicator(
                isOffline: false,
                queuedLocations: 3,
                isSyncing: true,
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });

    group('2.1.5-I-003: UI Syncs When Online', () {
      testWidgets('should hide indicator when online and queue empty', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OfflineIndicator(
                isOffline: false,
                queuedLocations: 0,
                isSyncing: false,
              ),
            ),
          ),
        );

        // Should be hidden or not visible
        expect(find.byType(Visibility), findsWidgets);
      });

      testWidgets('should show indicator when queue has items', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OfflineIndicator(
                isOffline: false,
                queuedLocations: 2,
                isSyncing: true,
              ),
            ),
          ),
        );

        expect(find.text('2 vị trí chưa gửi'), findsOneWidget);
      });

      testWidgets('should update queue count dynamically', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: Column(
                    children: [
                      OfflineIndicator(
                        isOffline: false,
                        queuedLocations: 5,
                        isSyncing: false,
                      ),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: Text('Update'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );

        expect(find.text('5 vị trí chưa gửi'), findsOneWidget);

        // Simulate queue being processed
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OfflineIndicator(
                isOffline: false,
                queuedLocations: 2,
                isSyncing: false,
              ),
            ),
          ),
        );

        expect(find.text('2 vị trí chưa gửi'), findsOneWidget);
      });
    });
  });
}
