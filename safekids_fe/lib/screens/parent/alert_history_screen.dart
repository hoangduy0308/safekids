import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../models/geofence_alert.dart';
import '../../widgets/alert_list_item.dart';
import '../../widgets/alert_detail_sheet.dart';
import '../../theme/app_colors.dart';

class AlertHistoryScreen extends StatefulWidget {
  const AlertHistoryScreen({super.key});
  @override
  State<AlertHistoryScreen> createState() => _AlertHistoryScreenState();
}

class _AlertHistoryScreenState extends State<AlertHistoryScreen> {
  final ScrollController _controller = ScrollController();
  final int _limit = 50;
  int _skip = 0;
  bool _loading = false;
  bool _hasMore = true;
  String _datePreset = 'today';
  String? _childId;
  String? _geofenceId;
  List<Map<String, dynamic>> _children = const [];
  DateTime? _customStart;
  DateTime? _customEnd;
  final List<GeofenceAlertModel> _alerts = [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _controller.addListener(_onScroll);
  }

  Future<void> _bootstrap() async {
    await _loadChildren();
    await _fetchInitial();
  }

  Future<void> _loadChildren() async {
    try {
      final kids = await ApiService().getMyChildren();
      if (mounted)
        setState(() {
          _children = kids;
        });
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_controller.position.pixels >=
        _controller.position.maxScrollExtent - 200) {
      if (_hasMore && !_loading) _fetchMore();
    }
  }

  Future<void> _fetchInitial() async {
    setState(() {
      _alerts.clear();
      _skip = 0;
      _hasMore = true;
    });
    await _fetch();
  }

  Future<void> _fetchMore() async {
    await _fetch();
  }

  Map<String, String?> _range() {
    DateTime? start;
    final end = DateTime.now();
    switch (_datePreset) {
      case 'today':
        start = end.subtract(const Duration(hours: 24));
        break;
      case '7':
        start = end.subtract(const Duration(days: 7));
        break;
      case '30':
        start = end.subtract(const Duration(days: 30));
        break;
      case 'custom':
        start = _customStart;
        return {
          'start': _customStart?.toIso8601String(),
          'end': (_customEnd ?? end).toIso8601String(),
        };
      default:
        start = null;
        break;
    }
    return {'start': start?.toIso8601String(), 'end': end.toIso8601String()};
  }

  Future<void> _fetch() async {
    if (_loading) return;
    setState(() {
      _loading = true;
    });
    final r = _range();
    try {
      final data = await ApiService().getGeofenceAlerts(
        startDate: r['start'],
        endDate: r['end'],
        childId: _childId,
        geofenceId: _geofenceId,
        limit: _limit,
        skip: _skip,
      );
      final list = (data['alerts'] as List)
          .map((e) => GeofenceAlertModel.fromJson(e))
          .toList();
      setState(() {
        _alerts.addAll(list);
        _skip += _limit;
        _hasMore = data['hasMore'] == true;
      });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải cảnh báo: $e')));
    } finally {
      if (mounted)
        setState(() {
          _loading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch Sử Cảnh Báo')),
      body: Column(
        children: [
          _filters(),
          const Divider(height: 1),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _filters() {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _chip('Hôm nay', 'today'),
              _chip('7 ngày', '7'),
              _chip('30 ngày', '30'),
              _chip('Tất cả', 'all'),
              _chip('Tùy chỉnh', 'custom'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _childId,
                  decoration: const InputDecoration(labelText: 'Trẻ em'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Tất cả trẻ em'),
                    ),
                    ..._children.map(
                      (c) => DropdownMenuItem(
                        value: c['childId']?.toString() ?? c['_id']?.toString(),
                        child: Text(
                          c['childName']?.toString() ??
                              c['name']?.toString() ??
                              '',
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _childId = v;
                    });
                    _fetchInitial();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  value: _geofenceId,
                  decoration: const InputDecoration(
                    labelText: 'Vùng địa phương',
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tất cả vùng')),
                  ],
                  onChanged: (v) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _geofenceId = v;
                    });
                    _fetchInitial();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, String value) {
    final selected = _datePreset == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (s) {
          HapticFeedback.lightImpact();
          if (value == 'custom' && s) {
            _pickCustomRange();
            return;
          }
          setState(() {
            _datePreset = value;
          });
          _fetchInitial();
        },
        selectedColor: AppColors.parentPrimaryLight.withOpacity(0.3),
      ),
    );
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final last7 = DateTimeRange(
      start: now.subtract(const Duration(days: 7)),
      end: now,
    );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _customStart != null && _customEnd != null
          ? DateTimeRange(start: _customStart!, end: _customEnd!)
          : last7,
      helpText: 'Chọn khoảng ngày',
      confirmText: 'Áp dụng',
      cancelText: 'Hủy',
    );
    if (picked != null) {
      setState(() {
        _customStart = DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        );
        _customEnd = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
        _datePreset = 'custom';
      });
      await _fetchInitial();
    }
  }

  Widget _buildList() {
    if (_alerts.isEmpty && _loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_alerts.isEmpty) {
      return const Center(child: Text('Không có cảnh báo'));
    }
    return ListView.builder(
      controller: _controller,
      itemCount: _alerts.length + (_hasMore ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == _alerts.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final a = _alerts[i];
        return AlertListItem(
          alert: a,
          onTap: () => showModalBottomSheet(
            context: context,
            builder: (_) => AlertDetailSheet(alert: a),
          ),
        );
      },
    );
  }
}
