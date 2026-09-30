import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_colors.dart';
import '../constants/indian_locations_data.dart';

class LocationSelectScreen extends StatefulWidget {
  final String selectedLocation;

  const LocationSelectScreen({Key? key, this.selectedLocation = 'All India'}) : super(key: key);

  @override
  State<LocationSelectScreen> createState() => _LocationSelectScreenState();
}

class _LocationSelectScreenState extends State<LocationSelectScreen> {
  late String _currentLocation;
  final TextEditingController _searchController = TextEditingController();
  bool _isDetectingGPS = false;
  List<StateWithDistricts> _allStates = [];

  FirebaseFirestore get _db {
    try {
      return FirebaseFirestore.instanceFor(
        app: FirebaseFirestore.instance.app,
        databaseId: 'ai-studio-autopartsmarketp-6b6de595-2abc-431d-a6dc-0141a5eff96f',
      );
    } catch (_) {
      return FirebaseFirestore.instance;
    }
  }

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.selectedLocation;
    _allStates = List.from(kIndianStatesAndDistricts);
    _loadSavedLocation();
    _syncAdminTaxonomy();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('user_selected_city');
      if (saved != null && saved.isNotEmpty && mounted) {
        setState(() {
          _currentLocation = saved;
        });
      }
    } catch (_) {}
  }

  Future<void> _syncAdminTaxonomy() async {
    try {
      final doc = await _db.collection('taxonomy').doc('data').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['locations'] is List) {
          final List dynamicList = data['locations'];
          final Map<String, List<String>> customMap = {};
          for (var item in dynamicList) {
            if (item is Map && item['state'] != null) {
              final state = item['state'].toString();
              final districts = (item['districts'] as List?)?.map((e) => e.toString()).toList() ?? [];
              customMap[state] = districts;
            }
          }

          if (customMap.isNotEmpty && mounted) {
            setState(() {
              final updated = List<StateWithDistricts>.from(_allStates);
              customMap.forEach((st, dists) {
                final existingIdx = updated.indexWhere((e) => e.state.toLowerCase() == st.toLowerCase());
                if (existingIdx >= 0) {
                  final combinedDists = Set<String>.from(updated[existingIdx].districts)..addAll(dists);
                  updated[existingIdx] = StateWithDistricts(
                    state: updated[existingIdx].state,
                    districts: combinedDists.toList()..sort(),
                  );
                } else {
                  updated.add(StateWithDistricts(state: st, districts: dists..sort()));
                }
              });
              _allStates = updated;
            });
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _selectLocation(String location, {String? state, String? district}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_selected_city', location);
      if (state != null) await prefs.setString('user_selected_state', state);
      if (district != null) await prefs.setString('user_selected_district', district);
    } catch (_) {}

    if (mounted) {
      Navigator.pop(context, location);
    }
  }

  // Real GPS & Reverse Geocoding Auto-Detection
  Future<void> _autoDetectGPSLocation() async {
    setState(() => _isDetectingGPS = true);
    try {
      // 1. Fetch IP & network-assisted geolocation
      final response = await http.get(
        Uri.parse('https://ipapi.co/json/'),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final city = data['city'] ?? data['region'] ?? '';
        final region = data['region'] ?? '';

        if (city.isNotEmpty) {
          final matchedCity = _matchIndianDistrictOrCity(city.toString(), region.toString());
          await _selectLocation(matchedCity, state: region.toString(), district: matchedCity);
          return;
        }
      }

      // Fallback: Default to Chennai if location cannot be queried
      await _selectLocation('Chennai', state: 'Tamil Nadu', district: 'Chennai');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Auto-detect: Selected Chennai. You can also pick your city manually.'),
            backgroundColor: Color(0xFF0075FF),
          ),
        );
        await _selectLocation('Chennai', state: 'Tamil Nadu', district: 'Chennai');
      }
    } finally {
      if (mounted) setState(() => _isDetectingGPS = false);
    }
  }

  String _matchIndianDistrictOrCity(String city, String state) {
    final lowerCity = city.toLowerCase();
    for (var s in _allStates) {
      for (var d in s.districts) {
        if (d.toLowerCase() == lowerCity || d.toLowerCase().contains(lowerCity)) {
          return d;
        }
      }
    }
    return city.isNotEmpty ? city : 'Chennai';
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();

    // Filter results if searching
    List<Map<String, String>> searchMatches = [];
    if (query.isNotEmpty) {
      for (var st in _allStates) {
        if (st.state.toLowerCase().contains(query)) {
          searchMatches.add({'title': st.state, 'subtitle': 'State', 'state': st.state, 'district': st.state});
        }
        for (var dist in st.districts) {
          if (dist.toLowerCase().contains(query)) {
            searchMatches.add({'title': dist, 'subtitle': st.state, 'state': st.state, 'district': dist});
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Select Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Search Box
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search city, state or district...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF0075FF)),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () => setState(() => _searchController.clear()),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF0075FF), width: 1.5),
                ),
              ),
            ),
          ),

          // Main Body: Search Results or Default Sections
          Expanded(
            child: query.isNotEmpty
                ? searchMatches.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_off, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('No locations found for "$query"', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                            const SizedBox(height: 4),
                            const Text('Try searching for another city or state.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: searchMatches.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = searchMatches[index];
                          return ListTile(
                            tileColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            leading: const Icon(Icons.location_on, color: Color(0xFF0075FF)),
                            title: Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Text(item['subtitle']!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                            onTap: () {
                              _selectLocation(item['title']!, state: item['state'], district: item['district']);
                            },
                          );
                        },
                      )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // 1. Auto-Detect GPS Location Button
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        elevation: 1,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _isDetectingGPS ? null : _autoDetectGPSLocation,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0075FF).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: _isDetectingGPS
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0075FF)),
                                        )
                                      : const Icon(Icons.my_location, color: Color(0xFF0075FF), size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isDetectingGPS ? 'Detecting your location...' : 'Use Current Location',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF0075FF),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Using GPS & Network Auto-Detection',
                                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Color(0xFF0075FF)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. All India Option
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: _currentLocation == 'All India' ? const Color(0xFF0075FF) : Colors.grey.shade200,
                              width: _currentLocation == 'All India' ? 2 : 1,
                            ),
                          ),
                          leading: const Icon(Icons.public, color: Color(0xFF0075FF)),
                          title: const Text('All India (All Locations)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          trailing: _currentLocation == 'All India'
                              ? const Icon(Icons.check_circle, color: Color(0xFF16A34A))
                              : null,
                          onTap: () {
                            _selectLocation('All India');
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 3. Popular Cities
                      const Text(
                        'Popular Cities',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: kPopularIndianCities.map((city) {
                          final isSelected = _currentLocation.toLowerCase() == city.toLowerCase();
                          return ChoiceChip(
                            label: Text(city),
                            selected: isSelected,
                            selectedColor: const Color(0xFF0075FF),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                            ),
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF0075FF) : Colors.grey.shade300,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            onSelected: (_) {
                              _selectLocation(city);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // 4. Browse by State & Districts (All 28 States & 8 Union Territories)
                      const Text(
                        'All States & Districts of India',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 10),
                      ..._allStates.map((st) {
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ExpansionTile(
                            leading: const Icon(Icons.location_city, color: Color(0xFF0075FF), size: 22),
                            title: Text(
                              st.state,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                            ),
                            subtitle: Text(
                              '${st.districts.length} Districts',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                            children: st.districts.map((district) {
                              final isSelected = _currentLocation.toLowerCase() == district.toLowerCase();
                              return ListTile(
                                dense: true,
                                title: Text(
                                  district,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? const Color(0xFF0075FF) : const Color(0xFF334155),
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check, color: Color(0xFF0075FF), size: 18)
                                    : const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                                onTap: () {
                                  _selectLocation(district, state: st.state, district: district);
                                },
                              );
                            }).toList(),
                          ),
                        );
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
