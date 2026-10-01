import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/parts_provider.dart';
import '../providers/language_provider.dart';
import 'auth_screen.dart';
import 'edit_profile_screen.dart';
import 'my_ads_screen.dart';
import 'wishlist_screen.dart';
import 'notifications_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_taxonomy_screen.dart';
import 'help_support_screen.dart';
import 'recently_viewed_screen.dart';
import 'settings_screen.dart';
import '../widgets/profile_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  static const List<String> SUPER_ADMIN_EMAILS = [
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

  void _showLanguageDialog(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.language_rounded, color: Color(0xFF0075FF), size: 22),
            SizedBox(width: 8),
            Text('Language / மொழி', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English (Default)', style: TextStyle(fontWeight: FontWeight.w700)),
              trailing: lang.currentLanguage == 'en' ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0075FF)) : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                lang.setLanguage('en');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('தமிழ் (Tamil)', style: TextStyle(fontWeight: FontWeight.w700)),
              trailing: lang.currentLanguage == 'ta' ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0075FF)) : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                lang.setLanguage('ta');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('हिन्दी (Hindi)', style: TextStyle(fontWeight: FontWeight.w700)),
              trailing: lang.currentLanguage == 'hi' ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0075FF)) : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () {
                lang.setLanguage('hi');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AppAuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 8),
            Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out from Auto Parts India?',
          style: TextStyle(color: Color(0xFF475569), fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.signOut();
            },
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AppAuthProvider>(context);
    final partsProvider = Provider.of<PartsProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final user = auth.user;
    final userEmail = (user?.email ?? '').toLowerCase().trim();
    final isAdmin = SUPER_ADMIN_EMAILS.contains(userEmail) || auth.userProfile?.role == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          lang.t('profile'),
          style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF0F172A)),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          children: [
            // 1. User Header & Profile Avatar Card
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar with tap-to-zoom round preview
                      Stack(
                        children: [
                          ProfileAvatar(
                            photoUrl: auth.userProfile?.photoURL ?? user?.photoURL,
                            name: auth.userProfile?.displayName ?? user?.displayName ?? 'Auto Enthusiast',
                            radius: 36,
                          ),
                          if (isAdmin)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF59E0B),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Details
                      Expanded(
                        child: auth.isAuthenticated
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          user?.displayName ?? 'Auto Parts Trader',
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF0075FF)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user?.email ?? '',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  if (isAdmin)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFFDE68A)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.shield_rounded, size: 12, color: Color(0xFFD97706)),
                                          SizedBox(width: 4),
                                          Text(
                                            'SUPER ADMIN',
                                            style: TextStyle(color: Color(0xFFD97706), fontSize: 10, fontWeight: FontWeight.w900),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Row(
                                      children: const [
                                        Icon(Icons.shield_outlined, size: 13, color: Color(0xFF10B981)),
                                        SizedBox(width: 4),
                                        Text('Verified Seller & Buyer', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Welcome, Guest Trader',
                                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Sign in to list parts, chat & negotiate',
                                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0075FF),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Text('Sign In / Register →', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),

                  // Interactive Metric Badges
                  if (auth.isAuthenticated) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // My Ads count
                          StreamBuilder<QuerySnapshot>(
                            stream: _db.collection('spareParts').where('sellerId', isEqualTo: user?.uid).snapshots(),
                            builder: (context, snap) {
                              final count = snap.data?.docs.length ?? 0;
                              return _buildMetricItem(
                                label: 'My Ads',
                                value: '$count',
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAdsScreen())),
                              );
                            },
                          ),
                          Container(width: 1, height: 26, color: const Color(0xFFCBD5E1)),

                          // Wishlist count
                          _buildMetricItem(
                            label: 'Saved Parts',
                            value: '${partsProvider.wishlistPartIds.length}',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen())),
                          ),
                          Container(width: 1, height: 26, color: const Color(0xFFCBD5E1)),

                          // Rating
                          _buildMetricItem(
                            label: 'Trust Rating',
                            value: '4.9 ★',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Super Admin Portal Hub (Visible only to Admin emails)
            if (isAdmin) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    const Text('Marketplace Management', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    _buildMenuTile(
                      icon: Icons.admin_panel_settings_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      title: 'Marketplace Console',
                      subtitle: 'Review listings, manage members & reports',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
                    ),
                    const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                    _buildMenuTile(
                      icon: Icons.alt_route_rounded,
                      iconColor: const Color(0xFF0075FF),
                      title: 'Car Brands & Categories',
                      subtitle: 'Manage vehicle catalog, models & categories',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTaxonomyScreen())),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 3. Marketplace Activities
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFF0075FF), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  const Text('Marketplace Activities', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildMenuTile(
                    icon: Icons.inventory_2_outlined,
                    iconColor: const Color(0xFF0075FF),
                    title: 'My Listed Parts (Ads)',
                    subtitle: 'Manage active, sold, and deleted ads',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAdsScreen())),
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                  _buildMenuTile(
                    icon: Icons.favorite_outline_rounded,
                    iconColor: const Color(0xFFEF4444),
                    title: 'Wishlist / Saved Parts',
                    subtitle: 'Spare parts you bookmarked for later',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen())),
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                  _buildMenuTile(
                    icon: Icons.history_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    title: 'Recently Viewed Parts',
                    subtitle: 'History of parts you browsed recently',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecentlyViewedScreen())),
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                  _buildMenuTile(
                    icon: Icons.notifications_none_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: 'Notifications & Alerts',
                    subtitle: 'Offers, chats and price drop notices',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 4. Preferences & Support
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFF0075FF), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  const Text('Settings & Help Support', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildMenuTile(
                    icon: Icons.language_rounded,
                    iconColor: const Color(0xFF0075FF),
                    title: 'Language / மொழி',
                    subtitle: lang.currentLanguage == 'ta' ? 'தமிழ் (Tamil)' : (lang.currentLanguage == 'hi' ? 'हिन्दी (Hindi)' : 'English'),
                    onTap: () => _showLanguageDialog(context),
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                  if (auth.isAuthenticated) ...[
                    _buildMenuTile(
                      icon: Icons.badge_outlined,
                      iconColor: const Color(0xFF64748B),
                      title: 'Edit Trader Profile',
                      subtitle: 'Update phone number, location, and workshop name',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                    ),
                    const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                  ],
                  _buildMenuTile(
                    icon: Icons.help_outline_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: 'Help & 24/7 Helpline',
                    subtitle: 'Safety rules, buyer protection & customer support',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                  _buildMenuTile(
                    icon: Icons.tune_rounded,
                    iconColor: const Color(0xFF64748B),
                    title: 'App Settings',
                    subtitle: 'Notifications, sounds & storage',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen())),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Sign Out Button (If authenticated)
            if (auth.isAuthenticated)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      foregroundColor: const Color(0xFFEF4444),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Sign Out from Auto Parts India', style: TextStyle(fontWeight: FontWeight.w800)),
                    onPressed: () => _confirmSignOut(context, auth),
                  ),
                ),
              ),

            const SizedBox(height: 16),
            const Text(
              'Auto Parts India • 100% Genuine Marketplace',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem({required String label, required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A))),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }
}
