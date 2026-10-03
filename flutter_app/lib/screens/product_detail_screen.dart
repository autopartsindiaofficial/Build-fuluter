import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/spare_part.dart';
import '../constants/app_colors.dart';
import '../constants/location_coordinates_helper.dart';
import '../providers/language_provider.dart';
import '../providers/parts_provider.dart';
import '../widgets/make_offer_dialog.dart';
import 'chat_room_screen.dart';
import 'seller_profile_screen.dart';
import 'edit_listing_screen.dart';
import 'full_screen_gallery_screen.dart';
import '../services/cloudinary_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final SparePart part;

  const ProductDetailScreen({Key? key, required this.part}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _imagePageController = PageController();
  int _activeImageIndex = 0;
  bool _hasIncrementedView = false;
  final NumberFormat _currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  GoogleMapController? _mapController;
  late LatLng _partLocation;
  double? _distanceInKm;
  late bool _isSoldLocal;

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
    _isSoldLocal = widget.part.isSold;
    _initPartLocation();
    _incrementViewCount();
  }

  Future<void> _handleToggleSold() async {
    final nextSold = !_isSoldLocal;
    try {
      setState(() => _isSoldLocal = nextSold);
      await _db.collection('spareParts').doc(widget.part.id).update({
        'status': nextSold ? 'sold' : 'approved',
        'isSold': nextSold,
        'sold': nextSold,
        'approved': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(nextSold ? '🎉 Ad marked as Sold & hidden from marketplace feed!' : '✨ Ad marked as Active & live in marketplace!'),
            backgroundColor: nextSold ? const Color(0xFFD97706) : const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSoldLocal = !nextSold);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  void _initPartLocation() {
    if (widget.part.latitude != null && widget.part.longitude != null) {
      _partLocation = LatLng(widget.part.latitude!, widget.part.longitude!);
    } else {
      _partLocation = LocationCoordinatesHelper.getCoordinatesForLocation(
        widget.part.location,
        widget.part.district,
      );
    }
    _calculateUserDistance();
  }

  Future<void> _calculateUserDistance() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
        final dist = LocationCoordinatesHelper.calculateDistanceInKm(
          pos.latitude,
          pos.longitude,
          _partLocation.latitude,
          _partLocation.longitude,
        );
        if (mounted) {
          setState(() {
            _distanceInKm = dist;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _openDirectionsInGoogleMaps() async {
    final lat = _partLocation.latitude;
    final lng = _partLocation.longitude;
    final Uri url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch maps: $e')),
        );
      }
    }
  }

  void _openFullScreenMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.part.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${widget.part.location}${widget.part.district.isNotEmpty ? ', ' + widget.part.district : ''}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.directions_rounded, color: Color(0xFF0075FF)),
                tooltip: 'Get Directions',
                onPressed: _openDirectionsInGoogleMaps,
              ),
            ],
          ),
          body: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: _partLocation, zoom: 15),
                myLocationEnabled: true,
                zoomControlsEnabled: true,
                markers: {
                  Marker(
                    markerId: const MarkerId('part_fullscreen'),
                    position: _partLocation,
                    infoWindow: InfoWindow(
                      title: widget.part.title,
                      snippet: '${_currencyFormatter.format(widget.part.price)} • ${widget.part.location}',
                    ),
                  ),
                },
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0075FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    icon: const Icon(Icons.navigation_rounded),
                    label: const Text('Start Navigation in Google Maps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    onPressed: _openDirectionsInGoogleMaps,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  void _incrementViewCount() {
    if (_hasIncrementedView || widget.part.id.isEmpty) return;
    _hasIncrementedView = true;
    try {
      _db.collection('spareParts').doc(widget.part.id).update({
        'views': FieldValue.increment(1),
      }).catchError((_) {});
    } catch (_) {}
  }

  void _callPhone(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri uri = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open phone dialer. Please check call permissions.'),
              backgroundColor: Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteAd() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.delete_forever_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Delete Listing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently remove this spare part listing? This action cannot be undone.',
          style: TextStyle(color: Color(0xFF475569), fontSize: 14, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Listing', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final imagesToDelete = <String>[...widget.part.images];
        if (widget.part.imageUrl.isNotEmpty && !imagesToDelete.contains(widget.part.imageUrl)) {
          imagesToDelete.add(widget.part.imageUrl);
        }
        if (imagesToDelete.isNotEmpty) {
          CloudinaryService.deleteImages(imagesToDelete);
        }

        await _db.collection('spareParts').doc(widget.part.id).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Listing deleted successfully.'),
              backgroundColor: Color(0xFF0F172A),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to delete listing. Please try again.')),
          );
        }
      }
    }
  }

  void _openFullScreenImage(int initialIndex, List<String> images) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) => FullScreenGalleryScreen(
          images: images,
          initialIndex: initialIndex,
          title: widget.part.title,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final partsProvider = Provider.of<PartsProvider>(context);
    final isFav = partsProvider.isFavorite(widget.part.id);
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid;

    final isOwner = currentUserId != null &&
        (currentUserId == widget.part.sellerId || currentUserId == widget.part.userId);

    // Prepare image list
    final List<String> images = [];
    if (widget.part.imageUrl.isNotEmpty) images.add(widget.part.imageUrl);
    if (widget.part.images.isNotEmpty) {
      for (var img in widget.part.images) {
        if (!images.contains(img)) images.add(img);
      }
    }
    if (images.isEmpty) {
      images.add('https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&w=800&q=80');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.part.title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF0F172A)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
            ),
            onPressed: () {
              partsProvider.toggleWishlist(widget.part.id);
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(isFav ? Icons.favorite_border_rounded : Icons.favorite_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      Text(isFav ? 'Removed from Saved Parts' : 'Saved to Wishlist! ⭐', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  backgroundColor: isFav ? const Color(0xFF475569) : const Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF0F172A)),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: '${widget.part.title} - ₹${widget.part.price.toInt()} on Auto Parts India'));
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.copy_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text('Listing link copied to clipboard! 📋', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  backgroundColor: Color(0xFF0F172A),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. High-Impact Image Carousel with Specular Badges
            Stack(
              children: [
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: PageView.builder(
                    controller: _imagePageController,
                    onPageChanged: (idx) => setState(() => _activeImageIndex = idx),
                    itemCount: images.length,
                    itemBuilder: (context, idx) {
                      final url = images[idx];
                      return GestureDetector(
                        onTap: () => _openFullScreenImage(idx, images),
                        child: Container(
                          color: const Color(0xFF0F172A),
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: const Color(0xFF1E293B),
                              child: const Center(
                                child: CircularProgressIndicator(color: Color(0xFF0075FF)),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: const Color(0xFF1E293B),
                              child: const Icon(Icons.directions_car_rounded, size: 64, color: Colors.white54),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Tap to Zoom Hint
                Positioned(
                  bottom: 14,
                  right: 14,
                  child: GestureDetector(
                    onTap: () => _openFullScreenImage(_activeImageIndex, images),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Tap to zoom', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),

                // Image Index Indicator (e.g. 1 / 4)
                if (images.length > 1)
                  Positioned(
                    bottom: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Text(
                        '${_activeImageIndex + 1} / ${images.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                // Verified Badge on Top Left
                if (widget.part.verified)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0075FF), Color(0xFF0052B4)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.verified_rounded, color: Colors.white, size: 13),
                          SizedBox(width: 5),
                          Text('VERIFIED OEM PART', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // 2. Price, Title & Condition Card
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _currencyFormatter.format(widget.part.price),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (widget.part.isNegotiable) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: const Text(
                                'Negotiable',
                                style: TextStyle(color: Color(0xFF1D4ED8), fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Condition Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.part.condition.toLowerCase().contains('new')
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.part.condition.toLowerCase().contains('new')
                                ? const Color(0xFF0075FF).withOpacity(0.3)
                                : const Color(0xFFEF4444).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          widget.part.condition.toLowerCase().contains('new') ? '✨ BRAND NEW' : 'GENTLY USED',
                          style: TextStyle(
                            color: widget.part.condition.toLowerCase().contains('new')
                                ? const Color(0xFF0075FF)
                                : const Color(0xFFEF4444),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.part.title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0075FF).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF0075FF)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${widget.part.location}${widget.part.district.isNotEmpty ? ', ' + widget.part.district : ''}',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.remove_red_eye_rounded, size: 12, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.part.views} views',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 3. Technical Specifications Card
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0075FF),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Automotive Specifications',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildSpecTile('Car Brand', widget.part.carBrand, Icons.directions_car_rounded),
                  _buildSpecTile('Car Model', widget.part.carModel, Icons.car_repair_rounded),
                  if (widget.part.year.isNotEmpty) _buildSpecTile('Model Year', widget.part.year, Icons.calendar_today_rounded),
                  _buildSpecTile('Part Category', widget.part.category, Icons.category_rounded),
                  if (widget.part.subcategory.isNotEmpty) _buildSpecTile('Subcategory', widget.part.subcategory, Icons.subdirectory_arrow_right_rounded),
                  if (widget.part.oemNumber != null && widget.part.oemNumber!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.tag_rounded, size: 18, color: Color(0xFF64748B)),
                          const SizedBox(width: 10),
                          const Text('OEM Number', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Text(widget.part.oemNumber!, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0075FF))),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: widget.part.oemNumber!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('OEM Number copied!'), duration: Duration(seconds: 1)),
                              );
                            },
                            child: const Icon(Icons.copy_rounded, size: 15, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 4. Description Card
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0075FF),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Description',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.part.description ?? 'Genuine OEM automobile spare part in good working condition. Tested and verified.',
                    style: const TextStyle(color: Color(0xFF475569), fontSize: 14, height: 1.55),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 5. Verified Seller Card
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0075FF),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Seller Information',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SellerProfileScreen(
                            sellerId: widget.part.sellerId,
                            sellerName: widget.part.contactName ?? 'Verified Seller',
                            sellerPhone: widget.part.contactPhone,
                            location: widget.part.location,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0075FF), Color(0xFF0052B4)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Icon(Icons.person_rounded, color: Colors.white, size: 28),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.part.contactName ?? 'Verified Seller',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified_rounded, color: Color(0xFF0075FF), size: 16),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: const [
                                    Icon(Icons.star_rounded, size: 15, color: Color(0xFFF59E0B)),
                                    SizedBox(width: 3),
                                    Text('4.9 (48 ratings) • View Profile →', style: TextStyle(fontSize: 12, color: Color(0xFF0075FF), fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (widget.part.contactPhone != null && widget.part.contactPhone!.isNotEmpty)
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.call_rounded, color: Color(0xFF10B981), size: 22),
                                onPressed: () => _callPhone(widget.part.contactPhone!),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 5.5 Seller Location & Map View Card
            _buildLocationMapCard(),
            const SizedBox(height: 8),

            // 6. Similar Parts (Matching Brand)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0075FF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'More Spares for ${widget.part.carBrand}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('spareParts')
                  .where('carBrand', isEqualTo: widget.part.carBrand)
                  .limit(6)
                  .snapshots(),
              builder: (context, simSnap) {
                final docs = (simSnap.data?.docs ?? []).where((d) => d.id != widget.part.id).toList();
                if (docs.isEmpty) {
                  return const SizedBox.shrink();
                }

                return SizedBox(
                  height: 195,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: docs.length,
                    itemBuilder: (context, idx) {
                      final item = SparePart.fromFirestore(docs[idx]);
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => ProductDetailScreen(part: item)),
                          );
                        },
                        child: Container(
                          width: 145,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withOpacity(0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                child: CachedNetworkImage(
                                  imageUrl: item.imageUrl,
                                  height: 95,
                                  width: 145,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(height: 95, color: Colors.grey.shade200),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _currencyFormatter.format(item.price),
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0075FF)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.title,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
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
                );
              },
            ),
          ],
        ),
      ),

      // Bottom Action Bar (Direct Call, Make Offer, Chat with Seller OR Owner Edit/Delete)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          border: const Border(
            top: BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
          ),
        ),
        child: SafeArea(
          top: false,
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: isOwner
                // Owner Controls: Delete, Mark Sold/Active, and Edit
                ? Row(
                    children: [
                      // 1. Delete Ad Button
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFFEE2E2),
                          foregroundColor: const Color(0xFFEF4444),
                          padding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, size: 22),
                        tooltip: 'Delete Ad',
                        onPressed: _handleDeleteAd,
                      ),
                      const SizedBox(width: 8),

                      // 2. Mark Sold / Mark Active Toggle Button
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _isSoldLocal ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              width: 1.5,
                            ),
                            foregroundColor: _isSoldLocal ? const Color(0xFF10B981) : const Color(0xFFD97706),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: Icon(_isSoldLocal ? Icons.check_circle_outline_rounded : Icons.monetization_on_outlined, size: 18),
                          label: Text(
                            _isSoldLocal ? 'Mark Active' : 'Mark Sold',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          onPressed: _handleToggleSold,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 3. Edit Listing Button
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0075FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: const Text('Edit Listing', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => EditListingScreen(part: widget.part)),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                // Buyer Controls (Direct Call, Make Offer, Chat OR Sold Banner)
                : _isSoldLocal
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCD34D)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'This spare part has been sold out 🎉',
                              style: TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : Row(
                    children: [
                      // Direct Call Phone Dialer
                      if (widget.part.contactPhone != null && widget.part.contactPhone!.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                              foregroundColor: const Color(0xFF10B981),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => _callPhone(widget.part.contactPhone!),
                            child: const Icon(Icons.call_rounded, size: 20),
                          ),
                        ),

                      // Make Offer Button
                      Expanded(
                        flex: 1,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF0075FF), width: 1.5),
                            foregroundColor: const Color(0xFF0075FF),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.local_offer_outlined, size: 18),
                          label: const Text('Make Offer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                          onPressed: () {
                            final currentUid = currentUser?.uid ?? 'guest_buyer';
                            final currentName = currentUser?.displayName ?? 'Buyer';
                            showDialog(
                              context: context,
                              builder: (_) => MakeOfferDialog(
                                part: widget.part,
                                currentUserId: currentUid,
                                currentUserName: currentName,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Chat with Seller Button
                      Expanded(
                        flex: 1,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0075FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                          label: const Text('Chat', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          onPressed: () {
                            final currentUid = currentUser?.uid ?? 'guest_buyer';
                            final conversationId = '${currentUid}_${widget.part.sellerId}_${widget.part.id}';
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatRoomScreen(
                                  conversationId: conversationId,
                                  partTitle: widget.part.title,
                                  sellerName: widget.part.contactName ?? 'Seller',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }

  Widget _buildLocationMapCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF0075FF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Part Location & Map View',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Location details badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0075FF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on_rounded, size: 20, color: Color(0xFF0075FF)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.part.location}${widget.part.district.isNotEmpty ? ', ' + widget.part.district : ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (_distanceInKm != null) ...[
                            Text(
                              '📍 ${_distanceInKm!.toStringAsFixed(1)} km away from you',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                            ),
                          ] else ...[
                            Text(
                              'GPS: ${_partLocation.latitude.toStringAsFixed(4)}, ${_partLocation.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Embedded Google Map View
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 190,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _partLocation,
                      zoom: 14.0,
                    ),
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    markers: {
                      Marker(
                        markerId: const MarkerId('part_location'),
                        position: _partLocation,
                        infoWindow: InfoWindow(
                          title: widget.part.title,
                          snippet: widget.part.location,
                        ),
                      ),
                    },
                    onMapCreated: (ctrl) => _mapController = ctrl,
                    onTap: (_) => _openFullScreenMap(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons: Get Directions & Full Map
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0075FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: const Text(
                    'Get Directions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: _openDirectionsInGoogleMaps,
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.map_outlined, size: 18, color: Color(0xFF0075FF)),
                label: const Text(
                  'Full View',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: _openFullScreenMap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
