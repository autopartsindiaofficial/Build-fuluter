import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import 'auth_screen.dart';
import 'my_ads_screen.dart';
import 'wishlist_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

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
              trailing: lang.currentLanguage == 'en' ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                lang.setLanguage('en');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('தமிழ் (Tamil)'),
              trailing: lang.currentLanguage == 'ta' ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                lang.setLanguage('ta');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('हिन्दी (Hindi)'),
              trailing: lang.currentLanguage == 'hi' ? const Icon(Icons.check, color: AppColors.primary) : null,
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AppAuthProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          lang.t('profile'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // User Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: auth.user?.photoURL != null ? NetworkImage(auth.user!.photoURL!) : null,
                    child: auth.user?.photoURL == null
                        ? const Icon(Icons.person, size: 36, color: AppColors.primary)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: auth.isAuthenticated
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.userProfile?.displayName ?? auth.user?.displayName ?? 'Auto Enthusiast',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                auth.user?.email ?? '',
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Verified Member',
                                  style: TextStyle(color: Colors.blue.shade800, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Welcome Guest', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('Login to manage your parts & chats', style: TextStyle(color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Login / Sign Up', style: TextStyle(fontSize: 12, color: Colors.white)),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Settings List
            _buildSettingSection([
              _buildSettingTile(
                icon: Icons.language,
                title: lang.t('language'),
                subtitle: lang.currentLanguage == 'ta' ? 'தமிழ்' : (lang.currentLanguage == 'hi' ? 'हिन्दी' : 'English'),
                onTap: () => _showLanguageDialog(context),
              ),
              _buildSettingTile(
                icon: Icons.list_alt,
                title: lang.t('myAds'),
                onTap: () {
                  if (auth.isAuthenticated) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAdsScreen()));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                  }
                },
              ),
              _buildSettingTile(
                icon: Icons.notifications_none,
                title: 'Notifications',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                },
              ),
              _buildSettingTile(
                icon: Icons.favorite_border,
                title: lang.t('wishlist'),
                onTap: () {
                  if (auth.isAuthenticated) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistScreen()));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                  }
                },
              ),
              _buildSettingTile(
                icon: Icons.help_outline,
                title: 'Help & Support (24x7)',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Support line: support@autopartsindia.com')),
                  );
                },
              ),
            ]),

            const SizedBox(height: 12),

            if (auth.isAuthenticated)
              _buildSettingSection([
                _buildSettingTile(
                  icon: Icons.logout,
                  title: 'Logout',
                  iconColor: Colors.red,
                  textColor: Colors.red,
                  onTap: () async {
                    await auth.signOut();
                  },
                ),
              ]),

            const SizedBox(height: 20),
            const Text(
              'Auto Parts India v1.0.0 (Flutter Edition)',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
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
      leading: Icon(icon, color: iconColor ?? AppColors.textPrimary),
      title: Text(title, style: TextStyle(color: textColor ?? AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}
