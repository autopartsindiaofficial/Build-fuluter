import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import 'main_nav_screen.dart';
import 'auth_screen.dart';

const String currentAppVersion = '1.0.0';

bool isVersionLower(String current, String required) {
  List<int> cParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  List<int> rParts = required.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  int maxLen = cParts.length > rParts.length ? cParts.length : rParts.length;
  for (int i = 0; i < maxLen; i++) {
    int c = i < cParts.length ? cParts[i] : 0;
    int r = i < rParts.length ? rParts[i] : 0;
    if (c < r) return true;
    if (c > r) return false;
  }
  return false;
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late AnimationController _footerController;
  late Animation<double> _footerFade;

  Timer? _initialTimer;
  Timer? _fallbackTimer;
  bool _hasProceeded = false;

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
  void initState() {
    super.initState();

    // 1. Center Brand Logo Entrance Animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _scaleAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );

    // 2. Footer Tagline Fade Animation
    _footerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _footerFade = CurvedAnimation(parent: _footerController, curve: Curves.easeIn);

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _footerController.forward();
    });

    // 3. Check App Update & Proceed after brief display
    _initialTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) _checkAppUpdate();
    });
  }

  @override
  void dispose() {
    _initialTimer?.cancel();
    _fallbackTimer?.cancel();
    _fadeController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  void _safeProceed() {
    if (_hasProceeded || !mounted) return;
    _hasProceeded = true;
    _proceedToApp();
  }

  Future<void> _proceedToApp() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final targetScreen = (user != null) ? const MainNavScreen() : const AuthScreen();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => targetScreen,
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } catch (_) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
      }
    }
  }

  Future<void> _checkAppUpdate() async {
    _fallbackTimer = Timer(const Duration(milliseconds: 3500), () {
      _safeProceed();
    });

    try {
      final doc = await _db
          .collection('app_version')
          .doc('config')
          .get()
          .timeout(const Duration(milliseconds: 2800));

      _fallbackTimer?.cancel();

      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        final minVersion = data['minimumSupportedVersion'] ?? '1.0.0';
        final forceUpdate = data['forceUpdate'] == true;
        final apkUrl = data['apkDownloadUrl'] ?? data['playStoreUrl'] ?? '';

        if (isVersionLower(currentAppVersion, minVersion)) {
          _promptUpdate(apkUrl: apkUrl, forceUpdate: forceUpdate);
          return;
        }
      }
    } catch (e) {
      debugPrint('[Splash] Update check failed or timed out: $e');
    }

    _safeProceed();
  }

  void _promptUpdate({required String apkUrl, required bool forceUpdate}) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (ctx) => PopScope(
        canPop: !forceUpdate,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.system_update, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Update Required', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: const Text(
            'A new version of Auto Parts India is available. Please update to continue using the app.',
            style: TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.4),
          ),
          actions: [
            if (!forceUpdate)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _safeProceed();
                },
                child: const Text('Later', style: TextStyle(color: Colors.grey)),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (apkUrl.isNotEmpty) {
                  final uri = Uri.parse(apkUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
                if (!forceUpdate) {
                  Navigator.pop(ctx);
                  _safeProceed();
                }
              },
              child: const Text('Update Now'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0075FF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const Spacer(),

              // Center Brand Emblem & Typography
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.car_repair, size: 52, color: Color(0xFF0075FF)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Auto Parts India',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'GENUINE AUTOMOBILE SPARES',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              FadeTransition(
                opacity: _footerFade,
                child: const Text(
                  'India’s leading marketplace',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
