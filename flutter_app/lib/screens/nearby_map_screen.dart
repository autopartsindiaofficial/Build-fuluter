import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/spare_part.dart';
import '../constants/location_coordinates_helper.dart';
import 'product_detail_screen.dart';

class NearbyMapScreen extends StatefulWidget {
  const NearbyMapScreen({Key? key}) : super(key: key);

  @override
  State<NearbyMapScreen> createState() => _NearbyMapScreenState();
}

class _NearbyMapScreenState extends State<NearbyMapScreen> {
  GoogleMapController? _mapController;
  LatLng _currentCenter = const LatLng(13.0827, 80.2707); // Default Chennai center
  bool _isLoadingLocation = true;
  bool _hasLocationPermission = false;
  bool _isListView = false;
  Set<Marker> _markers = {};
  List<SparePart> _nearbyParts = [];
  StreamSubscription<QuerySnapshot>? _partsSubscription;
  final NumberFormat _currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

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
    _determinePosition();
    _loadParts();
  }

  @override
  void dispose() {
    _partsSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _hasLocationPermission = false;
              _isLoadingLocation = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _hasLocationPermission = false;
            _isLoadingLocation = false;
          });
        }
        return;
      }

      // Permission is granted (whileInUse or always)
      if (mounted) {
        setState(() => _hasLocationPermission = true);
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 4));

      if (mounted) {
        setState(() {
          _currentCenter = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
        _buildMarkers(_nearbyParts);
      }

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentCenter, zoom: 13.0),
        ),
      );
    } catch (e) {
      debugPrint('[NearbyMap] Location determination fallback: $e');
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  void _loadParts() {
    _partsSubscription = _db
        .collection('spareParts')
        .where('isDeleted', isEqualTo: false)
        .limit(60)
        .snapshots()
        .listen(
      (snapshot) {
        final parts = snapshot.docs.map((doc) => SparePart.fromFirestore(doc)).toList();

        // Sort parts by proximity to _currentCenter
        parts.sort((a, b) {
          final aCoords = (a.latitude != null && a.longitude != null)
              ? LatLng(a.latitude!, a.longitude!)
              : LocationCoordinatesHelper.getCoordinatesForLocation(a.location, a.district);
          final bCoords = (b.latitude != null && b.longitude != null)
              ? LatLng(b.latitude!, b.longitude!)
              : LocationCoordinatesHelper.getCoordinatesForLocation(b.location, b.district);

          final aDist = LocationCoordinatesHelper.calculateDistanceInKm(
            _currentCenter.latitude,
            _currentCenter.longitude,
            aCoords.latitude,
            aCoords.longitude,
          );
          final bDist = LocationCoordinatesHelper.calculateDistanceInKm(
            _currentCenter.latitude,
            _currentCenter.longitude,
            bCoords.latitude,
            bCoords.longitude,
          );
          return aDist.compareTo(bDist);
        });

        if (mounted) {
          setState(() {
            _nearbyParts = parts;
            _buildMarkers(parts);
          });
        }
      },
      onError: (err) {
        debugPrint('[NearbyMap] Firestore error: $err');
      },
    );
  }

  void _buildMarkers(List<SparePart> parts) {
    Set<Marker> markers = {};

    // 1. Current user position marker
    markers.add(
      Marker(
        markerId: const MarkerId('current_location_marker'),
        position: _currentCenter,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(
          title: '📍 Your Location',
          snippet: 'Searching auto parts near you',
        ),
      ),
    );

    // 2. Part markers with resolved coordinates
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      final LatLng pos = (part.latitude != null && part.longitude != null)
          ? LatLng(part.latitude!, part.longitude!)
          : LocationCoordinatesHelper.getCoordinatesForLocation(part.location, part.district);

      final double distance = LocationCoordinatesHelper.calculateDistanceInKm(
        _currentCenter.latitude,
        _currentCenter.longitude,
        pos.latitude,
        pos.longitude,
      );

      markers.add(
        Marker(
          markerId: MarkerId('part_${part.id}_$i'),
          position: pos,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: part.title,
            snippet: '${_currencyFormatter.format(part.price)} • ${distance.toStringAsFixed(1)} km away',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductDetailScreen(part: part)),
              );
            },
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  Future<void> _openDirections(SparePart part) async {
    final LatLng pos = (part.latitude != null && part.longitude != null)
        ? LatLng(part.latitude!, part.longitude!)
        : LocationCoordinatesHelper.getCoordinatesForLocation(part.location, part.district);

    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${pos.latitude},${pos.longitude}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Nearby Spares Radar',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          // Toggle between Map & List View
          IconButton(
            icon: Icon(
              _isListView ? Icons.map_rounded : Icons.view_list_rounded,
              color: const Color(0xFF0075FF),
            ),
            tooltip: _isListView ? 'Switch to Map View' : 'Switch to List View',
            onPressed: () {
              setState(() => _isListView = !_isListView);
            },
          ),
          IconButton(
            icon: const Icon(Icons.my_location_rounded, color: Color(0xFF0075FF)),
            tooltip: 'Re-center GPS',
            onPressed: _determinePosition,
          ),
        ],
      ),
      body: _isListView ? _buildListView() : _buildMapView(),
    );
  }

  Widget _buildMapView() {
    return Stack(
      children: [
        // 1. Google Map
        GoogleMap(
          onMapCreated: (controller) => _mapController = controller,
          initialCameraPosition: CameraPosition(
            target: _currentCenter,
            zoom: 12.5,
          ),
          markers: _markers,
          myLocationEnabled: _hasLocationPermission,
          myLocationButtonEnabled: _hasLocationPermission,
          zoomControlsEnabled: false,
          compassEnabled: true,
        ),

        // 2. Loading overlay
        if (_isLoadingLocation)
          Container(
            color: Colors.black.withOpacity(0.2),
            child: const Center(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0075FF)),
                      ),
                      SizedBox(width: 14),
                      Text('Finding spares near your GPS...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // 3. Top Mode / Parts Count Banner
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0075FF).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.radar_rounded, size: 18, color: Color(0xFF0075FF)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_nearbyParts.length} Spares Available Nearby',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        _hasLocationPermission ? 'Sorted by real-time GPS distance' : 'Showing Tamil Nadu & Indian hub spares',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.list_alt_rounded, size: 16, color: Color(0xFF0075FF)),
                  label: const Text('List', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0075FF))),
                  onPressed: () => setState(() => _isListView = true),
                ),
              ],
            ),
          ),
        ),

        // 4. Bottom Horizontal Carousel of Nearby Spares
        if (_nearbyParts.isNotEmpty)
          Positioned(
            bottom: 24,
            left: 14,
            right: 14,
            child: SizedBox(
              height: 145,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _nearbyParts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final part = _nearbyParts[index];
                  final LatLng pos = (part.latitude != null && part.longitude != null)
                      ? LatLng(part.latitude!, part.longitude!)
                      : LocationCoordinatesHelper.getCoordinatesForLocation(part.location, part.district);

                  final double dist = LocationCoordinatesHelper.calculateDistanceInKm(
                    _currentCenter.latitude,
                    _currentCenter.longitude,
                    pos.latitude,
                    pos.longitude,
                  );

                  return GestureDetector(
                    onTap: () {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(pos, 14.5),
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProductDetailScreen(part: part)),
                      );
                    },
                    child: Container(
                      width: 260,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: part.imageUrl,
                              width: 85,
                              height: 125,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                width: 85,
                                height: 125,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.directions_car_rounded, color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currencyFormatter.format(part.price),
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0075FF)),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  part.title,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.near_me_rounded, size: 11, color: Color(0xFF10B981)),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${dist.toStringAsFixed(1)} km away',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildListView() {
    if (_nearbyParts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            const Text(
              'No spare parts found nearby',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try changing your location or view all marketplace listings',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _nearbyParts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final part = _nearbyParts[index];
        final LatLng pos = (part.latitude != null && part.longitude != null)
            ? LatLng(part.latitude!, part.longitude!)
            : LocationCoordinatesHelper.getCoordinatesForLocation(part.location, part.district);

        final double distance = LocationCoordinatesHelper.calculateDistanceInKm(
          _currentCenter.latitude,
          _currentCenter.longitude,
          pos.latitude,
          pos.longitude,
        );

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductDetailScreen(part: part)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: part.imageUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 90,
                        height: 90,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.directions_car_rounded, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _currencyFormatter.format(part.price),
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0075FF)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.near_me_rounded, size: 12, color: Color(0xFF10B981)),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${distance.toStringAsFixed(1)} km',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          part.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFF64748B)),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                part.location,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0075FF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.directions_rounded, size: 14),
                              label: const Text('Directions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () => _openDirections(part),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('View Part', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => ProductDetailScreen(part: part)),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
