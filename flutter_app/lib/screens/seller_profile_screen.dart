import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';
import '../models/spare_part.dart';
import 'product_detail_screen.dart';
import 'seller_reviews_screen.dart';
import 'chat_room_screen.dart';
import 'auth_screen.dart';
import '../providers/auth_provider.dart';
import '../widgets/profile_avatar.dart';
import 'package:provider/provider.dart';

class SellerProfileScreen extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  final String? sellerPhone;
  final String? location;

  const SellerProfileScreen({
    Key? key,
    required this.sellerId,
    required this.sellerName,
    this.sellerPhone,
    this.location,
  }) : super(key: key);

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
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

  void _callSeller(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone dialer')),
        );
      }
    }
  }

  Future<void> _toggleFollow(bool isCurrentlyFollowing, String currentUid) async {
    final auth = Provider.of<AppAuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
      return;
    }

    final followDocId = '${widget.sellerId}_$currentUid';
    try {
      if (isCurrentlyFollowing) {
        await _db.collection('seller_follows').doc(followDocId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unfollowed ${widget.sellerName}'), duration: const Duration(seconds: 1)),
          );
        }
      } else {
        await _db.collection('seller_follows').doc(followDocId).set({
          'sellerId': widget.sellerId,
          'followerId': currentUid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You are now following ${widget.sellerName} ⭐'), duration: const Duration(seconds: 1)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update follow status. Please try again.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.sellerName, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          children: [
            // 1. Seller Header Profile Card with Real-time Follow & Ratings
            StreamBuilder<QuerySnapshot>(
              stream: _db.collection('seller_follows').where('sellerId', isEqualTo: widget.sellerId).snapshots(),
              builder: (context, followSnap) {
                final followersDocs = followSnap.data?.docs ?? [];
                final followersCount = followersDocs.length;
                final isFollowing = followersDocs.any((d) => (d.data() as Map<String, dynamic>)['followerId'] == currentUid);

                return StreamBuilder<QuerySnapshot>(
                  stream: _db.collection('seller_reviews').where('sellerId', isEqualTo: widget.sellerId).snapshots(),
                  builder: (context, reviewSnap) {
                    final reviewDocs = reviewSnap.data?.docs ?? [];
                    final reviewCount = reviewDocs.length;
                    double totalRating = 0;
                    for (var doc in reviewDocs) {
                      final data = doc.data() as Map<String, dynamic>;
                      totalRating += ((data['rating'] ?? 5) as num).toDouble();
                    }
                    final avgRating = reviewCount > 0 ? (totalRating / reviewCount).toStringAsFixed(1) : '5.0';

                    return Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.white,
                      child: Column(
                        children: [
                          StreamBuilder<DocumentSnapshot>(
                            stream: widget.sellerId.isNotEmpty
                                ? _db.collection('users').doc(widget.sellerId).snapshots()
                                : null,
                            builder: (context, userSnap) {
                              String? photoUrl;
                              if (userSnap.hasData && userSnap.data != null && userSnap.data!.exists) {
                                final uData = userSnap.data!.data() as Map<String, dynamic>?;
                                photoUrl = uData?['photoUrl'] ?? uData?['avatarUrl'] ?? uData?['photoURL'] ?? uData?['profileImage'] ?? uData?['profilePhoto'];
                              }
                              return ProfileAvatar(
                                name: widget.sellerName,
                                photoUrl: photoUrl,
                                radius: 38,
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  widget.sellerName,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.verified_rounded, color: Color(0xFF0075FF), size: 18),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                            child: const Text('VERIFIED AUTO TRADER', style: TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.w900)),
                          ),
                          if (widget.location != null && widget.location!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text(widget.location!, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 18),

                          // Stats Row (Real Rating & Followers)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildMetric('Rating', '$avgRating ⭐ ($reviewCount)', () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => SellerReviewsScreen(sellerId: widget.sellerId, sellerName: widget.sellerName)),
                                );
                              }),
                              const SizedBox(width: 28),
                              _buildMetric('Followers', '$followersCount', () {}),
                              const SizedBox(width: 28),
                              _buildMetric('Response', '< 15 mins', () {}),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Actions: Direct Call & In-App Chat & Follow
                          Row(
                            children: [
                              // Follow / Unfollow Button
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: isFollowing ? const Color(0xFF10B981) : const Color(0xFF0075FF)),
                                    foregroundColor: isFollowing ? const Color(0xFF10B981) : const Color(0xFF0075FF),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  icon: Icon(isFollowing ? Icons.check_circle_rounded : Icons.person_add_alt_1_rounded, size: 18),
                                  label: Text(isFollowing ? 'Following' : 'Follow Seller', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  onPressed: () => _toggleFollow(isFollowing, currentUid),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Call Button
                              if (widget.sellerPhone != null && widget.sellerPhone!.isNotEmpty) ...[
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFF10B981)),
                                    foregroundColor: const Color(0xFF10B981),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                  onPressed: () => _callSeller(context, widget.sellerPhone!),
                                  child: const Icon(Icons.call_rounded, size: 20),
                                ),
                                const SizedBox(width: 10),
                              ],

                              // Chat Button
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0075FF),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                                  label: const Text('Chat with Seller', style: TextStyle(fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    final conversationId = '${currentUid}_${widget.sellerId}_general';
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatRoomScreen(
                                          conversationId: conversationId,
                                          partTitle: 'Direct Seller Inquiry',
                                          sellerName: widget.sellerName,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 16),

            // 2. Seller's Listed Spare Parts
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    "Parts Listed by ${widget.sellerName}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: _db.collection('spareParts').where('sellerId', isEqualTo: widget.sellerId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF0075FF))),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 42, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 10),
                        const Text('No Active Parts Listed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                        const SizedBox(height: 4),
                        const Text('This seller currently has no other parts listed on the marketplace.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final part = SparePart.fromFirestore(docs[index]);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ProductDetailScreen(part: part)),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: part.imageUrl,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(width: 70, height: 70, color: const Color(0xFFF1F5F9)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currencyFormatter.format(part.price),
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      part.title,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF334155)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_rounded, size: 12, color: Color(0xFF64748B)),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(
                                            part.location,
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
                              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}
