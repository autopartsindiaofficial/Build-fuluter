import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../providers/language_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _soundEnabled = true;
  String _cacheSize = '2.4 MB';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  void _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('pref_notifications') ?? true;
      _locationEnabled = prefs.getBool('pref_location') ?? true;
      _soundEnabled = prefs.getBool('pref_sound') ?? true;
    });
  }

  void _toggleNotification(bool val) async {
    setState(() => _notificationsEnabled = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_notifications', val);
  }

  void _toggleLocation(bool val) async {
    setState(() => _locationEnabled = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_location', val);
  }

  void _toggleSound(bool val) async {
    setState(() => _soundEnabled = val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_sound', val);
  }

  void _clearCache() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear App Cache?'),
        content: const Text('This will free up local temporary image storage.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _cacheSize = '0 KB');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully!'), backgroundColor: Colors.green),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('App Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
            child: Column(
              children: [
                SwitchListTile(
                  value: _notificationsEnabled,
                  onChanged: _toggleNotification,
                  title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Get alerts for messages and price drops', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _locationEnabled,
                  onChanged: _toggleLocation,
                  title: const Text('Location Services', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Show nearby auto spare parts in your city', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  secondary: const Icon(Icons.my_location, color: AppColors.primary),
                  activeColor: AppColors.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _soundEnabled,
                  onChanged: _toggleSound,
                  title: const Text('In-App Notification Sounds', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Play sound on new chat messages', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  secondary: const Icon(Icons.volume_up_outlined, color: AppColors.primary),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text('Storage & Cache', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
            child: ListTile(
              leading: const Icon(Icons.cleaning_services_outlined, color: AppColors.primary),
              title: const Text('Clear Temporary Cache', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Current cache size: $_cacheSize', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              trailing: TextButton(
                onPressed: _clearCache,
                child: const Text('Clear', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Text('About & Legal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primary),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: AppColors.primary),
                  title: const Text('App Version'),
                  trailing: const Text('1.0.0 (Build 100)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
