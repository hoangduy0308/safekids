import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../config/environment.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../utils/path_simplifier.dart';

import '../../theme/app_typography.dart';

/// Widget hiển thị Map với flutter_map + OpenStreetMap/MapTiler
class ChildLocationMap extends StatefulWidget {
  final String? focusedChildId;
  final dynamic selectedLocation;
  final dynamic previousLocation;
  final List<dynamic>? pathLocations;
  final bool showPath;

  const ChildLocationMap({
    Key? key,
    this.focusedChildId,
    this.selectedLocation,
    this.previousLocation,
    this.pathLocations,
    this.showPath = false,
  }) : super(key: key);

  @override
  State<ChildLocationMap> createState() => _ChildLocationMapState();
}

class _ChildLocationMapState extends State<ChildLocationMap>
    with AutomaticKeepAliveClientMixin {
  static const String _osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String _mapTilerTemplate =
      'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key={key}';

  final MapController _mapController = MapController();
  final SocketService _socketService = SocketService();
  final ApiService _apiService = ApiService();
  late final String _mapTilerKey;

  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  Map<String, dynamic> _childLocations = {};
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _throttleTimer;
  bool _isThrottled = false;

  // Default position (Hanoi)
  static const LatLng _defaultCenter = LatLng(21.0285, 105.8542);

  @override
  void initState() {
    super.initState();
    _mapTilerKey = EnvironmentConfig.mapTilerApiKey;
    final tileSource = _mapTilerKey.isNotEmpty
        ? 'MapTiler'
        : 'OpenStreetMap fallback';
    debugPrint(
      '[ChildLocationMap] Tile source: $tileSource (key empty: ${_mapTilerKey.isEmpty})',
    );
    print('[MAP_MAPTILER_INIT] Starting initialization');

    if (widget.selectedLocation != null) {
      print('[INIT] selectedLocation provided, skipping _initializeMap');
      if (mounted) setState(() => _isLoading = false);
      Future.delayed(const Duration(milliseconds: 300), _drawPathIfNeeded);
    } else if (widget.showPath &&
        widget.pathLocations != null &&
        widget.pathLocations!.isNotEmpty) {
      print('[INIT] showPath=true, loading path locations');
      if (mounted) setState(() => _isLoading = false);
      Future.delayed(const Duration(milliseconds: 500), _drawPathPolyline);
    } else {
      _initializeMap();
      _setupSocketListener();
    }
  }

  @override
  void didUpdateWidget(covariant ChildLocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('[UPDATE_WIDGET] Called');

    if (widget.showPath != oldWidget.showPath ||
        widget.pathLocations != oldWidget.pathLocations) {
      print('[UPDATE_WIDGET] Path settings changed');
      if (widget.showPath &&
          widget.pathLocations != null &&
          widget.pathLocations!.isNotEmpty) {
        _drawPathPolyline();
      } else if (!widget.showPath) {
        _polylines.clear();
        if (mounted) setState(() {});
      }
    }

    if (oldWidget.selectedLocation != widget.selectedLocation ||
        oldWidget.previousLocation != widget.previousLocation) {
      print('[UPDATE_WIDGET] Location changed');
      if (widget.selectedLocation != null) {
        _drawPathIfNeeded();
      }
    }
  }

  Future<void> _initializeMap() async {
    try {
      print('[MAP_INIT] _initializeMap START');
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final linkedChildren = authProvider.user?.linkedUsersData ?? [];

      if (linkedChildren.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Chưa có con được liên kết';
          });
        }
        return;
      }

      await Future.wait(
        linkedChildren
            .where((child) {
              if (child['role'] != 'child') return false;
              if (widget.focusedChildId != null &&
                  widget.focusedChildId != child['_id'])
                return false;
              return true;
            })
            .map((child) {
              final childId = child['_id'];
              final childName = child['name'] ?? child['fullName'];
              return _fetchChildLocation(childId, childName);
            }),
      );

      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (_markers.isNotEmpty) {
        _fitMapToMarkers();
      }
    } catch (e) {
      print('[MAP_INIT] Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Lỗi tải bản đồ: $e';
        });
      }
    }
  }

  Future<void> _fetchChildLocation(String childId, String childName) async {
    try {
      final response = await _apiService.getChildLatestLocation(childId);
      if (response['success'] == true && response['data'] != null) {
        final locationData = response['data']['location'];
        if (locationData == null) return;

        final lat = (locationData['latitude'] as num).toDouble();
        final lng = (locationData['longitude'] as num).toDouble();

        final marker = Marker(
          point: LatLng(lat, lng),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showChildDetails(childId, childName, lat, lng),
            child: const Icon(Icons.location_on, color: Colors.blue, size: 32),
          ),
        );

        if (mounted) {
          setState(() {
            _markers.add(marker);
            _childLocations[childId] = {
              'name': childName,
              'lat': lat,
              'lng': lng,
              'timestamp': locationData['timestamp'],
            };
          });
        }
      }
    } catch (e) {
      print('[LOCATION] Error fetching for $childName: $e');
    }
  }

  void _setupSocketListener() {
    _socketService.onLocationUpdate = (data) {
      if (_isThrottled) return;

      _isThrottled = true;
      _throttleTimer = Timer(const Duration(seconds: 5), () {
        _isThrottled = false;
      });

      final childId = data['userId'] ?? data['childId'];
      if (childId == null) return;
      if (widget.focusedChildId != null && widget.focusedChildId != childId)
        return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final linkedChildren = authProvider.user?.linkedUsersData ?? [];
      final childData = linkedChildren.firstWhere(
        (c) => c['_id'] == childId,
        orElse: () => {},
      );
      final childName = childData['name'] ?? childData['fullName'] ?? 'Unknown';

      final lat = (data['latitude'] as num).toDouble();
      final lng = (data['longitude'] as num).toDouble();

      final marker = Marker(
        point: LatLng(lat, lng),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _showChildDetails(childId, childName, lat, lng),
          child: const Icon(Icons.location_on, color: Colors.blue, size: 32),
        ),
      );

      if (mounted) {
        setState(() {
          _markers.removeWhere(
            (m) => m.key?.toString().contains(childId) ?? false,
          );
          _markers.add(marker);
          _childLocations[childId] = {
            'name': childName,
            'lat': lat,
            'lng': lng,
            'timestamp': DateTime.now(),
          };
        });

        if (_markers.length == 1) {
          _mapController.move(LatLng(lat, lng), 16);
        } else if (_markers.length > 1) {
          _fitMapToMarkers();
        }
      }
    };
  }

  void _fitMapToMarkers() {
    if (_markers.isEmpty) return;

    double minLat = _markers[0].point.latitude;
    double maxLat = _markers[0].point.latitude;
    double minLng = _markers[0].point.longitude;
    double maxLng = _markers[0].point.longitude;

    for (var marker in _markers) {
      minLat = marker.point.latitude < minLat ? marker.point.latitude : minLat;
      maxLat = marker.point.latitude > maxLat ? marker.point.latitude : maxLat;
      minLng = marker.point.longitude < minLng
          ? marker.point.longitude
          : minLng;
      maxLng = marker.point.longitude > maxLng
          ? marker.point.longitude
          : maxLng;
    }

    // Ensure bounds are valid: if all markers have identical lat or lng,
    // expand by a tiny delta so fitBounds doesn't receive zero-area bounds.
    if (minLat == maxLat) {
      minLat = minLat - 0.0001;
      maxLat = maxLat + 0.0001;
    }
    if (minLng == maxLng) {
      minLng = minLng - 0.0001;
      maxLng = maxLng + 0.0001;
    }

    final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));

    _mapController.fitBounds(
      bounds,
      options: const FitBoundsOptions(padding: EdgeInsets.all(100)),
    );
  }

  void _showChildDetails(
    String childId,
    String childName,
    double lat,
    double lng,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(childName, style: AppTypography.h2.copyWith(fontSize: 22)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _mapController.move(LatLng(lat, lng), 16);
              },
              icon: const Icon(Icons.my_location),
              label: const Text('Xem trên bản đồ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _drawPathIfNeeded() async {
    print('[DRAW_PATH] Called');
    _polylines.clear();

    if (widget.selectedLocation == null) {
      print('[DRAW_PATH] selectedLocation is NULL');
      return;
    }

    try {
      final lat = (widget.selectedLocation!.latitude as num).toDouble();
      final lng = (widget.selectedLocation!.longitude as num).toDouble();
      final selectedPoint = LatLng(lat, lng);

      // Add selected marker
      _markers.add(
        Marker(
          point: selectedPoint,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.cyan, size: 32),
        ),
      );

      // Draw polyline if previous location exists
      if (widget.previousLocation != null) {
        final prevLat = (widget.previousLocation!.latitude as num).toDouble();
        final prevLng = (widget.previousLocation!.longitude as num).toDouble();
        final prevPoint = LatLng(prevLat, prevLng);

        _polylines.add(
          Polyline(
            points: [prevPoint, selectedPoint],
            color: Colors.blueAccent,
            strokeWidth: 3,
          ),
        );
      }

      _mapController.move(selectedPoint, 15);

      if (mounted) setState(() {});
      print('[DRAW_PATH] Complete');
    } catch (e) {
      print('[DRAW_PATH] ERROR: $e');
    }
  }

  Future<void> _drawPathPolyline() async {
    print(
      '[PATH_POLY] Called with ${widget.pathLocations?.length ?? 0} locations',
    );
    _polylines.clear();
    _markers.clear();

    if (widget.pathLocations == null || widget.pathLocations!.isEmpty) {
      print('[PATH_POLY] No path locations');
      return;
    }

    try {
      final points = <LatLng>[];
      for (var loc in widget.pathLocations!) {
        points.add(
          LatLng(
            (loc.latitude as num).toDouble(),
            (loc.longitude as num).toDouble(),
          ),
        );
      }

      if (points.isEmpty) return;

      // Bounds diagnostics for suspected invalid ordering failures
      double minLat = points.first.latitude;
      double maxLat = points.first.latitude;
      double minLng = points.first.longitude;
      double maxLng = points.first.longitude;
      for (final point in points) {
        if (point.latitude < minLat) minLat = point.latitude;
        if (point.latitude > maxLat) maxLat = point.latitude;
        if (point.longitude < minLng) minLng = point.longitude;
        if (point.longitude > maxLng) maxLng = point.longitude;
      }
      final boundsLooksAscending =
          points.first.latitude <= points.last.latitude &&
          points.first.longitude <= points.last.longitude;
      print(
        '[PATH_POLY_BOUNDS] first=${points.first}, last=${points.last}, '
        'minLat=$minLat maxLat=$maxLat minLng=$minLng maxLng=$maxLng, '
        'firstLastAscending=$boundsLooksAscending',
      );
      if (minLat >= maxLat || minLng >= maxLng) {
        print(
          '[PATH_POLY_BOUNDS_WARNING] Suspicious bounds detected. '
          'This can break LatLngBounds. totalPoints=${points.length}',
        );
      }

      // Simplify if needed
      var simplifiedPoints = points;
      if (points.length > 200) {
        print('[PATH_POLY] Simplifying from ${points.length} to ~200 points');
        simplifiedPoints = PathSimplifier.simplify(points, tolerance: 0.0001);
      }

      _polylines.add(
        Polyline(points: simplifiedPoints, color: Colors.blue, strokeWidth: 4),
      );

      // Add start & end markers
      _markers.add(
        Marker(
          point: points.first,
          width: 40,
          height: 40,
          child: const Icon(Icons.flag, color: Colors.green, size: 32),
        ),
      );

      _markers.add(
        Marker(
          point: points.last,
          width: 40,
          height: 40,
          child: const Icon(Icons.flag, color: Colors.red, size: 32),
        ),
      );

      // Fit to bounds using computed min/max (safer than first/last).
      double localMinLat = minLat;
      double localMaxLat = maxLat;
      double localMinLng = minLng;
      double localMaxLng = maxLng;

      // Defensive: expand zero-area bounds slightly
      if (localMinLat == localMaxLat) {
        localMinLat -= 0.0001;
        localMaxLat += 0.0001;
      }
      if (localMinLng == localMaxLng) {
        localMinLng -= 0.0001;
        localMaxLng += 0.0001;
      }

      final bounds = LatLngBounds(
        LatLng(localMinLat, localMinLng),
        LatLng(localMaxLat, localMaxLng),
      );

      _mapController.fitBounds(
        bounds,
        options: const FitBoundsOptions(padding: EdgeInsets.all(100)),
      );

      if (mounted) setState(() {});
      print('[PATH_POLY] Complete');
    } catch (e) {
      print('[PATH_POLY] ERROR: $e');
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.expand(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 12,
              maxZoom: 18.4,
              minZoom: 1,
            ),
            children: [
              TileLayer(
                urlTemplate: _mapTilerKey.isNotEmpty
                    ? _mapTilerTemplate.replaceFirst('{key}', _mapTilerKey)
                    : _osmTileUrl,
                userAgentPackageName: 'com.safekids.safekids_app',
                additionalOptions: _mapTilerKey.isNotEmpty
                    ? {'key': _mapTilerKey}
                    : const <String, String>{},
              ),
              PolylineLayer(polylines: _polylines),
              MarkerLayer(markers: _markers),
            ],
          ),
        ),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
        if (!_isLoading && _errorMessage != null)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red,
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _throttleTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }
}
