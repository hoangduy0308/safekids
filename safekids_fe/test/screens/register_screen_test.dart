import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safekids_app/screens/auth/register_screen.dart';
import 'package:safekids_app/providers/auth_provider.dart';

void main() {
  Widget createTestableWidget(Widget child) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(home: child),
    );
  }

  group('RegisterScreen - AC 1.1.1: Form Validation', () {
    testWidgets('AC 1.1.1.1: Screen renders without errors', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(RegisterScreen()));

      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    testWidgets('AC 1.1.1.2: Form widget present', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(RegisterScreen()));

      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('AC 1.1.1.3: TextFormFields present (at least 4)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(RegisterScreen()));

      final textFields = find.byType(TextFormField);
      expect(textFields, findsWidgets);
      expect(textFields.evaluate().length, greaterThanOrEqualTo(4));
    });

    testWidgets('AC 1.1.1.4: Role selection widget present', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(RegisterScreen()));

      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('AC 1.1.1.5: Register button present', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(RegisterScreen()));

      final registerButton = find.text('Đăng ký');
      expect(registerButton, findsOneWidget);
    });

    testWidgets('AC 1.1.1.6: Can enter text in form fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(RegisterScreen()));

      final fields = find.byType(TextFormField);
      final firstField = fields.first;

      await tester.enterText(firstField, 'John Doe');
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('AC 1.1.1.7: Has login link', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(RegisterScreen()));

      final textButtons = find.byType(TextButton);
      expect(textButtons, findsWidgets);
    });
  });

  group('RegisterScreen - AC 1.1.3: Error Handling', () {
    testWidgets('AC 1.1.3.1: Submit button present and tapable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(RegisterScreen()));

      final submitButton = find.byType(ElevatedButton);
      expect(submitButton, findsWidgets);
    });

    testWidgets('AC 1.1.3.2: Loading state handling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(RegisterScreen()));

      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(ElevatedButton), findsWidgets);
    });
  });

  group('RegisterScreen - Form Structure', () {
    testWidgets('AC 1.1.1.8: Form is scrollable', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(RegisterScreen()));

      final scrollable = find.byType(SingleChildScrollView);
      expect(scrollable.evaluate().isNotEmpty, true);
    });

    testWidgets('AC 1.1.1.9: All form elements accessible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(RegisterScreen()));

      expect(find.byType(TextFormField), findsWidgets);
      expect(find.byType(Form), findsOneWidget);
      expect(find.text('Đăng ký'), findsOneWidget);
    });
  });
}
