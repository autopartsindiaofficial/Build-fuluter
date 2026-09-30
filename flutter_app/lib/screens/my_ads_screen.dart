import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_colors.dart';
import '../models/spare_part.dart';
import '../providers/auth_provider.dart';
import 'product_detail_screen.dart';
import 'edit_listing_screen.dart';
import 'sell_part_screen.dart';
import 'auth_screen.dart';
import '../services/cloudinary_service.dart';

class MyAdsScreen extends StatefulWidget {
  const MyAdsScreen({Key? key}) : super(key: key);

  @override
  State<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  String _activeTab = 'active'; // 'active', 'sold', 'all'
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
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
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleSoldStatus(String partId, bool currentlySold) async {
    try {
      await _db.collection('spareParts').doc(partId).update({
        'status': currentlySold ? 'active' : 'sold',
        'isSold': !currentlySold,
        'sold': !currentlySold,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(currentlySold ? 'Ad marked as Active' : 'Ad marked as Sold'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update ad. Please try again.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteListing(String partId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 8),
            Text('Delete Listing', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently delete this ad? This action cannot be undone.',
          style: TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final partDoc = await _db.collection('spareParts').doc(partId).get();
        if (partDoc.exists) {
          final data = partDoc.data() as Map<String, dynamic>;
          final images = (data['images'] as List?)?.map((e) => e.toString()).toList() ?? [];
          final imgUrl = data['imageUrl'] as String?;
          if (imgUrl != null && imgUrl.isNotEmpty && !images.contains(imgUrl)) {
            images.add(imgUrl);
          }
          if (images.isNotEmpty) {
            CloudinaryService.deleteImages(images);
          }
        }

        await _db.collection('spareParts').doc(partId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🗑️ Listing deleted successfully from marketplace.'),
              backgroundColor: Color(0xFF0F172A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to delete ad. Please try again.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AppAuthProvider>(context);
    final user = auth.user;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('My Listed Ads', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 18)),
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: const Color(0xFFF1F5F9), height: 1),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(color: const Color(0xFF0075FF).withOpacity(0.08), shape: BoxShape.circle),
                  child: const Icon(Icons.inventory_2_outlined, size: 54, color: Color(0xFF0075FF)),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Manage Your Listed Ads',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sign in to edit your listings, mark ads as sold, or view customer inquiries.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0075FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.login_rounded, size: 18),
                  label: const Text('Sign In Now', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final userId = user.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'My Listed Ads',
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0075FF)),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SellPartScreen()));
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: Column(
        children: [
          // Segmented Tabs & Search Container
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                // Segmented Tabs
                Row(
                  children: [
                    _buildTabPill('active', 'Active'),
                    const SizedBox(width: 8),
                    _buildTabPill('sold', 'Sold Out 🎉'),
                    const SizedBox(width: 8),
                    _buildTabPill('all', 'All Ads'),
                  ],
                ),
                const SizedBox(height: 10),

                // Quick Search Box
                Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search my ads by title or car model...',
                      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.cancel_rounded, size: 16, color: Color(0xFF94A3B8)),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Real-time Ads Stream
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('spareParts').where('sellerId', isEqualTo: userId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF0075FF)));
                }

                var docs = snapshot.data?.docs ?? [];

                // Filter by Tab
                if (_activeTab == 'active') {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final isSold = data['status'] == 'sold' || data['isSold'] == true || data['sold'] == true;
                    return !isSold;
                  }).toList();
                } else if (_activeTab == 'sold') {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final isSold = data['status'] == 'sold' || data['isSold'] == true || data['sold'] == true;
                    return isSold;
                  }).toList();
                }

                // Filter by Search
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final t = (data['title'] ?? '').toString().toLowerCase();
                    final b = (data['carBrand'] ?? '').toString().toLowerCase();
                    final m = (data['carModel'] ?? '').toString().toLowerCase();
                    return t.contains(_searchQuery) || b.contains(_searchQuery) || m.contains(_searchQuery);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle),
                            child: const Icon(Icons.inventory_2_outlined, size: 50, color: Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _activeTab == 'sold' ? 'No Sold Parts Yet' : 'No Listed Ads Found',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Post your unused or spare auto parts today to reach thousands of car owners across India.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0075FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                            label: const Text('Post New Spare Part', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const SellPartScreen()));
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final part = SparePart.fromFirestore(doc);
                    final data = doc.data() as Map<String, dynamic>;
                    final isSold = data['status'] == 'sold' || data['isSold'] == true || data['sold'] == true;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Top Part Info Row
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ProductDetailScreen(part: part)),
                              );
                            },
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Part Thumbnail
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: part.imageUrl,
                                      width: 76,
                                      height: 76,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Container(width: 76, height: 76, color: const Color(0xFFF1F5F9)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _currencyFormatter.format(part.price),
                                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isSold ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                isSold ? 'SOLD' : 'ACTIVE',
                                                style: TextStyle(
                                                  color: isSold ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          part.title,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF334155)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.remove_red_eye_rounded, size: 13, color: Color(0xFF64748B)),
                                            const SizedBox(width: 4),
                                            Text('${part.views} views', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                            const SizedBox(width: 12),
                                            const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFF64748B)),
                                            const SizedBox(width: 4),
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
                                ],
                              ),
                            ),
                          ),

                          const Divider(height: 1, color: Color(0xFFF1F5F9)),

                          // Action Toolbar (Sold Toggle, Edit, Delete)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Row(
                              children: [
                                // Toggle Sold / Active Button
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    side: BorderSide(color: isSold ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                                    foregroundColor: isSold ? const Color(0xFF10B981) : const Color(0xFFD97706),
                                    visualDensity: VisualDensity.compact,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  icon: Icon(isSold ? Icons.check_circle_outline_rounded : Icons.monetization_on_outlined, size: 15),
                                  label: Text(isSold ? 'Mark Active' : 'Mark Sold', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                  onPressed: () => _toggleSoldStatus(part.id, isSold),
                                ),
                                const Spacer(),

                                // Edit Button
                                TextButton.icon(
                                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                  icon: const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF0075FF)),
                                  label: const Text('Edit', style: TextStyle(color: Color(0xFF0075FF), fontWeight: FontWeight.bold, fontSize: 12)),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => EditListingScreen(part: part)),
                                    );
                                  },
                                ),
                                const SizedBox(width: 4),

                                // Delete Button
                                TextButton.icon(
                                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                  icon: const Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFEF4444)),
                                  label: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 12)),
                                  onPressed: () => _deleteListing(part.id),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill(String key, String label) {
    final isSelected = _activeTab == key;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0075FF) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
