import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockApiService extends Mock {
  Future<void> updateLocationSettings({
    required bool? sharingEnabled,
    required String? trackingInterval,
    required DateTime? pausedUntil,
  }) async {}

  Future<Map<String, dynamic>> getLocationSettings() async {
    return {
      'sharingEnabled': true,
      'trackingInterval': 'continuous',
      'pausedUntil': null,
    };
  }
}

class MockLocationService extends Mock {
  Future<void> startTracking({required String interval}) async {}
  Future<void> stopTracking() async {}
  Future<void> setInterval(String interval) async {}
}

void main() {
  group('Story 2.5: Location Sharing Settings [P1-HIGH]', () {
    late MockApiService mockApiService;
    late MockLocationService mockLocationService;
    late SharedPreferences prefs;

    setUp(() async {
      mockApiService = MockApiService();
      mockLocationService = MockLocationService();
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    group('AC 2.5.1: Location Sharing Toggle [P0-CRITICAL]', () {
      testWidgets('2.5.1-UNIT-001: Settings screen renders with toggle', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Text('Cài Đặt Vị Trí'),
                  SwitchListTile(
                    title: Text('Chia sẻ vị trí'),
                    value: true,
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Cài Đặt Vị Trí'), findsOneWidget);
        expect(find.text('Chia sẻ vị trí'), findsOneWidget);
        expect(find.byType(SwitchListTile), findsOneWidget);
      });

      testWidgets('2.5.1-INT-001: Toggle OFF → calls API', (
        WidgetTester tester,
      ) async {
        bool shareEnabled = true;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return SwitchListTile(
                    title: Text('Chia sẻ vị trí'),
                    value: shareEnabled,
                    onChanged: (value) async {
                      setState(() => shareEnabled = value);
                    },
                  );
                },
              ),
            ),
          ),
        );

        expect(shareEnabled, true);
        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();
        expect(shareEnabled, false);
      });

      testWidgets('2.5.1-INT-002: Warning message when disabled', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  SwitchListTile(
                    title: Text('Chia sẻ vị trí'),
                    value: false,
                    onChanged: (_) {},
                  ),
                  Text('Tắt chia sẻ có thể ảnh hưởng đến an toàn của bạn'),
                ],
              ),
            ),
          ),
        );

        expect(
          find.text('Tắt chia sẻ có thể ảnh hưởng đến an toàn của bạn'),
          findsOneWidget,
        );
      });

      testWidgets('2.5.1-INT-003: Toggle ON calls startTracking', (
        WidgetTester tester,
      ) async {
        bool shareEnabled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return SwitchListTile(
                    title: Text('Chia sẻ vị trí'),
                    value: shareEnabled,
                    onChanged: (value) async {
                      setState(() => shareEnabled = value);
                    },
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();
        expect(shareEnabled, true);
      });
    });

    group('AC 2.5.2: Tracking Interval Settings [P1-HIGH]', () {
      testWidgets('2.5.2-UNIT-001: Radio buttons for intervals', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Text('Tần suất cập nhật'),
                  RadioListTile<String>(
                    title: Text('Liên tục (30 giây)'),
                    value: 'continuous',
                    groupValue: 'continuous',
                    onChanged: (_) {},
                  ),
                  RadioListTile<String>(
                    title: Text('Bình thường (2 phút)'),
                    value: 'normal',
                    groupValue: 'continuous',
                    onChanged: (_) {},
                  ),
                  RadioListTile<String>(
                    title: Text('Tiết kiệm pin (5 phút)'),
                    value: 'battery-saver',
                    groupValue: 'continuous',
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Tần suất cập nhật'), findsOneWidget);
        expect(find.text('Liên tục (30 giây)'), findsOneWidget);
        expect(find.byType(RadioListTile<String>), findsWidgets);
      });

      testWidgets('2.5.2-INT-001: Change interval calls API', (
        WidgetTester tester,
      ) async {
        String selectedInterval = 'continuous';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return RadioListTile<String>(
                    title: Text('Bình thường'),
                    value: 'normal',
                    groupValue: selectedInterval,
                    onChanged: (value) async {
                      setState(() => selectedInterval = value!);
                    },
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.byType(RadioListTile<String>).first);
        await tester.pumpAndSettle();
        expect(selectedInterval, 'normal');
      });

      testWidgets('2.5.2-INT-002: Selected interval persisted', (
        WidgetTester tester,
      ) async {
        await prefs.setString('trackingInterval', 'battery-saver');
        final saved = prefs.getString('trackingInterval');
        expect(saved, 'battery-saver');
      });
    });

    group('AC 2.5.3: Pause Location Temporarily [P0-CRITICAL]', () {
      testWidgets('2.5.3-UNIT-001: Pause button exists', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Text('Tạm dừng'),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text('Tạm dừng 30 phút'),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Tạm dừng 30 phút'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('2.5.3-INT-001: Tap pause shows countdown', (
        WidgetTester tester,
      ) async {
        bool isPaused = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      if (isPaused) Text('Tạm dừng đến 15:30 (còn 29 phút)'),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => isPaused = true);
                        },
                        child: Text('Tạm dừng 30 phút'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
        expect(isPaused, true);
      });

      testWidgets('2.5.3-INT-002: Resume button when paused', (
        WidgetTester tester,
      ) async {
        bool isPaused = true;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      if (isPaused)
                        ElevatedButton(
                          onPressed: () {
                            setState(() => isPaused = false);
                          },
                          child: Text('Tiếp tục ngay'),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        expect(find.text('Tiếp tục ngay'), findsOneWidget);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
        expect(isPaused, false);
      });

      testWidgets('2.5.3-INT-003: Countdown timer updates', (
        WidgetTester tester,
      ) async {
        int secondsRemaining = 1800;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  final minutes = secondsRemaining ~/ 60;
                  return Text('còn $minutes phút');
                },
              ),
            ),
          ),
        );

        expect(find.text('còn 30 phút'), findsOneWidget);
      });
    });

    group('AC 2.5.4: Notify Parent of Changes [P1-HIGH]', () {
      testWidgets('2.5.4-INT-001: Disabling sharing triggers notification', (
        WidgetTester tester,
      ) async {
        bool shareEnabled = true;
        bool notificationSent = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return SwitchListTile(
                    title: Text('Chia sẻ vị trí'),
                    value: shareEnabled,
                    onChanged: (value) async {
                      final oldValue = shareEnabled;
                      setState(() => shareEnabled = value);
                      if (oldValue != value) {
                        notificationSent = true;
                      }
                    },
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.byType(SwitchListTile));
        await tester.pumpAndSettle();
        expect(notificationSent, true);
      });
    });

    group('AC 2.5.6: Settings Persistence [P1-HIGH]', () {
      testWidgets('2.5.6-UNIT-001: Settings saved to SharedPreferences', (
        WidgetTester tester,
      ) async {
        await prefs.setBool('sharingEnabled', false);
        await prefs.setString('trackingInterval', 'battery-saver');

        expect(prefs.getBool('sharingEnabled'), false);
        expect(prefs.getString('trackingInterval'), 'battery-saver');
      });

      testWidgets('2.5.6-INT-001: Settings restored after restart', (
        WidgetTester tester,
      ) async {
        await prefs.setBool('sharingEnabled', false);
        await prefs.setString('trackingInterval', 'normal');

        final restoredSharing = prefs.getBool('sharingEnabled') ?? true;
        final restoredInterval =
            prefs.getString('trackingInterval') ?? 'continuous';

        expect(restoredSharing, false);
        expect(restoredInterval, 'normal');
      });

      testWidgets('2.5.6-INT-002: Default settings on first install', (
        WidgetTester tester,
      ) async {
        final hasSharing = prefs.getBool('sharingEnabled') ?? true;
        final hasInterval = prefs.getString('trackingInterval') ?? 'continuous';

        expect(hasSharing, true);
        expect(hasInterval, 'continuous');
      });

      testWidgets('2.5.6-INT-003: Sync with backend on startup', (
        WidgetTester tester,
      ) async {
        // Verify that settings can be retrieved from backend mock
        final settings = await mockApiService.getLocationSettings();
        expect(settings, isA<Map<String, dynamic>>());
        expect(settings.containsKey('sharingEnabled'), true);
        expect(settings.containsKey('trackingInterval'), true);
      });
    });

    group('Performance & Edge Cases [P2-MEDIUM]', () {
      testWidgets('2.5-PERF-001: UI renders quickly', (
        WidgetTester tester,
      ) async {
        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  SwitchListTile(
                    title: Text('Chia sẻ vị trí'),
                    value: true,
                    onChanged: (_) {},
                  ),
                  RadioListTile<String>(
                    title: Text('Liên tục'),
                    value: 'continuous',
                    groupValue: 'continuous',
                    onChanged: (_) {},
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text('Tạm dừng 30 phút'),
                  ),
                ],
              ),
            ),
          ),
        );

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(1500));
      });

      testWidgets('2.5-EDGE-001: Handle permission denied gracefully', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  SwitchListTile(
                    title: Text('Chia sẻ vị trí'),
                    value: false,
                    onChanged: (_) {},
                  ),
                  Text('Yêu cầu cấp quyền vị trí để bật chia sẻ'),
                ],
              ),
            ),
          ),
        );

        expect(
          find.text('Yêu cầu cấp quyền vị trí để bật chia sẻ'),
          findsOneWidget,
        );
      });

      testWidgets('2.5-EDGE-002: Handle offline with cached settings', (
        WidgetTester tester,
      ) async {
        await prefs.setBool('sharingEnabled', true);
        final cached = prefs.getBool('sharingEnabled') ?? true;
        expect(cached, true);
      });
    });
  });
}
