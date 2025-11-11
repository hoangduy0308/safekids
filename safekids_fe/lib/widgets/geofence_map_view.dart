import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/geofence.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'geofence_form_dialog.dart';
import 'geofence_details_sheet.dart';

class GeofenceMapView extends StatefulWidget {
  final String? focusedChildId;
  final List<User> linkedChildren;
  final String? initialFocusedGeofenceId;
  final LatLng? initialCenter;
  final bool startInDrawMode;
  final bool showDrawControls;

  const GeofenceMapView({
    Key? key,
    this.focusedChildId,
    required this.linkedChildren,
    this.initialFocusedGeofenceId,
    this.initialCenter,
    this.startInDrawMode = false,
    this.showDrawControls = true,
  }) : super(key: key);

  @override
  State<GeofenceMapView> createState() => _GeofenceMapViewState();
}

class _GeofenceMapViewState extends State<GeofenceMapView>
    with AutomaticKeepAliveClientMixin {
  final MapController _mapController = MapController();
  double _currentZoom = _defaultZoom;
  LatLng _currentCenter = _defaultCenter;
  bool _mapReady = false;
  final ApiService _apiService = ApiService();

  bool _drawMode = false;
  LatLng? _geofenceCenter;
  double _geofenceRadius = 100.0;
  LatLng? _tempCenter;
  List<Geofence> _geofences = [];
  bool _isLoading = true;
  String? _focusedGeofenceId;
  List<User> _loadedLinkedChildren = [];
  Future<void>? _childrenLoadFuture;
  bool _hasAnimatedToInitialCenter = false;

  List<User> get _availableChildren => _loadedLinkedChildren.isNotEmpty
      ? _loadedLinkedChildren
      : widget.linkedChildren;

  static const LatLng _defaultCenter = LatLng(21.0285, 105.8542);
  static const double _defaultZoom = 12;
  static const String _osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String _mapTilerUrlTemplate =
      'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key={key}';
  static const String _mapTilerKey = String.fromEnvironment(
    'MAPTILER_API_KEY',
    defaultValue: '',
  );

  String get _tileUrl => _mapTilerKey.isEmpty
      ? _osmTileUrl
      : _mapTilerUrlTemplate.replaceFirst('{key}', _mapTilerKey);

  @override
  void initState() {
    super.initState();
    _currentCenter = widget.initialCenter ?? _defaultCenter;
    _drawMode = widget.showDrawControls && widget.startInDrawMode;
    _loadGeofences();
    _loadLinkedChildrenIfNeeded();

    // If initialCenter provided, set it up and skip draw mode
    if (widget.initialCenter != null) {
      print(
        '[GeofenceMapView] InitialCenter provided: ${widget.initialCenter}',
      );
      _geofenceCenter = widget.initialCenter;
      _tempCenter = widget.initialCenter;
      _drawMode = false;

      // Trigger UI update after frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('[GeofenceMapView] Post frame callback - temp geofence ready');
      });
    }
  }

  void _onMapReady() async {
    if (_mapReady) return;
    _mapReady = true;

    if (widget.initialCenter != null && !_hasAnimatedToInitialCenter) {
      _hasAnimatedToInitialCenter = true;
      final zoomLevel = _calculateZoomLevel(_geofenceRadius);
      _currentZoom = zoomLevel;
      _currentCenter = widget.initialCenter!;
      _mapController.move(_currentCenter, zoomLevel);

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && !_drawMode && widget.initialCenter != null) {
        _showRadiusSlider();
      }
    } else {
      _mapController.move(_currentCenter, _currentZoom);
    }
  }

  Future<void> _loadLinkedChildrenIfNeeded({bool forceReload = false}) async {
    if (!forceReload) {
      if (_loadedLinkedChildren.isNotEmpty) {
        return;
      }
      if (_childrenLoadFuture != null) {
        await _childrenLoadFuture;
        return;
      }
    }

    Future<void> loader() async {
      final Map<String, User> merged = {};
      for (final child in widget.linkedChildren) {
        if (child.id.isNotEmpty) {
          merged[child.id] = child;
        }
      }

      try {
        final children = await _apiService.getMyChildren();
        print('[GeofenceMapView] Loaded ${children.length} children from API');
        for (final rawChild in children) {
          final user = _mapApiChildToUser(rawChild);
          if (user != null && user.id.isNotEmpty) {
            merged[user.id] = user;
          }
        }
      } catch (e) {
        print('[GeofenceMapView] Error loading children: ${e}');
      }

      if (mounted) {
        setState(() {
          _loadedLinkedChildren = merged.values.toList();
        });
      } else {
        _loadedLinkedChildren = merged.values.toList();
      }
    }

    _childrenLoadFuture = loader();
    try {
      await _childrenLoadFuture;
    } finally {
      _childrenLoadFuture = null;
    }
  }

  User? _mapApiChildToUser(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }
    final map = Map<String, dynamic>.from(raw);
    final dynamic idValue = map['childId'] ?? map['_id'] ?? map['id'];
    final String id = idValue?.toString() ?? '';
    final String name =
        (map['childName'] ?? map['name'] ?? map['fullName'] ?? 'Unknown')
            .toString();

    DateTime createdAt;
    final createdAtRaw = map['createdAt'];
    if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    int? age;
    final ageRaw = map['age'];
    if (ageRaw is int) {
      age = ageRaw;
    } else if (ageRaw is num) {
      age = ageRaw.toInt();
    }

    return User(
      id: id,
      name: name,
      fullName: name,
      email: map['email']?.toString() ?? '',
      phone: map['phone']?.toString(),
      role: map['role']?.toString() ?? 'child',
      age: age,
      createdAt: createdAt,
    );
  }

  Future<void> _loadGeofences() async {
    try {
      setState(() => _isLoading = true);
      print(
        '[GeofenceMapView] Loading geofences with focusedChildId: ${widget.focusedChildId}',
      );

      // Nếu không có focusedChildId, load tất cả vùng của parent
      final response = await _apiService.getGeofences(
        childId: widget.focusedChildId,
      );
      print('[GeofenceMapView] Raw response: $response');
      print('[GeofenceMapView] Response type: ${response.runtimeType}');

      // Response từ API là List
      final List<dynamic> dataList = response;

      print('[GeofenceMapView] Data list length: ${dataList.length}');

      final geofences = dataList.map((json) {
        print('[GeofenceMapView] Parsing geofence: $json');
        return Geofence.fromJson(json as Map<String, dynamic>);
      }).toList();

      print(
        '[GeofenceMapView] Successfully loaded ${geofences.length} geofences',
      );
      setState(() {
        _geofences = geofences;
        _isLoading = false;
      });

      //  NEW: Focus on initial geofence if provided
      if (widget.initialFocusedGeofenceId != null) {
        await Future.delayed(
          Duration(milliseconds: 300),
        ); // Wait for map to render
        if (mounted && _mapController != null) {
          print(
            '[GeofenceMapView] Map ready, focusing on geofence: ${widget.initialFocusedGeofenceId}',
          );
          await _focusOnGeofence(widget.initialFocusedGeofenceId!);
        } else {
          print('[GeofenceMapView] Map not ready, will skip focus');
        }
      }
      // Không auto-focus vào vùng đầu tiên - chỉ focus khi user click
      // Cách này tránh show detail sheet khi vừa vào map để tạo vùng mới
    } catch (e) {
      print('Error loading geofences: $e');
      print('Stack trace: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //  NEW: Calculate zoom level based on radius
  double _calculateZoomLevel(double radiusInMeters) {
    final maxDistance = radiusInMeters * 2.5;
    final zoomLevel = 16 - (math.log(maxDistance / 400) / math.log(2));
    return zoomLevel.clamp(10.0, 20.0);
  }

  //  NEW: Focus on specific geofence with highlight + auto-show details
  Future<void> _focusOnGeofence(String geofenceId) async {
    final geofence = _geofences.where((g) => g.id == geofenceId).firstOrNull;
    if (geofence == null) return;

    setState(() => _focusedGeofenceId = geofenceId);

    final zoomLevel = _calculateZoomLevel(geofence.radius);
    _currentZoom = zoomLevel;
    _currentCenter = geofence.latLng;
    _mapController.move(geofence.latLng, zoomLevel);

    // Auto-show details sheet after animation
    await Future.delayed(Duration(milliseconds: 500));
    if (mounted) {
      _showGeofenceDetails(geofence);
    }
  }

  List<Geofence> _visibleGeofences() {
    if (_focusedGeofenceId != null) {
      return _geofences.where((g) => g.id == _focusedGeofenceId).toList();
    }
    return _geofences;
  }

  List<Polygon> _buildGeofencePolygons() {
    final polygons = <Polygon>[];

    for (final geofence in _visibleGeofences()) {
      final color = geofence.isDangerZone ? Colors.red : Colors.green;
      final isFocused = _focusedGeofenceId == geofence.id;

      polygons.add(
        Polygon(
          points: _createCirclePoints(geofence.latLng, geofence.radius),
          isFilled: true,
          color: color.withOpacity(isFocused ? 0.35 : 0.18),
          borderColor: color,
          borderStrokeWidth: isFocused ? 3 : 1.5,
        ),
      );
    }

    if (_tempCenter != null) {
      polygons.add(
        Polygon(
          points: _createCirclePoints(_tempCenter!, _geofenceRadius),
          isFilled: true,
          color: Colors.blue.withOpacity(0.25),
          borderColor: Colors.blue,
          borderStrokeWidth: 2,
        ),
      );
    }

    return polygons;
  }

  List<Marker> _buildGeofenceMarkers() {
    final markers = <Marker>[];

    for (final geofence in _visibleGeofences()) {
      final isFocused = _focusedGeofenceId == geofence.id;
      markers.add(
        Marker(
          point: geofence.latLng,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showGeofenceDetails(geofence),
            child: Icon(
              Icons.adjust,
              color: isFocused ? Colors.orangeAccent : Colors.blueGrey,
              size: isFocused ? 32 : 24,
            ),
          ),
        ),
      );
    }

    if (_tempCenter != null) {
      markers.add(
        Marker(
          point: _tempCenter!,
          width: 36,
          height: 36,
          child: const Icon(Icons.radio_button_checked, color: Colors.blue),
        ),
      );
    }

    return markers;
  }

  List<LatLng> _createCirclePoints(LatLng center, double radius) {
    const segments = 60;
    const earthRadius = 6371000.0; // meters
    final latRad = center.latitude * math.pi / 180;
    final lngRad = center.longitude * math.pi / 180;
    final angularDistance = radius / earthRadius;

    return List<LatLng>.generate(segments, (index) {
      final bearing = 2 * math.pi * index / segments;
      final pointLat = math.asin(
        math.sin(latRad) * math.cos(angularDistance) +
            math.cos(latRad) * math.sin(angularDistance) * math.cos(bearing),
      );
      final pointLng =
          lngRad +
          math.atan2(
            math.sin(bearing) * math.sin(angularDistance) * math.cos(latRad),
            math.cos(angularDistance) - math.sin(latRad) * math.sin(pointLat),
          );
      return LatLng(pointLat * 180 / math.pi, pointLng * 180 / math.pi);
    });
  }

  Future<void> _goToMyLocation() async {
    try {
      print('[GoToMyLocation] Requesting location permission');

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cần cấp quyền truy cập vị trí')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Vui lòng cấp quyền trong cài đặt')),
        );
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      print(
        '[GoToMyLocation] Got position: ${position.latitude}, ${position.longitude}',
      );

      final target = LatLng(position.latitude, position.longitude);
      _currentCenter = target;
      _currentZoom = math.max(_currentZoom, 15);
      _mapController.move(target, _currentZoom);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã định vị vị trí của bạn')));
    } catch (e) {
      print('[GoToMyLocation] Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi định vị: $e')));
    }
  }

  void _onMapTap(LatLng position) {
    if (_drawMode) {
      setState(() {
        _geofenceCenter = position;
        _tempCenter = position;
      });
      _showRadiusSlider();
    }
  }

  void _showRadiusSlider() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Điều chỉnh bán kính',
                style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('${_geofenceRadius.toInt()}m', style: AppTypography.h2),
              Slider(
                value: _geofenceRadius,
                min: 50,
                max: 1000,
                divisions: 19,
                label: '${_geofenceRadius.toInt()}m',
                onChanged: (value) {
                  setModalState(() => _geofenceRadius = value);
                  setState(() {});
                },
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _showGeofenceForm();
                },
                child: const Text('Tiếp tục'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showGeofenceForm({Geofence? editingGeofence}) async {
    await _loadLinkedChildrenIfNeeded(forceReload: true);
    final childrenToUse = _availableChildren;

    if (childrenToUse.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chưa có trẻ em được liên kết để áp dụng vùng'),
          ),
        );
      }
      return;
    }

    print('[ShowGeofenceForm] Children count: ${childrenToUse.length}');

    await showDialog(
      context: context,
      builder: (context) => GeofenceFormDialog(
        center: editingGeofence?.latLng ?? _geofenceCenter!,
        radius: editingGeofence?.radius ?? _geofenceRadius,
        linkedChildren: childrenToUse,
        existingData: editingGeofence != null
            ? {
                'name': editingGeofence.name,
                'type': editingGeofence.type,
                'radius': editingGeofence.radius,
                'linkedChildren': editingGeofence.linkedChildren,
              }
            : null,
        onSave: (data) {
          if (editingGeofence != null) {
            _updateGeofence(editingGeofence.id, data);
          } else {
            _createGeofence(data);
          }
        },
      ),
    );
  }

  Future<void> _createGeofence(Map<String, dynamic> data) async {
    try {
      print('[CreateGeofence] Bắt đầu tạo vùng: ${data['name']}');
      print(
        '[CreateGeofence] Center: ${_geofenceCenter}, Radius: ${data['radius']}',
      );
      print('[CreateGeofence] LinkedChildren: ${data['linkedChildren']}');

      final result = await _apiService.createGeofence(
        name: data['name'],
        type: data['type'],
        centerLat: _geofenceCenter!.latitude,
        centerLng: _geofenceCenter!.longitude,
        radius: data['radius'],
        linkedChildren: data['linkedChildren'],
      );

      print('[CreateGeofence] API response: $result');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã tạo vùng ${data['name']}')));

      print('[CreateGeofence] Gọi _loadGeofences() để refresh...');
      await _loadGeofences();

      print('[CreateGeofence] Refresh xong, cập nhật UI');
      setState(() {
        _drawMode = false;
        _geofenceCenter = null;
        _tempCenter = null;
      });
      print('[CreateGeofence] Hoàn tất');
    } catch (e, stackTrace) {
      print('[CreateGeofence] LỖI: $e');
      print('[CreateGeofence] Stack trace: $stackTrace');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _updateGeofence(String id, Map<String, dynamic> data) async {
    try {
      await _apiService.updateGeofence(
        geofenceId: id,
        name: data['name'],
        type: data['type'],
        radius: data['radius'],
        linkedChildren: data['linkedChildren'],
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã cập nhật vùng')));

      _loadGeofences();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _deleteGeofence(String id) async {
    try {
      await _apiService.deleteGeofence(id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Đã xóa vùng')));
      _loadGeofences();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  void _showGeofenceDetails(Geofence geofence) {
    setState(() => _focusedGeofenceId = geofence.id);
    print(
      '[ShowGeofenceDetails] Set focus to ${geofence.name} (${geofence.id})',
    );

    _loadLinkedChildrenIfNeeded().then((_) {
      if (!mounted) return;
      final childrenNames = _getChildrenNames(geofence.linkedChildren);

      showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => GeofenceDetailsSheet(
          geofence: geofence,
          linkedChildrenNames: childrenNames,
          onEdit: () async {
            Navigator.pop(context);
            await _showGeofenceForm(editingGeofence: geofence);
          },
          onDelete: () {
            Navigator.pop(context);
            _showDeleteConfirmation(geofence);
          },
        ),
      ).then((_) {
        if (!mounted) return;
        setState(() => _focusedGeofenceId = null);
        print('[ShowGeofenceDetails] Cleared focus');
      });
    });
  }

  void _showDeleteConfirmation(Geofence geofence) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa vùng?'),
        content: Text('Bạn có chắc muốn xóa vùng "${geofence.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteGeofence(geofence.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Xóa',
              style: AppTypography.button.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getChildrenNames(List<String> childIds) {
    final available = _availableChildren;
    return available
        .where((child) => childIds.contains(child.id))
        .map((child) => {'name': child.name, 'id': child.id})
        .toList();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Add this line
    return Scaffold(
      appBar: AppBar(
        title: Text(_drawMode ? 'Vẽ Vùng Mới' : 'Quản Lý Vùng'),
        backgroundColor: _drawMode ? Colors.blue : AppColors.parentPrimaryLight,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter ?? _currentCenter,
              initialZoom: widget.initialCenter != null
                  ? _calculateZoomLevel(_geofenceRadius)
                  : _currentZoom,
              minZoom: 3,
              maxZoom: 19,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: widget.showDrawControls
                  ? (tapPosition, position) => _onMapTap(position)
                  : null,
              onMapReady: _onMapReady,
              onPositionChanged: (camera, hasGesture) {
                final newZoom = camera.zoom;
                final newCenter = camera.center;

                if (newZoom == null || newCenter == null) {
                  debugPrint(
                    '[GeofenceMapView] Null camera payload received: zoom=$newZoom, center=$newCenter',
                  );
                }

                if (newZoom != null) {
                  _currentZoom = newZoom;
                }
                if (newCenter != null) {
                  _currentCenter = newCenter;
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _tileUrl,
                userAgentPackageName: 'com.safekids.safekids_app',
              ),
              PolygonLayer(polygons: _buildGeofencePolygons()),
              MarkerLayer(markers: _buildGeofenceMarkers()),
            ],
          ),
          if (_isLoading) Center(child: CircularProgressIndicator()),
          // Status indicator + Create zone toggle
          if (widget.showDrawControls)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(blurRadius: 4, color: Colors.black12),
                      ],
                    ),
                    child: Text(
                      'Zones: ${_geofences.length + (_tempCenter != null ? 1 : 0)}',
                      style: AppTypography.captionSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (!_drawMode)
                    GestureDetector(
                      onTap: () => setState(() => _drawMode = true),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.parentPrimaryLight,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(blurRadius: 4, color: Colors.black12),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_location,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Vẽ vùng',
                              style: AppTypography.captionSmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () => setState(() => _drawMode = false),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(blurRadius: 4, color: Colors.black12),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.close, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Hủy',
                              style: AppTypography.captionSmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (_drawMode && widget.showDrawControls)
            Positioned(
              top: 70,
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Nhấn vào bản đồ để chọn tâm vùng',
                  style: AppTypography.body.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          // Zoom controls + location button (repositioned to avoid collision)
          Positioned(
            bottom: 80,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  backgroundColor: Colors.white,
                  onPressed: () {
                    setState(() {
                      _currentZoom = (_currentZoom + 1).clamp(3.0, 19.0);
                      _mapController.move(_currentCenter, _currentZoom);
                    });
                  },
                  child: Icon(Icons.add, color: AppColors.parentPrimaryLight),
                ),
                SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  backgroundColor: Colors.white,
                  onPressed: () {
                    setState(() {
                      _currentZoom = (_currentZoom - 1).clamp(3.0, 19.0);
                      _mapController.move(_currentCenter, _currentZoom);
                    });
                  },
                  child: Icon(
                    Icons.remove,
                    color: AppColors.parentPrimaryLight,
                  ),
                ),
                SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'my_location',
                  backgroundColor: Colors.white,
                  onPressed: _goToMyLocation,
                  child: Icon(
                    Icons.my_location,
                    color: AppColors.parentPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
