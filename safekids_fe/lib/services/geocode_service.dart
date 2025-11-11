import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GeocodeService {
  static const String _nominatimUrl =
      'https://nominatim.openstreetmap.org/reverse';

  // Cache: {lat,lon} -> address
  static final Map<String, String> _cache = {};

  /// Reverse geocode coordinates to address
  /// Returns formatted address or "lat, lon" if fails
  static Future<String> getAddress(double latitude, double longitude) async {
    try {
      final key = '$latitude,$longitude';

      // Check cache first
      if (_cache.containsKey(key)) {
        debugPrint('[Geocode] Cache hit: $key');
        return _cache[key]!;
      }

      debugPrint('[Geocode] Fetching address for: $key');

      final response = await http
          .get(
            Uri.parse(
              '$_nominatimUrl?lat=$latitude&lon=$longitude&format=json&zoom=18&addressdetails=1',
            ),
            headers: {
              'User-Agent': 'SafeKids/1.0', // Required by Nominatim
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = _parseAddress(data);

        // Cache result
        _cache[key] = address;
        debugPrint('[Geocode] Got address: $address');
        return address;
      } else {
        debugPrint('[Geocode] Error ${response.statusCode}');
        return '$latitude, $longitude';
      }
    } catch (e) {
      debugPrint('[Geocode] Error: $e');
      return '$latitude, $longitude';
    }
  }

  /// Parse Nominatim response to most detailed Vietnamese address
  static String _parseAddress(Map<String, dynamic> data) {
    try {
      final address = data['address'] ?? {};
      final List<String> parts = [];

      // 1. House number + Road (most specific)
      if (address['house_number'] != null && address['road'] != null) {
        parts.add('${address['house_number']} ${address['road']}');
      } else if (address['road'] != null) {
        parts.add(address['road']);
      } else if (address['house_number'] != null) {
        parts.add(address['house_number']);
      }

      // 2. Hamlet/Village (if available)
      if (address['hamlet'] != null) {
        parts.add(address['hamlet']);
      }

      // 3. Suburb/Quarter
      if (address['suburb'] != null) {
        parts.add(address['suburb']);
      } else if (address['quarter'] != null) {
        parts.add(address['quarter']);
      }

      // 4. City District (Quận/Huyện)
      if (address['city_district'] != null) {
        parts.add(address['city_district']);
      } else if (address['district'] != null) {
        parts.add(address['district']);
      } else if (address['county'] != null) {
        parts.add(address['county']);
      }

      // 5. City (Thành phố)
      if (address['city'] != null) {
        parts.add(address['city']);
      } else if (address['town'] != null) {
        parts.add(address['town']);
      }

      // 6. Province/State (Tỉnh)
      if (address['state'] != null) {
        parts.add(address['state']);
      } else if (address['province'] != null) {
        parts.add(address['province']);
      }

      // 7. Postcode
      // if (address['postcode'] != null) {
      //   parts.add(address['postcode']);
      // }

      // 8. Country (only if outside Vietnam)
      if (address['country'] != null && address['country'] != 'Việt Nam') {
        parts.add(address['country']);
      }

      if (parts.isNotEmpty) {
        final formattedAddress = parts.join(', ');
        debugPrint('[Geocode] Parsed address parts: $parts');
        return formattedAddress;
      }

      // Ultimate fallback: display_name from Nominatim
      final displayName = data['display_name'] as String?;
      if (displayName != null && displayName.isNotEmpty) {
        // Truncate display_name to reasonable length
        return displayName.length > 150
            ? '${displayName.substring(0, 150)}...'
            : displayName;
      }

      return 'Không xác định';
    } catch (e) {
      debugPrint('[Geocode] Parse error: $e');
      return 'Không xác định';
    }
  }

  /// Clear cache
  static void clearCache() {
    _cache.clear();
    debugPrint('[Geocode] Cache cleared');
  }
}
