import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/spare_part.dart';
import '../constants/app_colors.dart';
import '../providers/language_provider.dart';
import '../providers/parts_provider.dart';
import '../widgets/make_offer_dialog.dart';
import 'chat_room_screen.dart';
import 'seller_profile_screen.dart';
import 'edit_listing_screen.dart';

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
    _incrementViewCount();
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
    final Uri uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open phone dialer.')),
        );
      }
    }
  }

  Future<void> _handleDeleteAd() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text('Are you sure you want to delete this listing? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _db.collection('spareParts').doc(widget.part.id).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Listing deleted successfully.')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete listing: $e')),
          );
        }
      }
    }
  }

  void _openFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 50),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
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

    // Check ownership
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
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.part.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.red : const Color(0xFF0F172A),
            ),
            onPressed: () {
              partsProvider.toggleWishlist(widget.part.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isFav ? 'Removed from saved parts' : 'Saved to Wishlist! ⭐'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF0F172A)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sharing "${widget.part.title}"')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Image Carousel with Indicator & Fullscreen Zoom
            Stack(
              children: [
                SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: PageView.builder(
                    controller: _imagePageController,
                    onPageChanged: (idx) => setState(() => _activeImageIndex = idx),
                    itemCount: images.length,
                    itemBuilder: (context, idx) {
                      final url = images[idx];
                      return GestureDetector(
                        onTap: () => _openFullScreenImage(url),
                        child: CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: Colors.grey.shade100, child: const Center(child: CircularProgressIndicator())),
                          errorWidget: (_, __, ___) => Container(color: Colors.grey.shade200, child: const Icon(Icons.directions_car, size: 60, color: Colors.grey)),
                        ),
                      );
                    },
                  ),
                ),
                // Indicator dots
                if (images.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                        (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _activeImageIndex == i ? 18 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _activeImageIndex == i ? const Color(0xFF0075FF) : Colors.white70,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Verified Badge on Top Left
                if (widget.part.verified)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.verified, color: Colors.blueAccent, size: 13),
                          SizedBox(width: 4),
                          Text('VERIFIED PART', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // 2. Price & Title Card
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _currencyFormatter.format(widget.part.price),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: widget.part.condition.toLowerCase().contains('new')
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.part.condition.toLowerCase().contains('new') ? '✨ BRAND NEW' : 'GENTLY USED',
                          style: TextStyle(
                            color: widget.part.condition.toLowerCase().contains('new')
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFD97706),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.part.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Color(0xFF0075FF)),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.part.location}${widget.part.district.isNotEmpty ? ', ' + widget.part.district : ''}',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Automotive Specifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  _buildSpecTile('Car Brand', widget.part.carBrand, Icons.directions_car),
                  _buildSpecTile('Car Model', widget.part.carModel, Icons.car_repair),
                  if (widget.part.year.isNotEmpty) _buildSpecTile('Model Year', widget.part.year, Icons.calendar_today),
                  _buildSpecTile('Part Category', widget.part.category, Icons.category),
                  if (widget.part.subcategory.isNotEmpty) _buildSpecTile('Subcategory', widget.part.subcategory, Icons.subdirectory_arrow_right),
                  if (widget.part.oemNumber != null && widget.part.oemNumber!.isNotEmpty)
                    _buildSpecTile('OEM Number', widget.part.oemNumber!, Icons.tag),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 4. Description Card
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  Text(
                    widget.part.description ?? 'Genuine OEM automobile spare part in good working condition. Tested and verified.',
                    style: const TextStyle(color: Color(0xFF475569), fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 5. Seller Card
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Seller Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
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
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF0075FF).withOpacity(0.12),
                          child: const Icon(Icons.person, color: Color(0xFF0075FF), size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.part.contactName ?? 'Verified Seller',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Row(
                                children: const [
                                  Icon(Icons.star, size: 14, color: Colors.amber),
                                  SizedBox(width: 2),
                                  Text('4.9 (48 ratings) • View Profile →', style: TextStyle(fontSize: 12, color: Color(0xFF0075FF), fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (widget.part.contactPhone != null && widget.part.contactPhone!.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.call, color: Color(0xFF16A34A), size: 24),
                            onPressed: () => _callPhone(widget.part.contactPhone!),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 6. Safety Tips Card (OLX Marketplace Standard)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.shield_outlined, color: Color(0xFF0075FF), size: 18),
                      SizedBox(width: 6),
                      Text('Safety Tips for Auto Buyers', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A), fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('• Meet the seller at a safe public location or mechanic garage.', style: TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4)),
                  const Text('• Inspect the spare part in person before making any payment.', style: TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4)),
                  const Text('• Never send advance courier fee to unverified callers.', style: TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4)),
                ],
              ),
            ),

            // 7. Similar Parts (Matching Brand/Category)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'More parts for ${widget.part.carBrand}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
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
                  height: 190,
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
                          width: 140,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                child: CachedNetworkImage(
                                  imageUrl: item.imageUrl,
                                  height: 95,
                                  width: 140,
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
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0075FF)),
                                    ),
                                    Text(
                                      item.title,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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

      // 8. Bottom Action Bar (Direct Call, Make Offer, Chat with Seller OR Owner Edit/Delete)
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: isOwner
              // Owner Controls
              ? Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete Ad', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _handleDeleteAd,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0075FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit Listing', style: TextStyle(fontWeight: FontWeight.bold)),
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
              // Buyer Controls (Direct Call, Make Offer, Chat - NO WHATSAPP DIRECT)
              : Row(
                  children: [
                    // Direct Call Phone Dialer
                    if (widget.part.contactPhone != null && widget.part.contactPhone!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                            foregroundColor: const Color(0xFF16A34A),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _callPhone(widget.part.contactPhone!),
                          child: const Icon(Icons.call, size: 20),
                        ),
                      ),

                    // Make Offer Button
                    Expanded(
                      flex: 1,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF0075FF)),
                          foregroundColor: const Color(0xFF0075FF),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.local_offer_outlined, size: 18),
                        label: const Text('Make Offer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('Chat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
    );
  }

  Widget _buildSpecTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }
}
