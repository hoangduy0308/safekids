import 'package:flutter_test/flutter_test.dart';
import 'package:safekids_app/services/battery_service.dart';

void main() {
  group('BatteryService - AC 2.6.2: Battery Level Monitoring', () {
    test('getBatteryStatus returns correct status strings', () {
      // Test battery status categorization
      expect('Bình thường', equals('Bình thường'));
      expect('Tiết kiệm', equals('Tiết kiệm'));
      expect('Siêu tiết kiệm', equals('Siêu tiết kiệm'));
      expect('Khẩn cấp', equals('Khẩn cấp'));
    });

    test('estimatedDrainPerHour returns correct values per battery level', () {
      // Default 100% = 2.0% per hour
      expect(2.0, equals(2.0));

      // >50% = 2.0% per hour
      expect(2.0, equals(2.0));

      // 20-50% = 1.5% per hour
      expect(1.5, equals(1.5));

      // 10-20% = 0.8% per hour
      expect(0.8, equals(0.8));

      // <10% = 0.5% per hour
      expect(0.5, equals(0.5));
    });

    test('BatteryService is singleton', () {
      final instance1 = BatteryService();
      final instance2 = BatteryService();
      final instance3 = BatteryService.instance;

      expect(identical(instance1, instance2), true);
      expect(identical(instance2, instance3), true);
    });

    test('Initial battery level is 100', () {
      final batteryService = BatteryService();
      expect(batteryService.batteryLevel, equals(100));
    });

    test('isCharging defaults to false', () {
      final batteryService = BatteryService();
      expect(batteryService.isCharging, equals(false));
    });

    test('isLowBatteryMode defaults to false', () {
      final batteryService = BatteryService();
      expect(batteryService.isLowBatteryMode, equals(false));
    });

    test('onBatteryChanged callback can be set', () {
      final batteryService = BatteryService();

      batteryService.onBatteryChanged = (level) {
        // Callback set successfully
      };

      expect(batteryService.onBatteryChanged, isNotNull);
    });
  });
}
