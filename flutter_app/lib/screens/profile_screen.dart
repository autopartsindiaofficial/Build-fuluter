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
        title: const Text('Select Language / மொழி'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              trailing: lang.currentLanguage == 'en' ? const Icon(Icons.check, color: Color(0xFF0075FF)) : null,
              onTap: () {
                lang.setLanguage('en');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('தமிழ் (Tamil)'),
              trailing: lang.currentLanguage == 'ta' ? const Icon(Icons.check, color: Color(0xFF0075FF)) : null,
              onTap: () {
                lang.setLanguage('ta');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('हिन्दी (Hindi)'),
              trailing: lang.currentLanguage == 'hi' ? const Icon(Icons.check, color: Color(0xFF0075FF)) : null,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out from Auto Parts India?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await auth.signOut();
            },
            child: const Text('Sign Out'),
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
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. User Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFF0075FF).withOpacity(0.12),
                        backgroundImage: (user?.photoURL != null && user!.photoURL!.isNotEmpty)
                            ? CachedNetworkImageProvider(user.photoURL!) as ImageProvider
                            : null,
                        child: (user?.photoURL == null || user!.photoURL!.isEmpty)
                            ? const Icon(Icons.person, size: 38, color: Color(0xFF0075FF))
                            : null,
                      ),
                      const SizedBox(width: 16),
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
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.verified, size: 16, color: Color(0xFF0075FF)),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    user?.email ?? '',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isAdmin ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      isAdmin ? '⭐ PLATFORM ADMIN' : 'VERIFIED TRADER',
                                      style: TextStyle(
                                        color: isAdmin ? const Color(0xFFB45309) : const Color(0xFF16A34A),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Welcome, Guest', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  const Text('Sign in to list parts and chat with sellers', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0075FF),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Sign In with Google', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),

                  // 2. Interactive Metrics Row (Matching React Native ProfileScreen)
                  if (auth.isAuthenticated) ...[
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 14),
                    StreamBuilder<QuerySnapshot>(
                      stream: _db.collection('spareParts').where('sellerId', isEqualTo: user!.uid).snapshots(),
                      builder: (context, snap) {
                        final adsCount = snap.data?.docs.where((d) => (d.data() as Map<String, dynamic>)['status'] != 'deleted').length ?? 0;
                        final savedCount = partsProvider.favoritesCount;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('My Ads', '$adsCount', () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAdsScreen()));
                            }),
                            _buildStatDivider(),
                            _buildStatItem('Followers', '12', () {}),
                            _buildStatDivider(),
                            _buildStatItem('Following', '4', () {}),
                            _buildStatDivider(),
                            _buildStatItem('Saved', '$savedCount', () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen()));
                            }),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 3. Settings & Actions Menu
            _buildSettingSection([
              if (auth.isAuthenticated)
                _buildSettingTile(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  subtitle: 'Update name, mobile, location & bio',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                  },
                ),
              _buildSettingTile(
                icon: Icons.list_alt,
                title: lang.t('myAds'),
                subtitle: 'Manage active & sold spare parts',
                onTap: () {
                  if (auth.isAuthenticated) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAdsScreen()));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                  }
                },
              ),
              _buildSettingTile(
                icon: Icons.favorite_border,
                title: lang.t('wishlist'),
                subtitle: 'Your bookmarked automobile parts',
                onTap: () {
                  if (auth.isAuthenticated) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen()));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                  }
                },
              ),
              _buildSettingTile(
                icon: Icons.history,
                title: 'Recently Viewed',
                subtitle: 'Spares you recently browsed',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RecentlyViewedScreen()));
                },
              ),
              _buildSettingTile(
                icon: Icons.language,
                title: lang.t('language'),
                subtitle: lang.currentLanguage == 'ta' ? 'தமிழ் (Tamil)' : (lang.currentLanguage == 'hi' ? 'हिन्दी (Hindi)' : 'English'),
                onTap: () => _showLanguageDialog(context),
              ),
              _buildSettingTile(
                icon: Icons.notifications_none,
                title: 'Notifications',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                },
              ),
              _buildSettingTile(
                icon: Icons.settings_outlined,
                title: 'App Settings',
                subtitle: 'Notifications, sound & cache',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                },
              ),
            ]),

            const SizedBox(height: 12),

            // 4. Admin Panel Section (Visible if Admin or for development)
            if (isAdmin)
              _buildSettingSection([
                _buildSettingTile(
                  icon: Icons.admin_panel_settings_outlined,
                  iconColor: const Color(0xFF0075FF),
                  title: 'Admin Dashboard & Moderation',
                  subtitle: 'Platform analytics, listings moderation',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
                  },
                ),
                _buildSettingTile(
                  icon: Icons.auto_awesome_mosaic_outlined,
                  iconColor: const Color(0xFF0075FF),
                  title: 'Categories & Brands CMS',
                  subtitle: 'Manage live car brands & spare parts categories',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTaxonomyScreen()));
                  },
                ),
              ]),

            if (isAdmin) const SizedBox(height: 12),

            // 5. Support & Legal
            _buildSettingSection([
              _buildSettingTile(
                icon: Icons.help_outline,
                title: 'Help & Support (24x7)',
                subtitle: 'Direct call, email & marketplace FAQs',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
                },
              ),
            ]),

            const SizedBox(height: 12),

            // 6. Sign Out Button
            if (auth.isAuthenticated)
              _buildSettingSection([
                _buildSettingTile(
                  icon: Icons.logout,
                  title: 'Log Out',
                  iconColor: Colors.red,
                  textColor: Colors.red,
                  onTap: () => _confirmSignOut(context, auth),
                ),
              ]),

            const SizedBox(height: 24),
            const Text(
              'Auto Parts India v1.0.0 • Verified Marketplace',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String count, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 24,
      width: 1,
      color: const Color(0xFFE2E8F0),
    );
  }

  Widget _buildSettingSection(List<Widget> children) {
    return Container(
      color: Colors.white,
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? const Color(0xFF475569)),
      title: Text(title, style: TextStyle(color: textColor ?? const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))) : null,
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
      onTap: onTap,
    );
  }
}
