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
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const AuthScreen(),
                    transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
                  ),
                  (route) => false,
                );
              }
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
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF0F172A), size: 22),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Compact User Header & Profile Avatar Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
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
                            radius: 28,
                          ),
                          if (isAdmin)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF59E0B),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.star_rounded, size: 12, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
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
                                          user?.displayName ?? 'Auto Trader',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.verified_rounded, size: 15, color: Color(0xFF0075FF)),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user?.email ?? '',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  if (isAdmin)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
                                      ),
                                      child: const Text(
                                        'SUPER ADMIN',
                                        style: TextStyle(color: Color(0xFFD97706), fontSize: 9.5, fontWeight: FontWeight.w900),
                                      ),
                                    )
                                  else
                                    const Text('Verified Auto Trader', style: TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.w700)),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Welcome, Guest Trader',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen())),
                                    child: const Text('Sign In / Register →', style: TextStyle(color: Color(0xFF0075FF), fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                      ),
                      // Edit Profile Button
                      if (auth.isAuthenticated)
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            foregroundColor: const Color(0xFF0075FF),
                            padding: const EdgeInsets.all(8),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Edit Profile',
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                        ),
                    ],
                  ),

                  // Compact Metric Badges (Single sleek row)
                  if (auth.isAuthenticated) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
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
                          Container(width: 1, height: 20, color: const Color(0xFFCBD5E1)),

                          // Wishlist count
                          _buildMetricItem(
                            label: 'Saved Parts',
                            value: '${partsProvider.wishlistPartIds.length}',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen())),
                          ),
                          Container(width: 1, height: 20, color: const Color(0xFFCBD5E1)),

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
            const SizedBox(height: 10),

            // 2. Super Admin Portal Strip (Visible only to Admin emails)
            if (isAdmin) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFFFEF3C7), const Color(0xFFFFFBEB)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
                        child: Row(
                          children: const [
                            Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFD97706), size: 18),
                            SizedBox(width: 6),
                            Text('Marketplace Console', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF92400E))),
                          ],
                        ),
                      ),
                    ),
                    Container(width: 1, height: 20, color: const Color(0xFFFCD34D)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTaxonomyScreen())),
                        child: Row(
                          children: const [
                            Icon(Icons.alt_route_rounded, color: Color(0xFF0075FF), size: 18),
                            SizedBox(width: 6),
                            Text('Brands & Catalog', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0052B4))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // 3. Compact 4-Grid Quick Actions
            Row(
              children: [
                _buildQuickActionTile(
                  icon: Icons.inventory_2_outlined,
                  iconColor: const Color(0xFF0075FF),
                  bgColor: const Color(0xFFEFF6FF),
                  title: 'My Ads',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAdsScreen())),
                ),
                const SizedBox(width: 8),
                _buildQuickActionTile(
                  icon: Icons.favorite_outline_rounded,
                  iconColor: const Color(0xFFEF4444),
                  bgColor: const Color(0xFFFEF2F2),
                  title: 'Saved',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen())),
                ),
                const SizedBox(width: 8),
                _buildQuickActionTile(
                  icon: Icons.history_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  bgColor: const Color(0xFFF5F3FF),
                  title: 'Recent',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecentlyViewedScreen())),
                ),
                const SizedBox(width: 8),
                _buildQuickActionTile(
                  icon: Icons.notifications_none_rounded,
                  iconColor: const Color(0xFF10B981),
                  bgColor: const Color(0xFFECFDF5),
                  title: 'Alerts',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 4. Compact Settings & Help Menu Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildCompactTile(
                    icon: Icons.language_rounded,
                    iconColor: const Color(0xFF0075FF),
                    title: 'Language / மொழி',
                    trailingText: lang.currentLanguage == 'ta' ? 'தமிழ்' : (lang.currentLanguage == 'hi' ? 'हिन्दी' : 'English'),
                    onTap: () => _showLanguageDialog(context),
                  ),
                  const Divider(height: 1, indent: 44, color: Color(0xFFF1F5F9)),
                  _buildCompactTile(
                    icon: Icons.help_outline_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: 'Help & Customer Support',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen())),
                  ),
                  const Divider(height: 1, indent: 44, color: Color(0xFFF1F5F9)),
                  _buildCompactTile(
                    icon: Icons.settings_outlined,
                    iconColor: const Color(0xFF64748B),
                    title: 'App Preferences & Settings',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen())),
                  ),
                  if (auth.isAuthenticated) ...[
                    const Divider(height: 1, indent: 44, color: Color(0xFFF1F5F9)),
                    _buildCompactTile(
                      icon: Icons.logout_rounded,
                      iconColor: const Color(0xFFEF4444),
                      title: 'Sign Out',
                      titleColor: const Color(0xFFEF4444),
                      onTap: () => _confirmSignOut(context, auth),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Footer
            const Center(
              child: Text(
                'Auto Parts India • 100% Genuine Marketplace',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11.5, color: Color(0xFF0F172A)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    Color? titleColor,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: titleColor ?? const Color(0xFF0F172A),
                ),
              ),
            ),
            if (trailingText != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trailingText,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0075FF)),
                ),
              ),
              const SizedBox(width: 4),
            ],
            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem({required String label, required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}
