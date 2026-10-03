import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/app_colors.dart';
import '../constants/indian_locations_data.dart';
import '../constants/location_coordinates_helper.dart';
import 'map_location_picker_screen.dart';

class LocationSelectScreen extends StatefulWidget {
  final String selectedLocation;

  const LocationSelectScreen({Key? key, this.selectedLocation = 'All India'}) : super(key: key);

  @override
  State<LocationSelectScreen> createState() => _LocationSelectScreenState();
}

class _LocationSelectScreenState extends State<LocationSelectScreen> with SingleTickerProviderStateMixin {
  late String _currentLocation;
  final TextEditingController _searchController = TextEditingController();
  bool _isDetectingGPS = false;
  List<StateWithDistricts> _allStates = [];
  bool _isMapView = false;

  Timer? _searchDebounceTimer;
  List<Map<String, dynamic>> _onlineVillageMatches = [];
  bool _isSearchingOnline = false;

  // Embedded Map View state
  GoogleMapController? _embeddedMapController;
  LatLng _mapSelectedPosition = const LatLng(13.0827, 80.2707); // Default Chennai
  String _mapResolvedAddress = 'Chennai, Tamil Nadu';
  String _mapResolvedDistrict = 'Chennai';
  String _mapResolvedState = 'Tamil Nadu';
  bool _isMapGeocoding = false;
  bool _hasLocationPermission = false;

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
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _embeddedMapController?.dispose();
    super.dispose();
  }

  void _onSearchQueryChanged(String query) {
    _searchDebounceTimer?.cancel();
    setState(() {});

    final clean = query.trim();
    if (clean.length >= 2) {
      _searchDebounceTimer = Timer(const Duration(milliseconds: 350), () async {
        if (!mounted) return;
        setState(() => _isSearchingOnline = true);
        final results = await LocationCoordinatesHelper.searchPlacesOnline(clean);
        if (mounted) {
          setState(() {
            _onlineVillageMatches = results;
            _isSearchingOnline = false;
          });
        }
      });
    } else {
      if (_onlineVillageMatches.isNotEmpty) {
        setState(() {
          _onlineVillageMatches = [];
          _isSearchingOnline = false;
        });
      }
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      final perm = await Geolocator.checkPermission();
      if ((perm == LocationPermission.always || perm == LocationPermission.whileInUse) && mounted) {
        setState(() => _hasLocationPermission = true);
      }
    } catch (_) {}
  }

  Future<void> _loadSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('user_selected_city');
      if (saved != null && saved.isNotEmpty && mounted) {
        setState(() {
          _currentLocation = saved;
          final coords = LocationCoordinatesHelper.getCoordinatesForLocation(saved);
          _mapSelectedPosition = coords;
          _mapResolvedAddress = saved;
          _mapResolvedDistrict = saved;
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
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }

        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          setState(() => _hasLocationPermission = true);
          final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium)
              .timeout(const Duration(seconds: 4));

          final address = await LocationCoordinatesHelper.reverseGeocode(pos.latitude, pos.longitude);
          if (address != null && address.isNotEmpty) {
            final parts = address.split(', ');
            String dist = parts.length >= 2 ? parts[parts.length - 2] : parts.first;
            String st = parts.last;
            await _selectLocation(dist, state: st, district: dist);
            return;
          }
        }
      }

      // Fallback via IP API
      final response = await http.get(Uri.parse('https://ipapi.co/json/')).timeout(const Duration(seconds: 4));
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
    } catch (_) {
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

  Future<void> _reverseGeocodeMapPosition(LatLng pos) async {
    setState(() => _isMapGeocoding = true);
    try {
      final address = await LocationCoordinatesHelper.reverseGeocode(pos.latitude, pos.longitude);
      if (address != null && address.isNotEmpty && mounted) {
        final parts = address.split(', ');
        String dist = parts.length >= 2 ? parts[parts.length - 2] : parts.first;
        String st = parts.last;
        setState(() {
          _mapResolvedAddress = address;
          _mapResolvedDistrict = dist;
          _mapResolvedState = st;
        });
      } else if (mounted) {
        setState(() {
          _mapResolvedAddress = 'Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}';
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isMapGeocoding = false);
    }
  }

  void _openGoogleMapForStateOrDistrict(String name, {String? state}) async {
    final coords = LocationCoordinatesHelper.getCoordinatesForLocation(name, state ?? '');
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPickerScreen(
          initialPosition: coords,
          initialAddress: state != null && state.isNotEmpty ? '$name, $state' : name,
        ),
      ),
    );
    if (result != null && result is LocationResult) {
      await _selectLocation(result.district, state: result.state, district: result.district);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();

    // Filter search matches across states and districts
    List<Map<String, String>> searchMatches = [];
    if (query.isNotEmpty) {
      for (var st in _allStates) {
        if (st.state.toLowerCase().contains(query)) {
          searchMatches.add({'title': st.state, 'subtitle': 'State • ${st.districts.length} Districts', 'state': st.state, 'district': st.state});
        }
        for (var dist in st.districts) {
          if (dist.toLowerCase().contains(query)) {
            searchMatches.add({'title': dist, 'subtitle': '${st.state} District', 'state': st.state, 'district': dist});
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
          'Select Location',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        actions: [
          // View Mode Switcher: List vs Map
          IconButton(
            icon: Icon(
              _isMapView ? Icons.format_list_bulleted_rounded : Icons.map_rounded,
              color: const Color(0xFF0075FF),
            ),
            tooltip: _isMapView ? 'Switch to All States & Districts' : 'Switch to Interactive India Map',
            onPressed: () {
              setState(() => _isMapView = !_isMapView);
            },
          ),
        ],
      ),
      body: _isMapView ? _buildInteractiveMapView() : _buildListView(query, searchMatches),
    );
  }

  Widget _buildInteractiveMapView() {
    final quickStates = [
      'Tamil Nadu', 'Kerala', 'Karnataka', 'Andhra Pradesh', 'Telangana',
      'Maharashtra', 'Gujarat', 'Delhi', 'Uttar Pradesh', 'West Bengal', 'Rajasthan'
    ];

    return Stack(
      children: [
        // 1. Google Map centered on India or current position
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _mapSelectedPosition,
            zoom: 12.0,
          ),
          myLocationEnabled: _hasLocationPermission,
          myLocationButtonEnabled: _hasLocationPermission,
          zoomControlsEnabled: false,
          compassEnabled: true,
          onMapCreated: (ctrl) => _embeddedMapController = ctrl,
          onCameraMove: (pos) {
            setState(() => _mapSelectedPosition = pos.target);
          },
          onCameraIdle: () {
            _reverseGeocodeMapPosition(_mapSelectedPosition);
          },
          onTap: (latLng) {
            setState(() => _mapSelectedPosition = latLng);
            _embeddedMapController?.animateCamera(CameraUpdate.newLatLng(latLng));
            _reverseGeocodeMapPosition(latLng);
          },
        ),

        // 2. Center Location Pin
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0075FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Icon(Icons.location_on_rounded, size: 24, color: Colors.white),
              ),
              Container(
                width: 4,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF0075FF),
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),

        // 3. Top Quick State Chips for Pan-India navigation
        Positioned(
          top: 12,
          left: 0,
          right: 0,
          child: SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: quickStates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final stateName = quickStates[index];
                return ActionChip(
                  label: Text(stateName),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                  backgroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFE2E8F0))),
                  onPressed: () {
                    final coords = LocationCoordinatesHelper.getCoordinatesForLocation(stateName);
                    setState(() => _mapSelectedPosition = coords);
                    _embeddedMapController?.animateCamera(
                      CameraUpdate.newCameraPosition(CameraPosition(target: coords, zoom: 8.5)),
                    );
                    _reverseGeocodeMapPosition(coords);
                  },
                );
              },
            ),
          ),
        ),

        // 4. Bottom Selection Card with Confirm Button
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0075FF).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.pin_drop_rounded, color: Color(0xFF0075FF), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isMapGeocoding ? 'Detecting area...' : _mapResolvedDistrict,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _mapResolvedAddress,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0075FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                    label: Text(
                      'Set Location to $_mapResolvedDistrict',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                    onPressed: () {
                      _selectLocation(_mapResolvedDistrict, state: _mapResolvedState, district: _mapResolvedDistrict);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListView(String query, List<Map<String, String>> searchMatches) {
    // Separate states (28) and Union Territories (8)
    final statesOnly = _allStates.take(28).toList();
    final unionTerritories = _allStates.skip(28).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchQueryChanged,
            decoration: InputDecoration(
              hintText: 'Search 750+ districts, cities, or 36 states...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.w400),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => setState(() => _searchController.clear()),
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF0075FF), width: 1.5),
              ),
            ),
          ),
        ),

        // Quick Map & GPS Option Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              // 1. Pick on Google Map Card Button
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isMapView = true),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_rounded, color: Color(0xFF0075FF), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Google Map View',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0075FF)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 2. Current GPS Location
              Expanded(
                child: InkWell(
                  onTap: _isDetectingGPS ? null : _autoDetectGPSLocation,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isDetectingGPS ? Icons.sync_rounded : Icons.my_location_rounded,
                          color: const Color(0xFF10B981),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isDetectingGPS ? 'Detecting...' : 'Current GPS',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Divider(height: 1, thickness: 1, color: Colors.grey.shade200),

        // Main Body: Search Results OR Categorized States & UTs
        Expanded(
          child: query.isNotEmpty
              ? ((searchMatches.isEmpty && _onlineVillageMatches.isEmpty && !_isSearchingOnline)
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_off_rounded, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text('No results for "$query"', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                          const SizedBox(height: 4),
                          const Text('Try typing a nearby district, town, or pin on Google Map.', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        if (_isSearchingOnline)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0075FF)),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Searching Pan-India villages & towns database...',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),

                        // 1. Online Village / Town Results
                        if (_onlineVillageMatches.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                            color: const Color(0xFFF1F5F9),
                            child: Row(
                              children: [
                                const Icon(Icons.holiday_village_rounded, size: 15, color: Color(0xFF10B981)),
                                const SizedBox(width: 6),
                                Text(
                                  'VILLAGES & TOWNS (${_onlineVillageMatches.length})',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF334155), letterSpacing: 0.8),
                                ),
                              ],
                            ),
                          ),
                          ..._onlineVillageMatches.map((village) {
                            final title = village['title'].toString();
                            final district = village['district'].toString();
                            final state = village['state'].toString();
                            final lat = village['lat'] as double? ?? 0.0;
                            final lng = village['lng'] as double? ?? 0.0;
                            final displayName = village['displayName'].toString();

                            return Column(
                              children: [
                                ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), shape: BoxShape.circle),
                                    child: const Icon(Icons.location_city_rounded, color: Color(0xFF10B981), size: 18),
                                  ),
                                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A))),
                                  subtitle: Text(district.isNotEmpty ? '$district, $state' : state, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.map_rounded, size: 20, color: Color(0xFF10B981)),
                                        tooltip: 'Pin $title on Google Map',
                                        onPressed: () {
                                          if (lat != 0.0 && lng != 0.0) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => MapLocationPickerScreen(
                                                  initialPosition: LatLng(lat, lng),
                                                  initialAddress: displayName,
                                                ),
                                              ),
                                            ).then((res) {
                                              if (res != null && res is LocationResult) {
                                                _selectLocation(res.district, state: res.state, district: res.district);
                                              }
                                            });
                                          } else {
                                            _openGoogleMapForStateOrDistrict(title, state: state);
                                          }
                                        },
                                      ),
                                      const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                                    ],
                                  ),
                                  onTap: () {
                                    _selectLocation(title, state: state, district: district.isNotEmpty ? district : title);
                                  },
                                ),
                                Divider(height: 1, color: Colors.grey.shade100),
                              ],
                            );
                          }),
                        ],

                        // 2. States & Districts Matches
                        if (searchMatches.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                            color: const Color(0xFFF1F5F9),
                            child: Row(
                              children: [
                                const Icon(Icons.account_balance_rounded, size: 15, color: Color(0xFF0075FF)),
                                const SizedBox(width: 6),
                                Text(
                                  'STATES & DISTRICTS (${searchMatches.length})',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFF334155), letterSpacing: 0.8),
                                ),
                              ],
                            ),
                          ),
                          ...searchMatches.map((item) {
                            return Column(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.location_on_rounded, color: Color(0xFF0075FF), size: 22),
                                  title: Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A))),
                                  subtitle: Text(item['subtitle']!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.map_rounded, size: 20, color: Color(0xFF0075FF)),
                                        tooltip: 'Pin on Google Map',
                                        onPressed: () {
                                          _openGoogleMapForStateOrDistrict(item['title']!, state: item['state']);
                                        },
                                      ),
                                      const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
                                    ],
                                  ),
                                  onTap: () {
                                    _selectLocation(item['title']!, state: item['state'], district: item['district']);
                                  },
                                ),
                                Divider(height: 1, color: Colors.grey.shade100),
                              ],
                            );
                          }),
                        ],
                      ],
                    ))
              : ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // All India Selection Tile
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFF0075FF).withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.public_rounded, color: Color(0xFF0075FF), size: 20),
                      ),
                      title: const Text(
                        'All in India (Pan-India Marketplace)',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0075FF)),
                      ),
                      subtitle: const Text('View spare parts across all 36 Indian States & UTs', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF0075FF)),
                      onTap: () => _selectLocation('All India'),
                    ),
                    Divider(height: 1, color: Colors.grey.shade200),

                    // Section 1: 28 States of India
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      color: const Color(0xFFF8FAFC),
                      child: Row(
                        children: [
                          const Icon(Icons.flag_rounded, size: 16, color: Color(0xFF0075FF)),
                          const SizedBox(width: 8),
                          Text(
                            'INDIAN STATES (28)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.grey.shade700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...statesOnly.map((st) => _buildStateTile(st)),

                    // Section 2: 8 Union Territories
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      color: const Color(0xFFF8FAFC),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_rounded, size: 16, color: Color(0xFF10B981)),
                          const SizedBox(width: 8),
                          Text(
                            'UNION TERRITORIES (8)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.grey.shade700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...unionTerritories.map((st) => _buildStateTile(st)),
                    const SizedBox(height: 32),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildStateTile(StateWithDistricts st) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          title: Text(
            st.state,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
          ),
          subtitle: Text(
            '${st.districts.length} Districts Available',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.map_rounded, size: 20, color: Color(0xFF0075FF)),
                tooltip: 'View ${st.state} on Google Map',
                onPressed: () {
                  _openGoogleMapForStateOrDistrict(st.state, state: st.state);
                },
              ),
              const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
            ],
          ),
          onTap: () => _showDistrictsDialog(st),
        ),
        Divider(height: 1, color: Colors.grey.shade100),
      ],
    );
  }

  void _showDistrictsDialog(StateWithDistricts st) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Sheet Header with Google Map Action
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            st.state,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${st.districts.length} Districts with Google Maps Pin Support',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0075FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.map_rounded, size: 16),
                      label: const Text('Map View', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openGoogleMapForStateOrDistrict(st.state, state: st.state);
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Entire State Selection Tile
              ListTile(
                tileColor: const Color(0xFFF8FAFC),
                leading: const Icon(Icons.domain_rounded, color: Color(0xFF0075FF), size: 20),
                title: Text('Entire ${st.state}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF0075FF), fontSize: 14)),
                subtitle: Text('Search all ${st.districts.length} districts in ${st.state}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF0075FF)),
                onTap: () {
                  Navigator.pop(ctx);
                  _selectLocation(st.state, state: st.state);
                },
              ),
              const Divider(height: 1),

              // Districts List
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: st.districts.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final district = st.districts[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                      leading: const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF64748B)),
                      title: Text(district, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF0F172A))),
                      subtitle: Text('${st.state} District', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Pin on Map Button
                          IconButton(
                            icon: const Icon(Icons.map_rounded, size: 20, color: Color(0xFF10B981)),
                            tooltip: 'Pin $district on Google Map',
                            onPressed: () {
                              Navigator.pop(ctx);
                              _openGoogleMapForStateOrDistrict(district, state: st.state);
                            },
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFCBD5E1)),
                        ],
                      ),
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
      ),
    );
  }
}
