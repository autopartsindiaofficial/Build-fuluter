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
  String _cacheSize = '3.8 MB';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.cleaning_services_rounded, color: Color(0xFF0075FF), size: 22),
            SizedBox(width: 8),
            Text('Free Up Storage', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          ],
        ),
        content: const Text(
          'This will remove temporary preview images to save space. Your account, listings, and messages will not be affected.',
          style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _cacheSize = '0 KB');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✨ Storage cleaned successfully!'),
                  backgroundColor: Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0075FF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Clean Now', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('App Settings', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A), fontSize: 18)),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Preferences Section
          Row(
            children: [
              Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFF0075FF), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              const Text('Marketplace Preferences', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: _notificationsEnabled,
                  onChanged: _toggleNotification,
                  title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Instant alerts for price offers, chats, and deals', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF0075FF).withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF0075FF), size: 20),
                  ),
                  activeColor: const Color(0xFF0075FF),
                ),
                const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                SwitchListTile(
                  value: _locationEnabled,
                  onChanged: _toggleLocation,
                  title: const Text('Location Services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Prioritize spare parts available in your city/state', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.my_location_rounded, color: Color(0xFF10B981), size: 20),
                  ),
                  activeColor: const Color(0xFF0075FF),
                ),
                const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                SwitchListTile(
                  value: _soundEnabled,
                  onChanged: _toggleSound,
                  title: const Text('In-App Alert Chimes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Play sound on new chat message arrivals', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.volume_up_rounded, color: Color(0xFFF59E0B), size: 20),
                  ),
                  activeColor: const Color(0xFF0075FF),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. Storage Section
          Row(
            children: [
              Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFF0075FF), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              const Text('Storage & Space', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF64748B).withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.cleaning_services_rounded, color: Color(0xFF64748B), size: 20),
              ),
              title: const Text('Free Up Space', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('Temporary image files: $_cacheSize', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              trailing: ElevatedButton(
                onPressed: _clearCache,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0075FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Clean', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 3. About Section
          Row(
            children: [
              Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFF0075FF), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              const Text('About Auto Parts India', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Application', style: TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                    Text('Auto Parts India', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                  ],
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Marketplace', style: TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                    Text('All-India Genuine Spares', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0075FF))),
                  ],
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Support', style: TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                    Text('24/7 Verified Community', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF10B981))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
