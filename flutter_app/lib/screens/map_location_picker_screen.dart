import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/app_colors.dart';
import '../constants/location_coordinates_helper.dart';

class LocationResult {
  final String address;
  final String district;
  final String state;
  final double latitude;
  final double longitude;

  const LocationResult({
    required this.address,
    required this.district,
    required this.state,
    required this.latitude,
    required this.longitude,
  });
}

class MapLocationPickerScreen extends StatefulWidget {
  final LatLng? initialPosition;
  final String? initialAddress;

  const MapLocationPickerScreen({
    Key? key,
    this.initialPosition,
    this.initialAddress,
  }) : super(key: key);

  @override
  State<MapLocationPickerScreen> createState() => _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  GoogleMapController? _mapController;
  late LatLng _selectedPosition;
  String _resolvedAddress = 'Locating...';
  String _selectedDistrict = 'Chennai';
  String _selectedState = 'Tamil Nadu';
  bool _isGeocoding = false;
  bool _isLoadingGps = false;
  bool _hasLocationPermission = false;
  MapType _currentMapType = MapType.normal;

  final TextEditingController _searchCtrl = TextEditingController();

  final List<String> _quickHubs = [
    'Chennai',
    'Coimbatore',
    'Madurai',
    'Salem',
    'Tiruchirappalli',
    'Tiruppur',
    'Erode',
    'Vellore',
    'Tirunelveli',
    'Bengaluru',
    'Kochi',
    'Hyderabad',
    'Mumbai',
    'Pune',
    'Delhi NCR',
    'Ahmedabad',
    'Kolkata',
    'Jaipur',
    'Lucknow',
    'Chandigarh',
    'Patna',
    'Bhopal',
    'Guwahati',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialPosition ?? const LatLng(13.0827, 80.2707);
    _checkInitialPermission();
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _resolvedAddress = widget.initialAddress!;
    } else {
      _reverseGeocodePosition(_selectedPosition);
    }
  }

  Future<void> _checkInitialPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      if ((permission == LocationPermission.always || permission == LocationPermission.whileInUse) && mounted) {
        setState(() => _hasLocationPermission = true);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _reverseGeocodePosition(LatLng pos) async {
    setState(() => _isGeocoding = true);
    try {
      final address = await LocationCoordinatesHelper.reverseGeocode(pos.latitude, pos.longitude);
      if (address != null && address.isNotEmpty && mounted) {
        setState(() {
          _resolvedAddress = address;
          // Extract district/state if possible
          final parts = address.split(', ');
          if (parts.length >= 2) {
            _selectedDistrict = parts[parts.length - 2];
            _selectedState = parts.last;
          } else {
            _selectedDistrict = parts.first;
          }
        });
      } else if (mounted) {
        setState(() {
          _resolvedAddress = 'Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resolvedAddress = 'Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}';
        });
      }
    } finally {
      if (mounted) setState(() => _isGeocoding = false);
    }
  }

  Future<void> _getCurrentGpsLocation() async {
    setState(() => _isLoadingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable GPS / Location services')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission permanently denied. Enable in Settings.')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final newPos = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedPosition = newPos;
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: newPos, zoom: 16)),
      );

      await _reverseGeocodePosition(newPos);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get GPS: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingGps = false);
    }
  }

  void _onQuickHubSelected(String hub) {
    final coords = LocationCoordinatesHelper.getCoordinatesForLocation(hub);
    setState(() {
      _selectedPosition = coords;
      _resolvedAddress = hub;
      _selectedDistrict = hub;
    });
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: coords, zoom: 14)),
    );
    _reverseGeocodePosition(coords);
  }

  Future<void> _onSearchSubmitted(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;

    LatLng coords = LocationCoordinatesHelper.getCoordinatesForLocation(clean);
    bool isKnownPremapped = LocationCoordinatesHelper.cityCoordinates.containsKey(clean.toLowerCase());

    // If not in offline pre-mapped list, search online for any village, town, or taluk across India
    if (!isKnownPremapped) {
      final onlineMatches = await LocationCoordinatesHelper.searchPlacesOnline(clean);
      if (onlineMatches.isNotEmpty) {
        final first = onlineMatches.first;
        final lat = first['lat'] as double?;
        final lng = first['lng'] as double?;
        if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
          coords = LatLng(lat, lng);
        }
      }
    }

    setState(() {
      _selectedPosition = coords;
      _resolvedAddress = clean;
    });
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: coords, zoom: 15.0)),
    );
    _reverseGeocodePosition(coords);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pick Part Location on Map',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _currentMapType == MapType.normal ? Icons.satellite_alt_rounded : Icons.map_rounded,
              color: const Color(0xFF0F172A),
            ),
            tooltip: 'Toggle Satellite / Normal Map',
            onPressed: () {
              setState(() {
                _currentMapType = _currentMapType == MapType.normal ? MapType.hybrid : MapType.normal;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Full Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPosition,
              zoom: 14.0,
            ),
            mapType: _currentMapType,
            myLocationEnabled: _hasLocationPermission,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            onMapCreated: (ctrl) => _mapController = ctrl,
            onCameraMove: (pos) {
              setState(() => _selectedPosition = pos.target);
            },
            onCameraIdle: () {
              _reverseGeocodePosition(_selectedPosition);
            },
            onTap: (latLng) {
              setState(() => _selectedPosition = latLng);
              _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
              _reverseGeocodePosition(latLng);
            },
          ),

          // 2. Fixed Center Pin with target marker
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 38.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: const Text(
                      'Pin Part Location',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF0075FF),
                    size: 46,
                  ),
                ],
              ),
            ),
          ),

          // 3. Top Search & Quick City Filter Chips
          Positioned(
            top: 12,
            left: 14,
            right: 14,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _onSearchSubmitted,
                    decoration: InputDecoration(
                      hintText: 'Search city or area (e.g. Coimbatore, Madurai)...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF0075FF)),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _quickHubs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, idx) {
                      final hub = _quickHubs[idx];
                      return GestureDetector(
                        onTap: () => _onQuickHubSelected(hub),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 1)),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.near_me_rounded, size: 12, color: Color(0xFF0075FF)),
                              const SizedBox(width: 4),
                              Text(
                                hub,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 4. GPS "My Location" Floating Button
          Positioned(
            right: 16,
            bottom: 185,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              elevation: 4,
              heroTag: 'gps_btn',
              onPressed: _isLoadingGps ? null : _getCurrentGpsLocation,
              child: _isLoadingGps
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0075FF)),
                    )
                  : const Icon(Icons.my_location_rounded, color: Color(0xFF0075FF), size: 22),
            ),
          ),

          // 5. Bottom Location Detail & Confirmation Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, -4)),
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
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.location_on_rounded, color: Color(0xFF0075FF), size: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isGeocoding ? 'Detecting address...' : _resolvedAddress,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'GPS: ${_selectedPosition.latitude.toStringAsFixed(4)}, ${_selectedPosition.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      if (_isGeocoding)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0075FF)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0075FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: const Text(
                        'Confirm Location for Ad',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onPressed: () {
                        final result = LocationResult(
                          address: _resolvedAddress,
                          district: _selectedDistrict,
                          state: _selectedState,
                          latitude: _selectedPosition.latitude,
                          longitude: _selectedPosition.longitude,
                        );
                        Navigator.pop(context, result);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
