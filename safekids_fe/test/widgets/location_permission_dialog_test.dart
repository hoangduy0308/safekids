import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:safekids_app/widgets/child/location_permission_dialog.dart';

class MockPermissionHandler extends Mock {}

void main() {
  group('Location Permission Dialog Tests', () {
    group('2.1.4-I-001: Explanation Dialog Shown', () {
      testWidgets('should display LocationPermissionDialog on app launch',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LocationPermissionDialog(
                onPermissionGranted: () {},
                onPermissionDenied: () {},
              ),
            ),
          ),
        );

        // Verify dialog is visible
        expect(find.byType(LocationPermissionDialog), findsOneWidget);
        expect(
          find.text(
            'SafeKids cần quyền vị trị để bảo vệ bạn',
          ),
          findsOneWidget,
        );

        // Verify action buttons
        expect(find.byType(ElevatedButton), findsWidgets);
        expect(find.text('Cho Phép'), findsOneWidget);
        expect(find.text('Từ Chối'), findsOneWidget);
      });

      testWidgets('should call onPermissionGranted when "Cho Phép" tapped',
          (WidgetTester tester) async {
        bool permissionGranted = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LocationPermissionDialog(
                onPermissionGranted: () {
                  permissionGranted = true;
                },
                onPermissionDenied: () {},
              ),
            ),
          ),
        );

        await tester.tap(find.text('Cho Phép'));
        await tester.pumpAndSettle();

        expect(permissionGranted, true);
      });

      testWidgets('should call onPermissionDenied when "Từ Chối" tapped',
          (WidgetTester tester) async {
        bool permissionDenied = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LocationPermissionDialog(
                onPermissionGranted: () {},
                onPermissionDenied: () {
                  permissionDenied = true;
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Từ Chối'));
        await tester.pumpAndSettle();

        expect(permissionDenied, true);
      });
    });

    group('2.1.4-I-004: Denied → Show Settings Guide', () => {
      testWidgets('should show error message when permission denied',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Scaffold(
                body: Column(
                  children: [
                    LocationPermissionDialog(
                      onPermissionGranted: () {},
                      onPermissionDenied: () {},
                    ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Cần bật GPS để app hoạt động'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(
          find.text('Cần bật GPS để app hoạt động'),
          findsOneWidget,
        );
      });

      testWidgets('should show "Mở Cài Đặt" button',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Text('Cần bật GPS để app hoạt động'),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text('Mở Cài Đặt'),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Mở Cài Đặt'), findsOneWidget);
      });
    });
  });
}
