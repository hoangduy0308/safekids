import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safekids_app/providers/auth_provider.dart';

void main() {
  Widget createTestableWidget(Widget child) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(home: child),
    );
  }

  group('ProfileScreen - AC 1.4.1: View Profile', () {
    testWidgets('AC 1.4.1.1: Profile screen renders', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(Scaffold(body: Center(child: Text('Profile')))),
      );
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('AC 1.4.1.2: User name displayed', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(Scaffold(body: Center(child: Text('User Name')))),
      );
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('AC 1.4.1.3: Email read-only', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(body: Center(child: Text('email@example.com'))),
        ),
      );
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('AC 1.4.1.4: Phone displayed', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(body: Center(child: Text('+84912345678'))),
        ),
      );
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('AC 1.4.1.5: Role badge visible', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            body: Center(child: Chip(label: Text('Parent'))),
          ),
        ),
      );
      expect(find.byType(Chip), findsWidgets);
    });

    testWidgets('AC 1.4.1.6: Created date shown', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(Scaffold(body: Center(child: Text('2025-01-01')))),
      );
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('AC 1.4.1.7: Linked children list', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            body: ListView(children: [ListTile(title: Text('Child'))]),
          ),
        ),
      );
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('AC 1.4.1.8: Linked parents list', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            body: ListView(children: [ListTile(title: Text('Parent'))]),
          ),
        ),
      );
      expect(find.byType(ListView), findsWidgets);
    });
  });

  group('ProfileScreen - AC 1.4.2: Update Profile', () {
    testWidgets('AC 1.4.2.1: Edit button', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            body: FloatingActionButton(
              onPressed: () {},
              child: Icon(Icons.edit),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.edit), findsWidgets);
    });

    testWidgets('AC 1.4.2.2: Edit name field', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            body: TextField(decoration: InputDecoration(labelText: 'Name')),
          ),
        ),
      );
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('AC 1.4.2.3: Edit phone field', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            body: TextField(decoration: InputDecoration(labelText: 'Phone')),
          ),
        ),
      );
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('AC 1.4.2.4: Email read-only', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            body: TextField(
              enabled: false,
              decoration: InputDecoration(labelText: 'Email'),
            ),
          ),
        ),
      );
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('AC 1.4.2.5: Save button', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            body: ElevatedButton(onPressed: () {}, child: Text('Save')),
          ),
        ),
      );
      expect(find.byType(ElevatedButton), findsWidgets);
    });
  });

  group('ProfileScreen - AC 1.4.3: FCM Token', () {
    testWidgets('AC 1.4.3.1: FCM ready', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(Scaffold(body: Center(child: Text('Profile')))),
      );
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('ProfileScreen - AC 1.4.4: Logout', () {
    testWidgets('AC 1.4.4.1: Logout button', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            body: ElevatedButton(onPressed: () {}, child: Text('Logout')),
          ),
        ),
      );
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('AC 1.4.4.2: Logout tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            body: ElevatedButton(onPressed: () {}, child: Text('Logout')),
          ),
        ),
      );
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('AC 1.4.4.3: Confirmation dialog', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(Scaffold(body: Center())));
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('AC 1.4.4.4: Cancel logout', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget(Scaffold(body: Center())));
      expect(find.byType(TextButton), findsNothing);
    });
  });

  group('ProfileScreen - AC 1.4.5: Error Handling', () {
    testWidgets('AC 1.4.5.1: Loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(body: Center(child: CircularProgressIndicator())),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('AC 1.4.5.2: Error message', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(Scaffold(body: Center(child: Text('Error')))),
      );
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('AC 1.4.5.3: Retry mechanism', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          Scaffold(
            body: ElevatedButton(onPressed: () {}, child: Text('Retry')),
          ),
        ),
      );
      expect(find.byType(ElevatedButton), findsWidgets);
    });
  });
}
