import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/geofence.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../widgets/geofence_list_item.dart';
import '../../widgets/geofence_map_view.dart';
import '../../theme/app_typography.dart';

class GeofenceListScreen extends StatefulWidget {
  const GeofenceListScreen({Key? key}) : super(key: key);

  @override
  _GeofenceListScreenState createState() => _GeofenceListScreenState();
}

class _GeofenceListScreenState extends State<GeofenceListScreen> {
  final ApiService _apiService = ApiService();
  List<Geofence> _geofences = [];
  Set<String> _selectedGeofences = {};
  bool _isSelectMode = false;
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _filterActive = true;
  bool _isLoading = false;
  List<User> _linkedChildren = [];

  @override
  void initState() {
    super.initState();
    _loadGeofences();
    _loadLinkedChildren();
  }

  Future<void> _loadLinkedChildren() async {
    try {
      final children = await _apiService.getMyChildren();
      print('[GeofenceListScreen] Loaded ${children.length} children');

      for (var child in children) {
        print('[GeofenceListScreen] Raw child: $child');
        print('[GeofenceListScreen] Keys: ${child.keys}');
      }

      setState(() {
        _linkedChildren = children.map((child) {
          // API trả về childId và childName, không phải _id/name
          final id = child['childId'] ?? child['_id'] ?? child['id'] ?? '';
          final name =
              child['childName'] ??
              child['name'] ??
              child['fullName'] ??
              'Unknown';
          print('[GeofenceListScreen] Creating User: id=$id, name=$name');
          return User(
            id: id,
            name: name,
            fullName: name,
            email: child['email'] ?? '',
            phone: child['phone'],
            role: 'child',
            age: child['age'],
            createdAt: child['createdAt'] != null
                ? DateTime.parse(child['createdAt'])
                : DateTime.now(),
          );
        }).toList();
      });
    } catch (e) {
      print('[GeofenceListScreen] Error loading children: $e');
    }
  }

  Future<void> _loadGeofences() async {
    try {
      setState(() => _isLoading = true);
      final response = await _apiService.getGeofences();

      // The API returns a List<dynamic>, so we can cast it directly.
      final geofencesData = response as List<dynamic>;

      print('[GeofenceListScreen] Loaded ${geofencesData.length} geofences');

      final geofences = geofencesData
          .map((json) => Geofence.fromJson(json as Map<String, dynamic>))
          .toList();

      setState(() {
        _geofences = geofences;
        _isLoading = false;
      });
    } catch (e) {
      print('[GeofenceListScreen] Error: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải vùng: $e')));
      }
    }
  }

  List<Geofence> get _filteredGeofences {
    var filtered = _geofences
        .where((g) => _filterActive ? g.active : true)
        .toList();

    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (g) => g.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'type':
        filtered.sort((a, b) => a.type.compareTo(b.type));
        break;
    }

    return filtered;
  }

  void _openCreateGeofence() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GeofenceMapView(
          linkedChildren: _linkedChildren,
          startInDrawMode: true,
        ),
      ),
    ).then((_) {
      if (mounted) _loadGeofences();
    });
  }

  Alignment _createButtonAlignment() {
    if (_filteredGeofences.isEmpty) {
      return const Alignment(0, 0);
    }
    final count = _filteredGeofences.length;
    final double y = math.min(0.85, -0.05 + 0.18 * count);
    return Alignment(0, y);
  }

  Widget _buildCreateGeofenceButton() {
    return ElevatedButton.icon(
      onPressed: _openCreateGeofence,
      icon: const Icon(Icons.add_location_alt_outlined),
      label: const Text('Thêm vùng an toàn'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: AppTypography.button,
      ),
    );
  }

  void _toggleSelection(String geofenceId) {
    setState(() {
      if (_selectedGeofences.contains(geofenceId)) {
        _selectedGeofences.remove(geofenceId);
        if (_selectedGeofences.isEmpty) _isSelectMode = false;
      } else {
        _selectedGeofences.add(geofenceId);
        _isSelectMode = true;
      }
    });
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      if (!_isSelectMode) {
        _selectedGeofences.clear();
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedGeofences = Set.from(_filteredGeofences.map((g) => g.id));
      _isSelectMode = true;
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedGeofences.clear();
      _isSelectMode = false;
    });
  }

  Future<void> _bulkDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận Xóa'),
        content: Text(
          'Bạn có chắc muốn xóa ${_selectedGeofences.length} vùng đã chọn?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        for (final geofenceId in _selectedGeofences) {
          await _apiService.deleteGeofence(geofenceId);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa các vùng đã chọn'),
              backgroundColor: Colors.green,
            ),
          );
        }
        _deselectAll();
        _loadGeofences();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi xóa vùng: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _bulkToggleActive(bool active) async {
    try {
      for (final geofenceId in _selectedGeofences) {
        await _apiService.updateGeofenceStatus(geofenceId, active);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              active ? 'Đã kích hoạt các vùng' : 'Đã vô hiệu hóa các vùng',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      _deselectAll();
      _loadGeofences();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật vùng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search and filter bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm tên vùng...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        decoration: InputDecoration(
                          labelText: 'Sắp xếp',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'name', child: Text('Tên')),
                          DropdownMenuItem(value: 'type', child: Text('Loại')),
                        ],
                        onChanged: (value) {
                          setState(() => _sortBy = value!);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 2,
                      child: DropdownButtonFormField<bool>(
                        value: _filterActive,
                        decoration: InputDecoration(
                          labelText: 'Lọc',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: true,
                            child: Text('Đang hoạt động'),
                          ),
                          DropdownMenuItem(value: false, child: Text('Tất cả')),
                        ],
                        onChanged: (value) {
                          setState(() => _filterActive = value!);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Geofence list & create button
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredGeofences.isEmpty
                      ? const SizedBox.shrink()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(0, 140, 0, 24),
                          itemCount: _filteredGeofences.length,
                          itemBuilder: (context, index) {
                            final geofence = _filteredGeofences[index];
                            return GeofenceListItem(
                              key: Key(geofence.id),
                              geofence: geofence,
                              isSelected: _selectedGeofences.contains(
                                geofence.id,
                              ),
                              onTap: () {
                                if (_isSelectMode) {
                                  _toggleSelection(geofence.id);
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GeofenceMapView(
                                        linkedChildren: _linkedChildren,
                                        initialFocusedGeofenceId: geofence.id,
                                        showDrawControls: false,
                                      ),
                                    ),
                                  ).then((_) {
                                    if (mounted) _loadGeofences();
                                  });
                                }
                              },
                              onToggle: (isActive) {
                                // Toggle handled internally
                              },
                              onDelete: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã xóa vùng'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _loadGeofences();
                              },
                            );
                          },
                        ),
                ),
                AnimatedAlign(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  alignment: _createButtonAlignment(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildCreateGeofenceButton(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
