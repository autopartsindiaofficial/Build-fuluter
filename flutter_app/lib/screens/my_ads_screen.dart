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
import 'auth_screen.dart';

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
            content: Text(currentlySold ? 'Ad marked as ACTIVE ✅' : 'Ad marked as SOLD 🎉'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteListing(String partId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Listing', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to permanently delete this ad? This action cannot be undone.'),
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
        await _db.collection('spareParts').doc(partId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Listing deleted successfully.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
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
          title: const Text('My Listed Ads', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          backgroundColor: Colors.white,
          elevation: 0.5,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: const Color(0xFF0075FF).withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.inventory_2_outlined, size: 54, color: Color(0xFF0075FF)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Manage Your Listed Ads',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sign in to edit your listings, mark ads as sold, or view customer inquiries.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0075FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.login),
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

    final currentUid = user.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('My Listed Ads', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('spareParts').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0075FF)));
          }

          final allDocs = snapshot.data?.docs ?? [];

          // Filter listings belonging to this seller
          final myDocs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final sId = (data['sellerId'] ?? data['userId'] ?? '').toString();
            final sEmail = (data['sellerEmail'] ?? '').toString().toLowerCase();
            return sId == currentUid || (user.email != null && sEmail == user.email!.toLowerCase());
          }).toList();

          final activeCount = myDocs.where((d) => (d.data() as Map<String, dynamic>)['status'] != 'sold' && (d.data() as Map<String, dynamic>)['isSold'] != true).length;
          final soldCount = myDocs.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'sold' || (d.data() as Map<String, dynamic>)['isSold'] == true).length;

          // Apply Tab Filter
          var filteredDocs = myDocs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final isSold = data['status'] == 'sold' || data['isSold'] == true;
            if (_activeTab == 'active') return !isSold;
            if (_activeTab == 'sold') return isSold;
            return true;
          }).toList();

          // Apply Search Filter
          if (_searchQuery.isNotEmpty) {
            filteredDocs = filteredDocs.where((d) {
              final data = d.data() as Map<String, dynamic>;
              final title = (data['title'] ?? '').toString().toLowerCase();
              final brand = (data['carBrand'] ?? '').toString().toLowerCase();
              return title.contains(_searchQuery) || brand.contains(_searchQuery);
            }).toList();
          }

          return Column(
            children: [
              // 1. Tab Selector Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildTabChip('active', 'Active ($activeCount)'),
                    const SizedBox(width: 8),
                    _buildTabChip('sold', 'Sold ($soldCount)'),
                    const SizedBox(width: 8),
                    _buildTabChip('all', 'All (${myDocs.length})'),
                  ],
                ),
              ),

              // 2. Search Bar
              if (myDocs.isNotEmpty)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search my ads by title or brand...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ),

              // 3. Listings List
              Expanded(
                child: filteredDocs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                              child: const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _activeTab == 'sold' ? 'No sold ads yet' : "You haven't listed any active spare parts.",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Post your spare part ads to reach buyers across India.',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          final part = SparePart.fromFirestore(doc);
                          final data = doc.data() as Map<String, dynamic>;
                          final isSold = data['status'] == 'sold' || data['isSold'] == true;
                          final views = data['views'] ?? 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
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
                                // Top info row
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => ProductDetailScreen(part: part)),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Thumbnail
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: CachedNetworkImage(
                                            imageUrl: part.imageUrl,
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => Container(color: Colors.grey.shade100),
                                            errorWidget: (_, __, ___) => Container(width: 80, height: 80, color: Colors.grey.shade200, child: const Icon(Icons.car_repair, color: Colors.grey)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Title, Price, Views
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: isSold ? Colors.grey.shade200 : const Color(0xFFDCFCE7),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      isSold ? 'SOLD' : 'ACTIVE',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: isSold ? Colors.grey.shade700 : const Color(0xFF16A34A),
                                                      ),
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF64748B)),
                                                      const SizedBox(width: 4),
                                                      Text('$views views', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                part.title,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _currencyFormatter.format(part.price),
                                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0075FF)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                                // Action Buttons Row
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      // Edit Button
                                      TextButton.icon(
                                        icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF0075FF)),
                                        label: const Text('Edit', style: TextStyle(color: Color(0xFF0075FF), fontSize: 12, fontWeight: FontWeight.bold)),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => EditListingScreen(part: part)),
                                          );
                                        },
                                      ),

                                      // Mark as Sold / Active
                                      TextButton.icon(
                                        icon: Icon(isSold ? Icons.check_circle_outline : Icons.sell_outlined, size: 16, color: const Color(0xFF16A34A)),
                                        label: Text(
                                          isSold ? 'Activate' : 'Mark Sold',
                                          style: const TextStyle(color: Color(0xFF16A34A), fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        onPressed: () => _toggleSoldStatus(part.id, isSold),
                                      ),

                                      // Delete Button
                                      TextButton.icon(
                                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                        label: const Text('Delete', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                                        onPressed: () => _deleteListing(part.id),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabChip(String key, String label) {
    final isSelected = _activeTab == key;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0075FF) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
