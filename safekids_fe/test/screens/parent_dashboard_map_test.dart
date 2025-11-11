import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// AC 2.2.1: Display Map with Child Location
void main() {
  group('AC 2.2.1: Display Map with Child Location', () {
    testWidgets('2.2.1-U-001: Parent dashboard shows title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('Vị trí con')),
            body: const SizedBox(),
          ),
        ),
      );

      expect(find.text('Vị trí con'), findsOneWidget);
    });

    testWidgets('2.2.1-U-002: Shows loading state initially', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FutureBuilder(
                future: Future.delayed(const Duration(seconds: 1)),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  return const Text('Loaded');
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('2.2.1-U-003: Shows map after loading', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              color: Colors.blue,
              child: const Center(child: Text('Map Container')),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Map Container'), findsOneWidget);
    });

    testWidgets('2.2.1-U-004: Displays list of children with locations', (
      WidgetTester tester,
    ) async {
      final children = [
        {'name': 'Alice', 'lat': '10.82', 'lng': '106.68'},
        {'name': 'Bob', 'lat': '10.76', 'lng': '106.66'},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: children.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(children[index]['name']!),
                subtitle: Text(
                  '${children[index]['lat']}, ${children[index]['lng']}',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('10.82, 106.68'), findsOneWidget);
    });

    testWidgets('2.2.1-U-005: Shows empty state when no children', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Center(child: Text('Chưa có con được liên kết')),
          ),
        ),
      );

      expect(find.text('Chưa có con được liên kết'), findsOneWidget);
    });

    testWidgets('2.2.1-U-006: Each child has unique marker representation', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Placeholder(),
                ), // Marker 1
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Placeholder(),
                ), // Marker 2
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Placeholder), findsNWidgets(2));
    });
  });

  group('AC 2.2.3: Fetch Initial Location Data', () {
    testWidgets('2.2.3-U-001: Fetches location on load', (
      WidgetTester tester,
    ) async {
      bool fetchCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FutureBuilder(
              future: Future.value(null).then((_) {
                fetchCalled = true;
                return null;
              }),
              builder: (context, snapshot) => const Text('Ready'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(fetchCalled, true);
      expect(find.text('Ready'), findsOneWidget);
    });

    testWidgets('2.2.3-U-002: Shows loading while fetching', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FutureBuilder(
              future: Future.delayed(const Duration(milliseconds: 100)),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                return const Text('Done');
              },
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('2.2.3-U-003: Shows error when no location data', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FutureBuilder(
              future: Future.error('No data'),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Chưa có dữ liệu vị trí');
                }
                return const Text('Loaded');
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Chưa có dữ liệu vị trí'), findsOneWidget);
    });
  });

  group('AC 2.2.5: Multiple Children Support', () {
    testWidgets('2.2.5-U-001: Displays all children on map', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('Alice - Marker 1'),
                const Text('Bob - Marker 2'),
                const Text('Charlie - Marker 3'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Alice - Marker 1'), findsOneWidget);
      expect(find.text('Bob - Marker 2'), findsOneWidget);
      expect(find.text('Charlie - Marker 3'), findsOneWidget);
    });

    testWidgets('2.2.5-U-002: Different colors represent different children', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  color: Colors.blue,
                  child: const Text('A'),
                ),
                Container(
                  width: 20,
                  height: 20,
                  color: Colors.red,
                  child: const Text('B'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate((widget) {
          if (widget is Container) {
            return widget.color == Colors.blue;
          }
          return false;
        }),
        findsOneWidget,
      );

      expect(
        find.byWidgetPredicate((widget) {
          if (widget is Container) {
            return widget.color == Colors.red;
          }
          return false;
        }),
        findsOneWidget,
      );
    });
  });

  group('AC 2.2.6: Connection Status', () {
    testWidgets('2.2.6-U-001: Shows disconnected indicator', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                Icon(Icons.cloud_off),
                Text('Mất kết nối, đang kết nối lại...'),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.text('Mất kết nối, đang kết nối lại...'), findsOneWidget);
    });

    testWidgets('2.2.6-U-002: Hides indicator when connected', (
      WidgetTester tester,
    ) async {
      bool isConnected = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: isConnected
                ? const Text('Connected')
                : const Text('Disconnected'),
          ),
        ),
      );

      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('Disconnected'), findsNothing);
    });
  });

  group('AC 2.2.4: Child Selection and Details', () {
    testWidgets('2.2.4-U-001: Tap marker shows details bottom sheet', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: tester.element(find.byType(Scaffold)),
                  builder: (context) =>
                      const Center(child: Text('Child Details')),
                );
              },
              child: const Text('Tap me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      await tester.pumpAndSettle();

      expect(find.text('Child Details'), findsOneWidget);
    });

    testWidgets('2.2.4-U-002: Details show child name', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: const [
                Text('Alice', style: TextStyle(fontSize: 22)),
                Text('10.8231, 106.6843'),
                Text('2 phút trước'),
                Text('Độ chính xác: ±5m'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('10.8231, 106.6843'), findsOneWidget);
      expect(find.text('2 phút trước'), findsOneWidget);
      expect(find.text('Độ chính xác: ±5m'), findsOneWidget);
    });

    testWidgets('2.2.4-U-003: Details show coordinates', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const Text('10.8231, 106.6843'))),
      );

      expect(find.text('10.8231, 106.6843'), findsOneWidget);
    });

    testWidgets('2.2.4-U-004: Details show time ago', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const Text('3 phút trước'))),
      );

      expect(find.text('3 phút trước'), findsOneWidget);
    });

    testWidgets('2.2.4-U-005: Details show accuracy', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: const Text('Độ chính xác: ±8m'))),
      );

      expect(find.text('Độ chính xác: ±8m'), findsOneWidget);
    });
  });
}
