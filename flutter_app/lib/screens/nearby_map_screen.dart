import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/spare_part.dart';
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
  Set<Marker> _markers = {};
  List<SparePart> _nearbyParts = [];
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

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      setState(() {
        _currentCenter = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentCenter, zoom: 13.5),
        ),
      );
    } catch (e) {
      debugPrint('Location error: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  void _loadParts() {
    _db.collection('spareParts').limit(50).snapshots().listen((snapshot) {
      final parts = snapshot.docs.map((doc) => SparePart.fromFirestore(doc)).toList();
      setState(() {
        _nearbyParts = parts;
        _buildMarkers(parts);
      });
    });
  }

  void _buildMarkers(List<SparePart> parts) {
    Set<Marker> markers = {};
    // Add current user marker
    markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: _currentCenter,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Your Location', snippet: 'Searching nearby auto parts'),
      ),
    );

    // Add part markers with slight coordinate spreads for visual demo
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      // Simulate proximity offsets if lat/lng not explicitly stored
      double latOffset = (i % 5 - 2) * 0.015;
      double lngOffset = ((i ~/ 5) % 5 - 2) * 0.015;
      LatLng pos = LatLng(_currentCenter.latitude + latOffset, _currentCenter.longitude + lngOffset);

      markers.add(
        Marker(
          markerId: MarkerId(part.id),
          position: pos,
          infoWindow: InfoWindow(
            title: part.title,
            snippet: _currencyFormatter.format(part.price),
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

    setState(() {
      _markers = markers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Spares Radar', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _currentCenter,
              zoom: 12.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
          ),

          if (_isLoadingLocation)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF0075FF)),
              ),
            ),

          // Bottom Horizontal List of Nearby Spares
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _nearbyParts.length,
                itemBuilder: (context, index) {
                  final part = _nearbyParts[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProductDetailScreen(part: part)),
                      );
                    },
                    child: Container(
                      width: 240,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
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
                              width: 90,
                              height: 120,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(width: 90, height: 120, color: Colors.grey.shade200),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _currencyFormatter.format(part.price),
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0075FF)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  part.title,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFF64748B)),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        part.location.isNotEmpty ? part.location : 'Nearby',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
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
      ),
    );
  }
}
