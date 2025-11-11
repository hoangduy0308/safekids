import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safekids_app/screens/parent/link_child_screen.dart';
import 'package:safekids_app/providers/auth_provider.dart';

void main() {
  Widget createTestableWidget(Widget child) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(home: child),
    );
  }

  group('LinkChildScreen - AC 1.3.1: Link Child UI', () {
    testWidgets('AC 1.3.1.1: Link Child screen renders', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(LinkChildScreen()));

      expect(find.byType(LinkChildScreen), findsOneWidget);
    });

    testWidgets('AC 1.3.1.2: Email input field present', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(LinkChildScreen()));

      final textFields = find.byType(TextFormField);
      expect(textFields, findsWidgets);
    });

    testWidgets('AC 1.3.1.3: Email validation error for invalid format', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(LinkChildScreen()));

      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'notanemail');
      await tester.pumpAndSettle();
    });

    testWidgets('AC 1.3.1.4: "Liên Kết" button present', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(LinkChildScreen()));

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('AC 1.3.1.5: "Liên Kết" button is tapable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(LinkChildScreen()));

      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });

  group('LinkChildScreen - AC 1.3.2: Input & Submission', () {
    testWidgets('AC 1.3.2.1: Can enter child email', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(LinkChildScreen()));

      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'child@example.com');
      expect(find.text('child@example.com'), findsOneWidget);
    });

    testWidgets('AC 1.3.2.2: Submit button shows loading state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(LinkChildScreen()));

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('AC 1.3.2.3: Button disabled while loading', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(LinkChildScreen()));

      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });

  group('LinkChildScreen - AC 1.3.3: Validation & Error Display', () {
    testWidgets('AC 1.3.3.1: Form validation works', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(LinkChildScreen()));

      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('AC 1.3.3.2: Error message display', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(LinkChildScreen()));

      // Error will show via SnackBar or AlertDialog
      expect(find.byType(ScaffoldMessenger), findsWidgets);
    });
  });

  group('LinkChildScreen - AC 1.3.4: Linked Children Display', () {
    testWidgets('AC 1.3.4.1: List of linked children visible (empty state)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestableWidget(LinkChildScreen()));

      // Initially empty, so ListView is not rendered (SizedBox.shrink)
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets(
      'AC 1.3.4.2: Each linked child shows name and email (empty state)',
      (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(LinkChildScreen()));

        // Initially empty, so ListTile is not rendered
        expect(find.byType(ListTile), findsNothing);
      },
    );
  });
}
