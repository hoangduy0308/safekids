/// Location Settings model (Task 2.5)
class LocationSettings {
  final bool sharingEnabled;
  final String trackingInterval; // 'continuous', 'normal', 'battery-saver'
  final DateTime? pausedUntil;

  LocationSettings({
    required this.sharingEnabled,
    required this.trackingInterval,
    this.pausedUntil,
  });

  factory LocationSettings.fromJson(Map<String, dynamic> json) {
    return LocationSettings(
      sharingEnabled: json['sharingEnabled'] ?? true,
      trackingInterval: json['trackingInterval'] ?? 'continuous',
      pausedUntil: json['pausedUntil'] != null
          ? DateTime.parse(json['pausedUntil'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sharingEnabled': sharingEnabled,
      'trackingInterval': trackingInterval,
      'pausedUntil': pausedUntil?.toIso8601String(),
    };
  }
}
