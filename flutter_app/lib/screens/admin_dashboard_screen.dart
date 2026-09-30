import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../models/spare_part.dart';
import 'admin_taxonomy_screen.dart';
import 'product_detail_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NumberFormat _currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  
  // Super admin emails matching React Native
  static const List<String> superAdminEmails = [
    'wwwautoparts2@gmail.com',
    'www.allahforgiveness877@gmail.com',
  ];

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

  // Listings filter & search
  String _listingSearch = '';
  String _listingFilter = 'all'; // all, active, pending, featured, reported, sold, trash
  final Set<String> _selectedPartIds = {};

  // Users search
  String _userSearch = '';

  // Announcements form
  final _annTitleController = TextEditingController();
  final _annMessageController = TextEditingController();
  String _annPriority = 'normal';
  bool _isSendingAnn = false;

  // Version config
  final _latestVerController = TextEditingController(text: '1.0.0');
  final _minVerController = TextEditingController(text: '1.0.0');
  final _apkUrlController = TextEditingController(text: 'https://autopartsindia.app/download/app-latest.apk');
  final _releaseNotesController = TextEditingController(text: '• Performance improvements\n• Bug fixes & UI refinements\n• Real-time chat & notifications');
  bool _forceUpdate = false;
  bool _isLoadingVersion = false;
  bool _isSavingVersion = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _loadVersionConfig();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _annTitleController.dispose();
    _annMessageController.dispose();
    _latestVerController.dispose();
    _minVerController.dispose();
    _apkUrlController.dispose();
    _releaseNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadVersionConfig() async {
    setState(() => _isLoadingVersion = true);
    try {
      final doc = await _db.collection('app_version').doc('config').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _latestVerController.text = data['latestVersion'] ?? '1.0.0';
        _minVerController.text = data['minimumSupportedVersion'] ?? '1.0.0';
        _apkUrlController.text = data['apkDownloadUrl'] ?? '';
        _releaseNotesController.text = data['releaseNotes'] ?? '';
        _forceUpdate = data['forceUpdate'] == true;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingVersion = false);
  }

  Future<void> _saveVersionConfig() async {
    setState(() => _isSavingVersion = true);
    try {
      await _db.collection('app_version').doc('config').set({
        'latestVersion': _latestVerController.text.trim(),
        'minimumSupportedVersion': _minVerController.text.trim(),
        'apkDownloadUrl': _apkUrlController.text.trim(),
        'releaseNotes': _releaseNotesController.text.trim(),
        'forceUpdate': _forceUpdate,
        'releaseDate': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App Version Configuration saved to Cloud!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save version config: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingVersion = false);
    }
  }

  bool _isSuperAdmin() {
    final user = FirebaseAuth.instance.currentUser;
    final email = (user?.email ?? '').trim().toLowerCase();
    return superAdminEmails.contains(email);
  }

  @override
  Widget build(BuildContext context) {
    // 1. Authorization check
    if (!_isSuperAdmin()) {
      final currentEmail = FirebaseAuth.instance.currentUser?.email ?? 'Guest / Not Signed In';
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('Admin Console')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_outlined, size: 40, color: Color(0xFFEF4444)),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Restricted Admin Access',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                Text(
                  'This Admin Console is strictly restricted to authorized administrators (wwwautoparts2@gmail.com / www.allahforgiveness877@gmail.com).\nCurrent account: $currentEmail',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back to Marketplace'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. Authorized Admin View
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Admin Master Console',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree_outlined, color: AppColors.primary),
            tooltip: 'Vehicle Taxonomy CMS',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTaxonomyScreen()));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined, size: 18), text: 'Overview'),
            Tab(icon: Icon(Icons.inventory_2_outlined, size: 18), text: 'Listings'),
            Tab(icon: Icon(Icons.people_outline, size: 18), text: 'Users'),
            Tab(icon: Icon(Icons.view_carousel_outlined, size: 18), text: 'Banners'),
            Tab(icon: Icon(Icons.category_outlined, size: 18), text: 'Top Categories'),
            Tab(icon: Icon(Icons.directions_car_outlined, size: 18), text: 'Car Brands'),
            Tab(icon: Icon(Icons.campaign_outlined, size: 18), text: 'Announcements'),
            Tab(icon: Icon(Icons.system_update_outlined, size: 18), text: 'Version Control'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildListingsTab(),
          _buildUsersTab(),
          _buildBannersTab(),
          _buildTopCategoriesTab(),
          _buildCarBrandsTab(),
          _buildAnnouncementsTab(),
          _buildVersionTab(),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: OVERVIEW TAB
  // ==========================================
  Widget _buildOverviewTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('spareParts').snapshots(),
      builder: (context, partsSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: _db.collection('users').snapshots(),
          builder: (context, usersSnap) {
            final parts = partsSnap.data?.docs ?? [];
            final users = usersSnap.data?.docs ?? [];

            final totalListings = parts.length;
            final activeListings = parts.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'approved' && (d.data() as Map<String, dynamic>)['sold'] != true && (d.data() as Map<String, dynamic>)['isDeleted'] != true).length;
            final pendingListings = parts.where((d) => (d.data() as Map<String, dynamic>)['status'] == 'pending' || (d.data() as Map<String, dynamic>)['approved'] == false).length;
            final reportedListings = parts.where((d) => (d.data() as Map<String, dynamic>)['reported'] == true).length;
            final totalUsers = users.length;

            double totalGmv = 0;
            for (var doc in parts) {
              final data = doc.data() as Map<String, dynamic>;
              totalGmv += (data['price'] is num ? data['price'] : 0).toDouble();
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Platform GMV Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Marketplace GMV Listed', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(
                          _currencyFormatter.format(totalGmv),
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$totalListings Total Spare Parts Listed across India',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Metrics Grid
                  const Text('Key Platform Metrics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildMetricCard('Total Parts', '$totalListings', Icons.directions_car, Colors.blue),
                      _buildMetricCard('Active Ads', '$activeListings', Icons.check_circle, Colors.green),
                      _buildMetricCard('Pending Review', '$pendingListings', Icons.hourglass_top, Colors.amber),
                      _buildMetricCard('Registered Users', '$totalUsers', Icons.people, Colors.purple),
                      _buildMetricCard('Reported Ads', '$reportedListings', Icons.flag, Colors.red),
                      _buildMetricCard('Live Database', 'Connected', Icons.cloud_done, Colors.teal),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quick Shortcuts
                  const Text('Admin Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  _buildQuickActionTile('Manage Vehicle Taxonomy', 'Add and edit car brands, models, and parts categories', Icons.account_tree, Colors.blue, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTaxonomyScreen()));
                  }),
                  _buildQuickActionTile('Review Pending Ads', 'Quickly approve or reject new listings', Icons.rate_review, Colors.amber, () {
                    _tabController.animateTo(1);
                    setState(() => _listingFilter = 'pending');
                  }),
                  _buildQuickActionTile('Send Broadcast Notification', 'Broadcast immediate message to all app users', Icons.campaign, Colors.purple, () {
                    _tabController.animateTo(6);
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 20, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  // ==========================================
  // TAB 2: LISTINGS MODERATION
  // ==========================================
  Widget _buildListingsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('spareParts').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        List<Map<String, dynamic>> items = docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          data['id'] = d.id;
          return data;
        }).toList();

        // Apply filters
        if (_listingSearch.isNotEmpty) {
          final query = _listingSearch.toLowerCase();
          items = items.where((i) {
            final t = (i['title'] ?? '').toString().toLowerCase();
            final b = (i['carBrand'] ?? '').toString().toLowerCase();
            final m = (i['carModel'] ?? '').toString().toLowerCase();
            final c = (i['category'] ?? '').toString().toLowerCase();
            return t.contains(query) || b.contains(query) || m.contains(query) || c.contains(query);
          }).toList();
        }

        if (_listingFilter == 'active') {
          items = items.where((i) => i['status'] == 'approved' && i['isDeleted'] != true && i['sold'] != true).toList();
        } else if (_listingFilter == 'pending') {
          items = items.where((i) => i['status'] == 'pending' || i['approved'] == false).toList();
        } else if (_listingFilter == 'featured') {
          items = items.where((i) => i['featured'] == true).toList();
        } else if (_listingFilter == 'reported') {
          items = items.where((i) => i['reported'] == true).toList();
        } else if (_listingFilter == 'sold') {
          items = items.where((i) => i['sold'] == true).toList();
        } else if (_listingFilter == 'trash') {
          items = items.where((i) => i['isDeleted'] == true).toList();
        }

        return Column(
          children: [
            // Search & Filter header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search parts by title, brand, model...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    onChanged: (val) => setState(() => _listingSearch = val.trim()),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'All (${docs.length})'),
                        _buildFilterChip('active', 'Active'),
                        _buildFilterChip('pending', 'Pending Approval'),
                        _buildFilterChip('featured', 'Featured ⭐'),
                        _buildFilterChip('reported', 'Reported 🚩'),
                        _buildFilterChip('sold', 'Sold Out'),
                        _buildFilterChip('trash', 'Trash 🗑️'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bulk action bar
            if (_selectedPartIds.isNotEmpty)
              Container(
                color: const Color(0xFFFEF2F2),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_selectedPartIds.length} items selected', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                    TextButton.icon(
                      onPressed: _handleBulkDelete,
                      icon: const Icon(Icons.delete_forever, color: Color(0xFFDC2626), size: 18),
                      label: const Text('Delete Selected', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),

            // Listings List
            Expanded(
              child: items.isEmpty
                  ? Center(child: Text('No listings found in $_listingFilter filter.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: items.length,
                      itemBuilder: (context, idx) {
                        final item = items[idx];
                        final isSelected = _selectedPartIds.contains(item['id']);
                        final isApproved = item['status'] == 'approved' || item['approved'] == true;
                        final isFeatured = item['featured'] == true;
                        final isSold = item['sold'] == true;
                        final isDeleted = item['isDeleted'] == true;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0), width: isSelected ? 2 : 1),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (val) {
                                        setState(() {
                                          if (val == true) {
                                            _selectedPartIds.add(item['id']);
                                          } else {
                                            _selectedPartIds.remove(item['id']);
                                          }
                                        });
                                      },
                                    ),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: item['imageUrl'] ?? '',
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(color: Colors.grey.shade200),
                                        errorWidget: (_, __, ___) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item['title'] ?? 'Untitled Part', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          Text(
                                            '${item['carBrand'] ?? ''} ${item['carModel'] ?? ''} • ${item['category'] ?? ''}',
                                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _currencyFormatter.format(item['price'] ?? 0),
                                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                // Action Chips / Buttons
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    // Status Badge
                                    Chip(
                                      backgroundColor: isApproved ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                                      label: Text(
                                        isApproved ? 'Approved' : 'Pending',
                                        style: TextStyle(color: isApproved ? const Color(0xFF16A34A) : const Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    // Approve / Reject Toggle
                                    ActionChip(
                                      label: Text(isApproved ? 'Unapprove' : 'Approve ✅', style: const TextStyle(fontSize: 11)),
                                      onPressed: () => _toggleListingApprove(item),
                                    ),
                                    // Feature Toggle
                                    ActionChip(
                                      label: Text(isFeatured ? 'Featured ⭐' : 'Make Featured', style: const TextStyle(fontSize: 11)),
                                      onPressed: () => _toggleListingFeatured(item),
                                    ),
                                    // Sold Toggle
                                    ActionChip(
                                      label: Text(isSold ? 'Sold' : 'Mark Sold', style: const TextStyle(fontSize: 11)),
                                      onPressed: () => _toggleListingSold(item),
                                    ),
                                    // Trash / Restore
                                    ActionChip(
                                      label: Text(isDeleted ? 'Restore ♻️' : 'Move to Trash 🗑️', style: const TextStyle(fontSize: 11)),
                                      onPressed: () => _toggleListingTrash(item),
                                    ),
                                    // Delete Permanently
                                    ActionChip(
                                      backgroundColor: const Color(0xFFFEE2E2),
                                      label: const Text('Delete ❌', style: TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.bold)),
                                      onPressed: () => _deleteListingPermanent(item),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _listingFilter == filterKey;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : const Color(0xFF334155))),
        selectedColor: AppColors.primary,
        backgroundColor: const Color(0xFFF1F5F9),
        onSelected: (val) => setState(() => _listingFilter = filterKey),
      ),
    );
  }

  Future<void> _toggleListingApprove(Map<String, dynamic> item) async {
    final newApproved = item['status'] != 'approved';
    await _db.collection('spareParts').doc(item['id']).update({
      'approved': newApproved,
      'status': newApproved ? 'approved' : 'pending',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _toggleListingFeatured(Map<String, dynamic> item) async {
    final newFeatured = !(item['featured'] == true);
    await _db.collection('spareParts').doc(item['id']).update({
      'featured': newFeatured,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _toggleListingSold(Map<String, dynamic> item) async {
    final newSold = !(item['sold'] == true);
    await _db.collection('spareParts').doc(item['id']).update({
      'sold': newSold,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _toggleListingTrash(Map<String, dynamic> item) async {
    final newTrash = !(item['isDeleted'] == true);
    await _db.collection('spareParts').doc(item['id']).update({
      'isDeleted': newTrash,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteListingPermanent(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Permanent Delete'),
        content: Text('Are you sure you want to permanently delete "${item['title']}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.collection('spareParts').doc(item['id']).delete();
      _selectedPartIds.remove(item['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Listing permanently deleted.')));
      }
    }
  }

  Future<void> _handleBulkDelete() async {
    final count = _selectedPartIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bulk Delete Listings'),
        content: Text('Permanently delete $count selected listings? This action cannot be reversed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete $count'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (final id in _selectedPartIds) {
        await _db.collection('spareParts').doc(id).delete();
      }
      setState(() => _selectedPartIds.clear());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$count listings permanently deleted.')));
      }
    }
  }

  // ==========================================
  // TAB 3: USERS MANAGEMENT
  // ==========================================
  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        List<Map<String, dynamic>> users = docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          data['id'] = d.id;
          return data;
        }).toList();

        if (_userSearch.isNotEmpty) {
          final query = _userSearch.toLowerCase();
          users = users.where((u) {
            final n = (u['name'] ?? u['displayName'] ?? '').toString().toLowerCase();
            final e = (u['email'] ?? '').toString().toLowerCase();
            final p = (u['phone'] ?? '').toString().toLowerCase();
            return n.contains(query) || e.contains(query) || p.contains(query);
          }).toList();
        }

        return Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search users by name, email, or phone...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                onChanged: (val) => setState(() => _userSearch = val.trim()),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: users.length,
                itemBuilder: (context, idx) {
                  final u = users[idx];
                  final isBlocked = u['isBlocked'] == true;
                  final isSuper = superAdminEmails.contains((u['email'] ?? '').toString().toLowerCase());

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isSuper ? Colors.amber.shade100 : Colors.blue.shade100,
                                child: Icon(isSuper ? Icons.star : Icons.person, color: isSuper ? Colors.amber.shade800 : AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(u['name'] ?? u['displayName'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        if (isSuper)
                                          Container(
                                            margin: const EdgeInsets.only(left: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)),
                                            child: const Text('SUPER ADMIN', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.brown)),
                                          ),
                                      ],
                                    ),
                                    Text(u['email'] ?? 'No Email', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                    if ((u['phone'] ?? '').toString().isNotEmpty)
                                      Text('📞 ${u['phone']}', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                                  ],
                                ),
                              ),
                              if (isBlocked)
                                const Chip(
                                  label: Text('BLOCKED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                  backgroundColor: Colors.red,
                                  visualDensity: VisualDensity.compact,
                                ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${u['district'] ?? ''}, ${u['state'] ?? 'India'}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                              if (!isSuper)
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () => _openEditUserDialog(u),
                                      child: const Text('Edit Profile'),
                                    ),
                                    TextButton(
                                      onPressed: () => _toggleBlockUser(u),
                                      child: Text(isBlocked ? 'Unblock' : 'Suspend / Block', style: TextStyle(color: isBlocked ? Colors.green : Colors.red)),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _openEditUserDialog(Map<String, dynamic> user) {
    final nameCtrl = TextEditingController(text: user['name'] ?? user['displayName'] ?? '');
    final phoneCtrl = TextEditingController(text: user['phone'] ?? '');
    final districtCtrl = TextEditingController(text: user['district'] ?? '');
    final stateCtrl = TextEditingController(text: user['state'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit User Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: districtCtrl, decoration: const InputDecoration(labelText: 'District')),
              TextField(controller: stateCtrl, decoration: const InputDecoration(labelText: 'State')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _db.collection('users').doc(user['id']).update({
                'name': nameCtrl.text.trim(),
                'displayName': nameCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'district': districtCtrl.text.trim(),
                'state': stateCtrl.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBlockUser(Map<String, dynamic> user) async {
    final currentlyBlocked = user['isBlocked'] == true;
    await _db.collection('users').doc(user['id']).update({
      'isBlocked': !currentlyBlocked,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==========================================
  // TAB 4: BANNERS CMS
  // ==========================================
  Widget _buildBannersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('banners').orderBy('order', descending: false).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Banner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () => _openBannerDialog(null),
          ),
          body: docs.isEmpty
              ? const Center(child: Text('No promotional banners configured.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, idx) {
                    final data = docs[idx].data() as Map<String, dynamic>;
                    data['id'] = docs[idx].id;
                    final isActive = data['active'] != false;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((data['imageUrl'] ?? '').toString().isNotEmpty)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: CachedNetworkImage(
                                imageUrl: data['imageUrl'],
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(height: 80, color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(data['title'] ?? 'Banner', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      Text(data['subtitle'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                      const SizedBox(height: 4),
                                      Text('Order: ${data['order'] ?? 0} • Tag: ${data['tag'] ?? 'Offer'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: isActive,
                                  onChanged: (val) {
                                    _db.collection('banners').doc(data['id']).update({'active': val});
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _openBannerDialog(data),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () => _db.collection('banners').doc(data['id']).delete(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  void _openBannerDialog(Map<String, dynamic>? banner) {
    final titleCtrl = TextEditingController(text: banner?['title'] ?? '');
    final subtitleCtrl = TextEditingController(text: banner?['subtitle'] ?? '');
    final imageCtrl = TextEditingController(text: banner?['imageUrl'] ?? '');
    final linkCtrl = TextEditingController(text: banner?['targetLink'] ?? '');
    final tagCtrl = TextEditingController(text: banner?['tag'] ?? 'Special Offer');
    final orderCtrl = TextEditingController(text: '${banner?['order'] ?? 0}');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(banner == null ? 'Add Promotional Banner' : 'Edit Banner'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Banner Title *')),
              TextField(controller: subtitleCtrl, decoration: const InputDecoration(labelText: 'Subtitle / Description')),
              TextField(controller: imageCtrl, decoration: const InputDecoration(labelText: 'Image URL *')),
              TextField(controller: linkCtrl, decoration: const InputDecoration(labelText: 'Target URL / Category Link')),
              TextField(controller: tagCtrl, decoration: const InputDecoration(labelText: 'Tag (e.g. 50% OFF, Genuine)')),
              TextField(controller: orderCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Display Order')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isEmpty || imageCtrl.text.isEmpty) return;
              final payload = {
                'title': titleCtrl.text.trim(),
                'subtitle': subtitleCtrl.text.trim(),
                'imageUrl': imageCtrl.text.trim(),
                'targetLink': linkCtrl.text.trim(),
                'tag': tagCtrl.text.trim(),
                'order': int.tryParse(orderCtrl.text.trim()) ?? 0,
                'active': banner?['active'] ?? true,
                'updatedAt': FieldValue.serverTimestamp(),
              };

              if (banner == null) {
                await _db.collection('banners').add(payload);
              } else {
                await _db.collection('banners').doc(banner['id']).update(payload);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 5: TOP CATEGORIES CMS
  // ==========================================
  Widget _buildTopCategoriesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('topCategories').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        return Scaffold(
          floatingActionButton: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                heroTag: 'seedCats',
                backgroundColor: const Color(0xFF0F172A),
                icon: const Icon(Icons.restart_alt, color: Colors.white),
                label: const Text('Seed Defaults', style: TextStyle(color: Colors.white)),
                onPressed: _seedDefaultCategories,
              ),
              const SizedBox(width: 10),
              FloatingActionButton.extended(
                heroTag: 'addCat',
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Add Category', style: TextStyle(color: Colors.white)),
                onPressed: () => _openCategoryDialog(null),
              ),
            ],
          ),
          body: docs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No top categories found.'),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _seedDefaultCategories, child: const Text('Seed 8 Default Auto Categories')),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, idx) {
                    final data = docs[idx].data() as Map<String, dynamic>;
                    data['id'] = docs[idx].id;
                    final isActive = data['active'] != false;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: data['imageUrl'] ?? '',
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Icon(Icons.category),
                          ),
                        ),
                        title: Text(data['name'] ?? 'Category', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Order: ${data['order'] ?? 0}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: isActive,
                              onChanged: (val) => _db.collection('topCategories').doc(data['id']).update({'active': val}),
                            ),
                            IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _openCategoryDialog(data)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _db.collection('topCategories').doc(data['id']).delete()),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  void _openCategoryDialog(Map<String, dynamic>? cat) {
    final nameCtrl = TextEditingController(text: cat?['name'] ?? '');
    final imgCtrl = TextEditingController(text: cat?['imageUrl'] ?? '');
    final orderCtrl = TextEditingController(text: '${cat?['order'] ?? 0}');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(cat == null ? 'Add Top Category' : 'Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Category Name *')),
            TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: 'Icon / Image URL *')),
            TextField(controller: orderCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Display Order')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final payload = {
                'name': nameCtrl.text.trim(),
                'imageUrl': imgCtrl.text.trim(),
                'order': int.tryParse(orderCtrl.text.trim()) ?? 0,
                'active': cat?['active'] ?? true,
                'updatedAt': FieldValue.serverTimestamp(),
              };

              if (cat == null) {
                await _db.collection('topCategories').add(payload);
              } else {
                await _db.collection('topCategories').doc(cat['id']).update(payload);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _seedDefaultCategories() async {
    final defaults = [
      {'name': 'Engine & Mechanical', 'order': 0, 'imageUrl': 'https://res.cloudinary.com/rqf1hlrx/image/upload/v1788828857/categories/v40ctc1xzsul1nmquwno.png'},
      {'name': 'Body & Exterior', 'order': 1, 'imageUrl': 'https://res.cloudinary.com/rqf1hlrx/image/upload/v1788915211/categories/ssxl1agf8ydkau5aqv4h.png'},
      {'name': 'Lights & Electricals', 'order': 2, 'imageUrl': 'https://res.cloudinary.com/rqf1hlrx/image/upload/v1788746594/categories/w1tym7epvnhv0f9aapuf.png'},
      {'name': 'Suspension & Brakes', 'order': 3, 'imageUrl': 'https://res.cloudinary.com/rqf1hlrx/image/upload/v1788808169/categories/ebbks7ce3jejqgtxlndo.png'},
      {'name': 'Interior & Dashboard', 'order': 4, 'imageUrl': 'https://res.cloudinary.com/rqf1hlrx/image/upload/v1788828857/categories/v40ctc1xzsul1nmquwno.png'},
      {'name': 'Wheels & Tyres', 'order': 5, 'imageUrl': 'https://res.cloudinary.com/rqf1hlrx/image/upload/v1788915211/categories/ssxl1agf8ydkau5aqv4h.png'},
    ];

    for (var cat in defaults) {
      await _db.collection('topCategories').add({
        ...cat,
        'active': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Default Categories Seeded to Cloud Firestore!')));
    }
  }

  // ==========================================
  // TAB 6: CAR BRANDS CMS
  // ==========================================
  Widget _buildCarBrandsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('carBrands').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        return Scaffold(
          floatingActionButton: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                heroTag: 'seedBrands',
                backgroundColor: const Color(0xFF0F172A),
                icon: const Icon(Icons.restart_alt, color: Colors.white),
                label: const Text('Seed Brands', style: TextStyle(color: Colors.white)),
                onPressed: _seedDefaultCarBrands,
              ),
              const SizedBox(width: 10),
              FloatingActionButton.extended(
                heroTag: 'addBrand',
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Add Brand', style: TextStyle(color: Colors.white)),
                onPressed: () => _openBrandDialog(null),
              ),
            ],
          ),
          body: docs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No car brands configured.'),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _seedDefaultCarBrands, child: const Text('Seed Popular Indian Car Brands')),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, idx) {
                    final data = docs[idx].data() as Map<String, dynamic>;
                    data['id'] = docs[idx].id;
                    final isActive = data['active'] != false;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: data['imageUrl'] ?? data['logoUrl'] ?? '',
                            width: 44,
                            height: 44,
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) => const Icon(Icons.directions_car),
                          ),
                        ),
                        title: Text(data['name'] ?? 'Car Brand', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Order: ${data['order'] ?? 0}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: isActive,
                              onChanged: (val) => _db.collection('carBrands').doc(data['id']).update({'active': val}),
                            ),
                            IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _openBrandDialog(data)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => _db.collection('carBrands').doc(data['id']).delete()),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  void _openBrandDialog(Map<String, dynamic>? brand) {
    final nameCtrl = TextEditingController(text: brand?['name'] ?? '');
    final imgCtrl = TextEditingController(text: brand?['imageUrl'] ?? brand?['logoUrl'] ?? '');
    final orderCtrl = TextEditingController(text: '${brand?['order'] ?? 0}');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(brand == null ? 'Add Car Brand' : 'Edit Car Brand'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Brand Name (e.g. Maruti, Tata) *')),
            TextField(controller: imgCtrl, decoration: const InputDecoration(labelText: 'Logo URL *')),
            TextField(controller: orderCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Display Order')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final payload = {
                'name': nameCtrl.text.trim(),
                'imageUrl': imgCtrl.text.trim(),
                'logoUrl': imgCtrl.text.trim(),
                'order': int.tryParse(orderCtrl.text.trim()) ?? 0,
                'active': brand?['active'] ?? true,
                'updatedAt': FieldValue.serverTimestamp(),
              };

              if (brand == null) {
                await _db.collection('carBrands').add(payload);
              } else {
                await _db.collection('carBrands').doc(brand['id']).update(payload);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _seedDefaultCarBrands() async {
    final defaults = [
      {'name': 'Maruti Suzuki', 'order': 0, 'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/12/Suzuki_logo_2.svg/320px-Suzuki_logo_2.svg.png'},
      {'name': 'Hyundai', 'order': 1, 'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/Hyundai_Motor_Company_logo.svg/320px-Hyundai_Motor_Company_logo.svg.png'},
      {'name': 'Tata Motors', 'order': 2, 'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8e/Tata_logo.svg/320px-Tata_logo.svg.png'},
      {'name': 'Mahindra', 'order': 3, 'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/66/Mahindra_%26_Mahindra_Logo.svg/320px-Mahindra_%26_Mahindra_Logo.svg.png'},
      {'name': 'Toyota', 'order': 4, 'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/ee/Toyota_logo_%282020%29.svg/320px-Toyota_logo_%282020%29.svg.png'},
      {'name': 'Honda', 'order': 5, 'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Honda_Logo.svg/320px-Honda_Logo.svg.png'},
      {'name': 'Kia', 'order': 6, 'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/KIA_logo2.svg/320px-KIA_logo2.svg.png'},
    ];

    for (var b in defaults) {
      await _db.collection('carBrands').add({
        ...b,
        'active': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Popular Indian Car Brands Seeded!')));
    }
  }

  // ==========================================
  // TAB 7: ANNOUNCEMENTS
  // ==========================================
  Widget _buildAnnouncementsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Broadcast Push Announcement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('This sends an in-app notice and alert to all active app users.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                const SizedBox(height: 16),
                TextField(
                  controller: _annTitleController,
                  decoration: const InputDecoration(labelText: 'Announcement Title', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _annMessageController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Detailed Message / Notice', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _annPriority,
                  decoration: const InputDecoration(labelText: 'Priority Level', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'normal', child: Text('Normal Priority')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgent / High Priority 🚨')),
                  ],
                  onChanged: (val) => setState(() => _annPriority = val ?? 'normal'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isSendingAnn
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send),
                    label: Text(_isSendingAnn ? 'Broadcasting...' : 'Broadcast to All Users'),
                    onPressed: _isSendingAnn ? null : _sendBroadcastAnnouncement,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Past Announcements History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('announcements').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) return const Text('No past announcements.', style: TextStyle(color: Colors.grey));
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, idx) {
                  final data = docs[idx].data() as Map<String, dynamic>;
                  data['id'] = docs[idx].id;
                  final isUrgent = data['priority'] == 'urgent';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(Icons.campaign, color: isUrgent ? Colors.red : Colors.blue),
                      title: Text(data['title'] ?? 'Notice', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(data['message'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey, size: 20),
                        onPressed: () => _db.collection('announcements').doc(data['id']).delete(),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _sendBroadcastAnnouncement() async {
    final title = _annTitleController.text.trim();
    final msg = _annMessageController.text.trim();
    if (title.isEmpty || msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill title and message.')));
      return;
    }

    setState(() => _isSendingAnn = true);
    try {
      await _db.collection('announcements').add({
        'title': title,
        'message': msg,
        'priority': _annPriority,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _annTitleController.clear();
      _annMessageController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Broadcast sent successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to broadcast: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSendingAnn = false);
    }
  }

  // ==========================================
  // TAB 8: VERSION CONTROL & OTA
  // ==========================================
  Widget _buildVersionTab() {
    if (_isLoadingVersion) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('App Version & Update Management', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Control in-app updates and mandatory version enforcement across Android & iOS.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            const SizedBox(height: 16),
            TextField(controller: _latestVerController, decoration: const InputDecoration(labelText: 'Latest Release Version (e.g. 1.0.1)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _minVerController, decoration: const InputDecoration(labelText: 'Minimum Supported Version (e.g. 1.0.0)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _apkUrlController, decoration: const InputDecoration(labelText: 'APK / App Store Download URL', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _releaseNotesController, maxLines: 4, decoration: const InputDecoration(labelText: 'Release Notes', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enforce Force Update', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Block older app versions until user updates the application', style: TextStyle(fontSize: 12, color: Colors.grey)),
              value: _forceUpdate,
              onChanged: (val) => setState(() => _forceUpdate = val),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isSavingVersion
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(_isSavingVersion ? 'Saving to Cloud...' : 'Save & Publish App Version Config'),
                onPressed: _isSavingVersion ? null : _saveVersionConfig,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
