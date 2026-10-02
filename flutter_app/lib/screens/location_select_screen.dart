import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_colors.dart';
import '../constants/indian_locations_data.dart';
import 'map_location_picker_screen.dart';

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
  String? _selectedStateForDistricts; // For viewing state districts subview

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

  Future<void> _autoDetectGPSLocation() async {
    setState(() => _isDetectingGPS = true);
    try {
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

      await _selectLocation('Chennai', state: 'Tamil Nadu', district: 'Chennai');
    } catch (e) {
      if (mounted) {
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

    // Filter search matches
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF0F172A), size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Location',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A)),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search city, area or neighbourhood',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.w400),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => setState(() => _searchController.clear()),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0075FF), width: 1.5),
                ),
              ),
            ),
          ),

          // Use Current Location Button Row
          InkWell(
            onTap: _isDetectingGPS ? null : _autoDetectGPSLocation,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.my_location_rounded, color: Color(0xFF0075FF), size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isDetectingGPS ? 'Detecting your location...' : 'Use current location',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF0075FF),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Detects device GPS position automatically',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Pick on Interactive Map Button Row
          InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MapLocationPickerScreen(),
                ),
              );
              if (result != null && result is LocationResult) {
                await _selectLocation(result.district, state: result.state, district: result.district);
              }
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Row(
                children: [
                  const Icon(Icons.map_rounded, color: Color(0xFF10B981), size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Pick on Google Map',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Select your exact town, area or garage on map',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),

          Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

          // Main Body: Search Results or States List
          Expanded(
            child: query.isNotEmpty
                ? searchMatches.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_off_rounded, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('No locations found for "$query"', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                            const SizedBox(height: 4),
                            const Text('Try searching for another city or state.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: searchMatches.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                        itemBuilder: (context, index) {
                          final item = searchMatches[index];
                          return ListTile(
                            title: Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0F172A))),
                            subtitle: Text(item['subtitle']!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                            onTap: () {
                              _selectLocation(item['title']!, state: item['state'], district: item['district']);
                            },
                          );
                        },
                      )
                    : ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          // Choose State Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              'CHOOSE STATE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),

                          // All in India
                          ListTile(
                            title: const Text(
                              'All in India',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF0075FF)),
                            ),
                            onTap: () => _selectLocation('All India'),
                          ),
                          Divider(height: 1, color: Colors.grey.shade100),

                          // States List
                          ..._allStates.map((st) {
                            return Column(
                              children: [
                                ListTile(
                                  title: Text(
                                    st.state,
                                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Color(0xFF0F172A)),
                                  ),
                                  trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
                                  onTap: () {
                                    // Show districts dialog or select state
                                    _showDistrictsDialog(st);
                                  },
                                ),
                                Divider(height: 1, color: Colors.grey.shade100),
                              ],
                            );
                          }),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  void _showDistrictsDialog(StateWithDistricts st) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      st.state,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              title: Text('Entire ${st.state}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0075FF))),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () {
                Navigator.pop(ctx);
                _selectLocation(st.state, state: st.state);
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: st.districts.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                  final district = st.districts[index];
                  return ListTile(
                    title: Text(district, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _selectLocation(district, state: st.state, district: district);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
