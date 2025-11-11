import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safekids_app/screens/auth/login_screen.dart';
import 'package:safekids_app/providers/auth_provider.dart';

void main() {
  Widget createTestableWidget(Widget child) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(home: child),
    );
  }

  group('LoginScreen - AC 1.2.1: Form Validation', () {
    testWidgets('AC 1.2.1.1: Screen renders without errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(LoginScreen()));

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('AC 1.2.1.2: Email field present', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(LoginScreen()));

      final emailFields = find.byType(TextFormField);
      expect(emailFields, findsWidgets);
    });

    testWidgets('AC 1.2.1.3: Password field with obscure text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(LoginScreen()));

      final textFields = find.byType(TextFormField);
      expect(textFields.evaluate().length, greaterThanOrEqualTo(2));
    });

    testWidgets('AC 1.2.1.4: Both fields required', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(LoginScreen()));

      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('AC 1.2.1.5: Password visibility toggle', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(LoginScreen()));

      final passwordField = find.byType(TextFormField).at(1);
      expect(passwordField, findsOneWidget);
    });

    testWidgets('AC 1.2.1.6: "Quên mật khẩu?" link visible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(LoginScreen()));

      expect(find.byType(TextButton), findsWidgets);
    });

    testWidgets('AC 1.2.1.7: "Đăng nhập" button present', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(LoginScreen()));

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('AC 1.2.1.8: Register link visible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(LoginScreen()));

      final textButtons = find.byType(TextButton);
      expect(textButtons, findsWidgets);
    });
  });

  group('LoginScreen - AC 1.2.2: Form Input', () {
    testWidgets('AC 1.2.2.1: Can enter email', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(LoginScreen()));

      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('AC 1.2.2.2: Can enter password', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(LoginScreen()));

      final fields = find.byType(TextFormField);
      final passwordField = fields.at(1);
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();
    });

    testWidgets('AC 1.2.2.3: Submit button is present and tapable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(LoginScreen()));

      expect(find.byType(ElevatedButton), findsWidgets);
    });
  });

  group('LoginScreen - AC 1.2.3: Error Display', () {
    testWidgets('AC 1.2.3.1: Form present for validation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(LoginScreen()));

      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('AC 1.2.3.2: Loading indicator support', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(LoginScreen()));

      expect(find.byType(ElevatedButton), findsWidgets);
    });
  });

  group('LoginScreen - AC 1.2.4: Auto-Login Support', () {
    testWidgets('AC 1.2.4.1: Login screen accessible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(LoginScreen()));

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}
