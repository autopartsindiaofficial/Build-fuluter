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
    'mysore': LatLng(12.2958, 76.6394),
    'mysuru': LatLng(12.2958, 76.6394),
    'hubli': LatLng(15.3647, 75.1240),
    'mangalore': LatLng(12.9141, 74.8560),
    'mangaluru': LatLng(12.9141, 74.8560),
    'belgaum': LatLng(15.8497, 74.4977),
    'belagavi': LatLng(15.8497, 74.4977),
    'gulbarga': LatLng(17.3297, 76.8343),
    'kalaburagi': LatLng(17.3297, 76.8343),
    'davanagere': LatLng(14.4644, 75.9218),
    'bellary': LatLng(15.1394, 76.9214),
    'ballari': LatLng(15.1394, 76.9214),
    'shimoga': LatLng(13.9299, 75.5681),
    'shivamogga': LatLng(13.9299, 75.5681),
    'tumkur': LatLng(13.3379, 77.1010),
    'udupi': LatLng(13.3409, 74.7421),

    // Kerala
    'kochi': LatLng(9.9312, 76.2673),
    'cochin': LatLng(9.9312, 76.2673),
    'ernakulam': LatLng(9.9816, 76.2999),
    'trivandrum': LatLng(8.5241, 76.9366),
    'thiruvananthapuram': LatLng(8.5241, 76.9366),
    'calicut': LatLng(11.2588, 75.7804),
    'kozhikode': LatLng(11.2588, 75.7804),
    'thrissur': LatLng(10.5276, 76.2144),
    'kollam': LatLng(8.8932, 76.6141),
    'palakkad': LatLng(10.7867, 76.6548),
    'alappuzha': LatLng(9.4981, 76.3388),
    'kannur': LatLng(11.8745, 75.3704),
    'kottayam': LatLng(9.5916, 76.5222),
    'malappuram': LatLng(11.0510, 76.0711),
    'kasaragod': LatLng(12.5102, 74.9852),
    'wayanad': LatLng(11.6854, 76.1320),
    'idukki': LatLng(9.8494, 76.9710),
    'pathanamthitta': LatLng(9.2648, 76.7870),

    // Andhra Pradesh & Telangana
    'hyderabad': LatLng(17.3850, 78.4867),
    'secunderabad': LatLng(17.4399, 78.4983),
    'warangal': LatLng(17.9689, 79.5941),
    'nizamabad': LatLng(18.6725, 78.0941),
    'karimnagar': LatLng(18.4386, 79.1288),
    'khammam': LatLng(17.2473, 80.1514),
    'visakhapatnam': LatLng(17.6868, 83.2185),
    'vizag': LatLng(17.6868, 83.2185),
    'vijayawada': LatLng(16.5062, 80.6480),
    'guntur': LatLng(16.3067, 80.4365),
    'tirupati': LatLng(13.6288, 79.4192),
    'kurnool': LatLng(15.8281, 78.0373),
    'nellore': LatLng(14.4426, 79.9865),
    'kakinada': LatLng(16.9891, 82.2475),
    'rajahmundry': LatLng(17.0005, 81.8040),
    'kadapa': LatLng(14.4673, 78.8242),
    'anantapur': LatLng(14.6819, 77.6006),

    // Maharashtra & Goa
    'mumbai': LatLng(19.0760, 72.8777),
    'pune': LatLng(18.5204, 73.8567),
    'nagpur': LatLng(21.1458, 79.0882),
    'nashik': LatLng(19.9975, 73.7898),
    'aurangabad': LatLng(19.8762, 75.3433),
    'thane': LatLng(19.2183, 72.9781),
    'solapur': LatLng(17.6599, 75.9064),
    'kolhapur': LatLng(16.7050, 74.2433),
    'navi mumbai': LatLng(19.0330, 73.0297),
    'amravati': LatLng(20.9320, 77.7523),
    'nanded': LatLng(19.1383, 77.3210),
    'sangli': LatLng(16.8524, 74.5815),
    'jalgaon': LatLng(21.0077, 75.5626),
    'panaji': LatLng(15.4909, 73.8278),
    'margao': LatLng(15.2832, 73.9862),
    'goa': LatLng(15.2993, 74.1240),

    // Gujarat & Rajasthan
    'ahmedabad': LatLng(23.0225, 72.5714),
    'surat': LatLng(21.1702, 72.8311),
    'vadodara': LatLng(22.3072, 73.1812),
    'baroda': LatLng(22.3072, 73.1812),
    'rajkot': LatLng(22.3039, 70.8022),
    'bhavnagar': LatLng(21.7645, 72.1519),
    'jamnagar': LatLng(22.4707, 70.0577),
    'gandhinagar': LatLng(23.2156, 72.6369),
    'junagadh': LatLng(21.5222, 70.4579),
    'anand': LatLng(22.5645, 72.9289),
    'bharuch': LatLng(21.7051, 72.9959),
    'jaipur': LatLng(26.9124, 75.7873),
    'jodhpur': LatLng(26.2389, 73.0243),
    'kota': LatLng(25.2138, 75.8648),
    'bikaner': LatLng(28.0229, 73.3119),
    'ajmer': LatLng(26.4499, 74.6399),
    'udaipur': LatLng(24.5854, 73.7125),
    'bhilwara': LatLng(25.3475, 74.6358),
    'alwar': LatLng(27.5530, 76.6346),

    // Delhi NCR, UP & North India
    'delhi': LatLng(28.6139, 77.2090),
    'new delhi': LatLng(28.6139, 77.2090),
    'noida': LatLng(28.5355, 77.3910),
    'greater noida': LatLng(28.4744, 77.5040),
    'gurugram': LatLng(28.4595, 77.0266),
    'gurgaon': LatLng(28.4595, 77.0266),
    'faridabad': LatLng(28.4089, 77.3178),
    'ghaziabad': LatLng(28.6692, 77.4538),
    'lucknow': LatLng(26.8467, 80.9462),
    'kanpur': LatLng(26.4499, 80.3319),
    'varanasi': LatLng(25.3176, 82.9739),
    'banaras': LatLng(25.3176, 82.9739),
    'agra': LatLng(27.1767, 78.0081),
    'prayagraj': LatLng(25.4358, 81.8463),
    'allahabad': LatLng(25.4358, 81.8463),
    'meerut': LatLng(28.9845, 77.7064),
    'bareilly': LatLng(28.3670, 79.4304),
    'aligarh': LatLng(27.8974, 78.0880),
    'moradabad': LatLng(28.8386, 78.7733),
    'gorakhpur': LatLng(26.7606, 83.3732),
    'saharanpur': LatLng(29.9640, 77.5460),
    'jhansi': LatLng(25.4484, 78.5685),
    'mathura': LatLng(27.4924, 77.6737),
    'ayodhya': LatLng(26.7922, 82.1998),
    'chandigarh': LatLng(30.7333, 76.7794),
    'ludhiana': LatLng(30.9010, 75.8573),
    'amritsar': LatLng(31.6340, 74.8723),
    'jalandhar': LatLng(31.3260, 75.5762),
    'patiala': LatLng(30.3398, 76.3869),
    'bathinda': LatLng(30.2110, 74.9455),
    'panipat': LatLng(29.3909, 76.9635),
    'ambala': LatLng(30.3782, 76.7767),
    'rohtak': LatLng(28.8955, 76.6066),
    'hisar': LatLng(29.1492, 75.7217),
    'karnal': LatLng(29.6857, 76.9905),
    'dehradun': LatLng(30.3165, 78.0322),
    'haridwar': LatLng(29.9457, 78.1642),
    'rishikesh': LatLng(30.0869, 78.2676),
    'nainital': LatLng(29.3919, 79.4542),
    'shimla': LatLng(31.1048, 77.1734),
    'dharamshala': LatLng(32.2190, 76.3234),
    'srinagar': LatLng(34.0837, 74.7973),
    'jammu': LatLng(32.7266, 74.8570),
    'leh': LatLng(34.1526, 77.5771),

    // Central, Eastern & North-Eastern India
    'bhopal': LatLng(23.2599, 77.4126),
    'indore': LatLng(22.7196, 75.8577),
    'gwalior': LatLng(26.2183, 78.1828),
    'jabalpur': LatLng(23.1815, 79.9864),
    'ujjain': LatLng(23.1765, 75.7885),
    'raipur': LatLng(21.2514, 81.6296),
    'bhilai': LatLng(21.1938, 81.3509),
    'bilaspur': LatLng(22.0797, 82.1409),
    'patna': LatLng(25.5941, 85.1376),
    'gaya': LatLng(24.7914, 85.0002),
    'bhagalpur': LatLng(25.2425, 86.9842),
    'muzaffarpur': LatLng(26.1209, 85.3647),
    'kolkata': LatLng(22.5726, 88.3639),
    'howrah': LatLng(22.5958, 88.2636),
    'siliguri': LatLng(26.7271, 88.3953),
    'durgapur': LatLng(23.5204, 87.3119),
    'asansol': LatLng(23.6739, 86.9524),
    'bhubaneswar': LatLng(20.2961, 85.8245),
    'cuttack': LatLng(20.4625, 85.8828),
    'rourkela': LatLng(22.2604, 84.8536),
    'puri': LatLng(19.8135, 85.8312),
    'ranchi': LatLng(23.3441, 85.3096),
    'jamshedpur': LatLng(22.8046, 86.2029),
    'dhanbad': LatLng(23.7957, 86.4304),
    'bokaro': LatLng(23.6693, 86.1511),
    'guwahati': LatLng(26.1445, 91.7362),
    'silchar': LatLng(24.8333, 92.7789),
    'dibrugarh': LatLng(27.4728, 94.9120),
    'jorhat': LatLng(26.7509, 94.2037),
    'shillong': LatLng(25.5788, 91.8933),
    'imphal': LatLng(24.8170, 93.9368),
    'aizawl': LatLng(23.7271, 92.7176),
    'kohima': LatLng(25.6751, 94.1086),
    'agartala': LatLng(23.8315, 91.2868),
    'gangtok': LatLng(27.3389, 88.6065),
    'itanagar': LatLng(27.0844, 93.6053),
    'port blair': LatLng(11.6234, 92.7265),
    'puducherry': LatLng(11.9416, 79.8083),
    'pondicherry': LatLng(11.9416, 79.8083),
    'daman': LatLng(20.3974, 72.8328),
    'diu': LatLng(20.7144, 70.9874),
    'silvassa': LatLng(20.2763, 73.0083),
    'kavaratti': LatLng(10.5669, 72.6420),

    // State Centers
    'tamil nadu': LatLng(11.1271, 78.6569),
    'kerala': LatLng(10.8505, 76.2711),
    'karnataka': LatLng(15.3173, 75.7139),
    'andhra pradesh': LatLng(15.9129, 79.7400),
    'telangana': LatLng(18.1124, 79.0193),
    'maharashtra': LatLng(19.7515, 75.7139),
    'gujarat': LatLng(22.2587, 71.1924),
    'rajasthan': LatLng(27.0238, 74.2179),
    'uttar pradesh': LatLng(26.8467, 80.9462),
    'madhya pradesh': LatLng(22.9734, 78.6569),
    'west bengal': LatLng(22.9868, 87.8550),
    'bihar': LatLng(25.0961, 85.3131),
    'punjab': LatLng(31.1471, 75.3412),
    'haryana': LatLng(29.0588, 76.0856),
    'odisha': LatLng(20.9517, 85.0985),
    'assam': LatLng(26.2006, 92.9376),
    'jharkhand': LatLng(23.6102, 85.2799),
    'chhattisgarh': LatLng(21.2787, 81.8661),
    'uttarakhand': LatLng(30.0668, 79.0193),
    'himachal pradesh': LatLng(31.7433, 77.1202),
    'jammu and kashmir': LatLng(33.7782, 76.5762),
    'ladakh': LatLng(34.1526, 77.5771),
    'tripura': LatLng(23.9408, 91.9882),
    'manipur': LatLng(24.6637, 93.9063),
    'meghalaya': LatLng(25.4670, 91.3662),
    'mizoram': LatLng(23.1645, 92.9376),
    'nagaland': LatLng(26.1584, 94.5624),
    'arunachal pradesh': LatLng(28.2180, 94.7278),
    'sikkim': LatLng(27.5330, 88.5122),
    'all india': LatLng(20.5937, 78.9629),
    'india': LatLng(20.5937, 78.9629),
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
        headers: {'User-Agent': 'AutoPartsIndia/1.0 (autopartsindia7@gmail.com)'},
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

  /// Searches for any village, town, panchayat, or area in India with accurate coordinates
  static Future<List<Map<String, dynamic>>> searchPlacesOnline(String query) async {
    final clean = query.trim();
    if (clean.length < 2) return [];

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(clean)}&countrycodes=in&format=json&addressdetails=1&limit=6',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'AutoPartsIndia/1.0 (autopartsindia7@gmail.com)'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((item) {
          final addr = item['address'] ?? {};
          final name = addr['village'] ?? addr['town'] ?? addr['suburb'] ?? addr['hamlet'] ?? addr['neighbourhood'] ?? item['display_name'].toString().split(',').first;
          final district = addr['state_district'] ?? addr['county'] ?? addr['city'] ?? '';
          final state = addr['state'] ?? '';
          final lat = double.tryParse(item['lat'].toString()) ?? 0.0;
          final lon = double.tryParse(item['lon'].toString()) ?? 0.0;

          return {
            'title': name.toString(),
            'displayName': item['display_name'].toString(),
            'district': district.toString().isNotEmpty ? district.toString() : name.toString(),
            'state': state.toString(),
            'lat': lat,
            'lng': lon,
          };
        }).toList();
      }
    } catch (_) {}
    return [];
  }
}
