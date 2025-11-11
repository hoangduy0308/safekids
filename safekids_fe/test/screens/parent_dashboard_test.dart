import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('Parent dashboard map', () {
    testWidgets('shows FlutterMap widget', (WidgetTester tester) async {
      await tester.pumpWidget(testApp());
      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets('renders markers for each child location', (WidgetTester tester) async {
      final locations = [
        ChildLocation('child-1', LatLng(10.8231, 106.6843)),
        ChildLocation('child-2', LatLng(10.7600, 106.6669)),
      ];

      await tester.pumpWidget(testApp(childLocations: locations));
      await tester.pumpAndSettle();

      // Each marker is represented by an Icon widget in this test scaffold
      expect(find.byIcon(Icons.location_on), findsNWidgets(locations.length));
    });

    testWidgets('renders fallback text when no children linked', (WidgetTester tester) async {
      await tester.pumpWidget(testApp(childLocations: const []));
      await tester.pumpAndSettle();

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.text('Chua có con du?c liên k?t'), findsOneWidget);
    });
  });
}

Widget testApp({List<ChildLocation> childLocations = const []}) {
  return MaterialApp(
    home: Scaffold(
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: childLocations.isNotEmpty
                    ? childLocations.first.position
                    : const LatLng(21.0285, 105.8542),
                initialZoom: 12,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.safekids.test',
                ),
                MarkerLayer(
                  markers: childLocations
                      .map(
                        (child) => Marker(
                          width: 28,
                          height: 28,
                          point: child.position,
                          child: const Icon(Icons.location_on, color: Colors.blue),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          if (childLocations.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Chua có con du?c liên k?t'),
            ),
        ],
      ),
    ),
  );
}

class ChildLocation {
  final String id;
  final LatLng position;

  const ChildLocation(this.id, this.position);
}
