import 'package:flutter/material.dart';
import 'package:safekids_app/theme/app_typography.dart';

class GeofenceLayerToggle extends StatefulWidget {
  final bool showSafeZones;
  final bool showDangerZones;
  final ValueChanged<bool>? onSafeZonesChanged;
  final ValueChanged<bool>? onDangerZonesChanged;

  const GeofenceLayerToggle({
    Key? key,
    this.showSafeZones = true,
    this.showDangerZones = true,
    this.onSafeZonesChanged,
    this.onDangerZonesChanged,
  }) : super(key: key);

  @override
  _GeofenceLayerToggleState createState() => _GeofenceLayerToggleState();
}

class _GeofenceLayerToggleState extends State<GeofenceLayerToggle> {
  bool _showSafeZones = true;
  bool _showDangerZones = true;

  @override
  void initState() {
    super.initState();
    _showSafeZones = widget.showSafeZones;
    _showDangerZones = widget.showDangerZones;
  }

  @override
  void didUpdateWidget(GeofenceLayerToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showSafeZones != widget.showSafeZones) {
      _showSafeZones = widget.showSafeZones;
    }
    if (oldWidget.showDangerZones != widget.showDangerZones) {
      _showDangerZones = widget.showDangerZones;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.layers_outlined, size: 20),
                const SizedBox(width: 8),
                Text('Hiển Thị Vùng', style: AppTypography.label),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Safe zones toggle
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green.shade500,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Vùng An Toàn'),
                    const Spacer(),
                    Switch(
                      value: _showSafeZones,
                      onChanged: (value) {
                        setState(() {
                          _showSafeZones = value;
                        });
                        widget.onSafeZonesChanged?.call(value);
                      },
                      activeColor: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Danger zones toggle
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.red.shade500,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('Vùng Nguy Hiểm'),
                    const Spacer(),
                    Switch(
                      value: _showDangerZones,
                      onChanged: (value) {
                        setState(() {
                          _showDangerZones = value;
                        });
                        widget.onDangerZonesChanged?.call(value);
                      },
                      activeColor: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
