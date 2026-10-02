import 'dart:convert';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class LocationCoordinatesHelper {
  // Pre-mapped standard coordinates for Tamil Nadu & Indian cities/districts
  static const Map<String, LatLng> cityCoordinates = {
    // Tamil Nadu
    'chennai': LatLng(13.0827, 80.2707),
    'coimbatore': LatLng(11.0168, 76.9558),
    'madurai': LatLng(9.9252, 78.1198),
    'tiruchirappalli': LatLng(10.7905, 78.7047),
    'trichy': LatLng(10.7905, 78.7047),
    'salem': LatLng(11.6643, 78.1460),
    'tiruppur': LatLng(11.1085, 77.3411),
    'erode': LatLng(11.3410, 77.7172),
    'vellore': LatLng(12.9165, 79.1325),
    'tirunelveli': LatLng(8.7139, 77.7567),
    'thoothukudi': LatLng(8.7642, 78.1348),
    'tuticorin': LatLng(8.7642, 78.1348),
    'dindigul': LatLng(10.3673, 77.9803),
    'thanjavur': LatLng(10.7870, 79.1378),
    'ranipet': LatLng(12.9272, 79.3330),
    'kanchipuram': LatLng(12.8342, 79.7036),
    'tiruvallur': LatLng(13.1432, 79.9079),
    'karur': LatLng(10.9601, 78.0766),
    'namakkal': LatLng(11.2189, 78.1674),
    'cuddalore': LatLng(11.7480, 79.7714),
    'kanyakumari': LatLng(8.0883, 77.5385),
    'nagercoil': LatLng(8.1833, 77.4119),
    'dharmapuri': LatLng(12.1211, 78.1582),
    'krishnagiri': LatLng(12.5186, 78.2137),
    'hosur': LatLng(12.7409, 77.8253),
    'pudukkottai': LatLng(10.3797, 78.8208),
    'nagapattinam': LatLng(10.7672, 79.8449),
    'viluppuram': LatLng(11.9401, 79.4861),
    'theni': LatLng(10.0104, 77.4768),
    'virudhunagar': LatLng(9.5680, 77.9624),
    'sivaganga': LatLng(9.8433, 78.4809),
    'ramanathapuram': LatLng(9.3639, 78.8395),
    'nilgiris': LatLng(11.4102, 76.6950),
    'ooty': LatLng(11.4102, 76.6950),
    'tenkasi': LatLng(8.9594, 77.3150),
    'mayiladuthurai': LatLng(11.1075, 79.6523),
    'tirupathur': LatLng(12.4958, 78.5678),
    'kallakurichi': LatLng(11.7384, 78.9639),
    'chengalpattu': LatLng(12.6841, 79.9836),

    // Other Major Indian Metros & Hubs
    'bengaluru': LatLng(12.9716, 77.5946),
    'bangalore': LatLng(12.9716, 77.5946),
    'mumbai': LatLng(19.0760, 72.8777),
    'delhi': LatLng(28.6139, 77.2090),
    'new delhi': LatLng(28.6139, 77.2090),
    'hyderabad': LatLng(17.3850, 78.4867),
    'kochi': LatLng(9.9312, 76.2673),
    'cochin': LatLng(9.9312, 76.2673),
    'trivandrum': LatLng(8.5241, 76.9366),
    'thiruvananthapuram': LatLng(8.5241, 76.9366),
    'calicut': LatLng(11.2588, 75.7804),
    'kozhikode': LatLng(11.2588, 75.7804),
    'kolkata': LatLng(22.5726, 88.3639),
    'pune': LatLng(18.5204, 73.8567),
    'ahmedabad': LatLng(23.0225, 72.5714),
    'jaipur': LatLng(26.9124, 75.7873),
    'lucknow': LatLng(26.8467, 80.9462),
    'chandigarh': LatLng(30.7333, 76.7794),
  };

  /// Returns coordinates for given location and district, or default Chennai coordinates
  static LatLng getCoordinatesForLocation(String location, [String district = '']) {
    final searchTerms = [
      ...location.toLowerCase().split(RegExp(r'[, -]')),
      ...district.toLowerCase().split(RegExp(r'[, -]')),
    ].where((s) => s.trim().isNotEmpty).toList();

    for (var term in searchTerms) {
      if (cityCoordinates.containsKey(term)) {
        return cityCoordinates[term]!;
      }
    }

    // Try substring matching
    for (var key in cityCoordinates.keys) {
      if (location.toLowerCase().contains(key) || district.toLowerCase().contains(key)) {
        return cityCoordinates[key]!;
      }
    }

    // Default fallback: Chennai central hub
    return const LatLng(13.0827, 80.2707);
  }

  /// Calculates straight-line distance in kilometers
  static double calculateDistanceInKm(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R * asin... R = 6371 km
  }

  /// Reverse geocodes LatLng to area/city description using OpenStreetMap Nominatim
  static Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=14&addressdetails=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'AutoPartsIndia/1.0 (support@autopartsindia.com)'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['address'] != null) {
          final addr = data['address'];
          final locality = addr['suburb'] ?? addr['neighbourhood'] ?? addr['residential'] ?? addr['road'];
          final city = addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['county'] ?? addr['state_district'];
          final state = addr['state'];

          List<String> parts = [];
          if (locality != null && locality.toString().isNotEmpty) parts.add(locality.toString());
          if (city != null && city.toString().isNotEmpty) parts.add(city.toString());
          if (state != null && state.toString().isNotEmpty) parts.add(state.toString());

          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
