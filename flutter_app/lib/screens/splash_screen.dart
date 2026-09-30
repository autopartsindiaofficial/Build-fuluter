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

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic);
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );

    // 2. Glowing pulse around logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 3. Footer Tagline Fade Animation
    _footerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _footerFade = CurvedAnimation(parent: _footerController, curve: Curves.easeIn);

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _footerController.forward();
    });

    // 4. Check App Update & Proceed after brief display
    _initialTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) _checkAppUpdate();
    });
  }

  @override
  void dispose() {
    _initialTimer?.cancel();
    _fallbackTimer?.cancel();
    _fadeController.dispose();
    _pulseController.dispose();
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.system_update_rounded, color: Color(0xFF0075FF), size: 26),
              SizedBox(width: 10),
              Text('Update Required', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ],
          ),
          content: const Text(
            'A newer update of Auto Parts India is available with improved marketplace features. Please update to continue.',
            style: TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.45),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            if (!forceUpdate)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _safeProceed();
                },
                child: const Text('Later', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0075FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
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
              child: const Text('Update Now', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0F1D), // Ultra Deep Slate Navy
              Color(0xFF0C1938), // Midnight Blue
              Color(0xFF0052B4), // Electric Automotive Blue Accent
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Center Brand Emblem & Typography
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated Glow Ring Container
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0075FF).withOpacity(0.4),
                                      blurRadius: 36,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.white, Color(0xFFF1F5F9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: Colors.white.withOpacity(0.8), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Center(
                              child: Image.asset(
                                'assets/app_logo.png',
                                width: 84,
                                height: 84,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.directions_car_filled_rounded,
                                  size: 60,
                                  color: Color(0xFF0075FF),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Title with luxury automotive styling
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, Color(0xFFE2E8F0)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ).createShader(bounds),
                          child: const Text(
                            'Auto Parts India',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Tagline
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 14),
                              SizedBox(width: 6),
                              Text(
                                'GENUINE AUTO PARTS MARKETPLACE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // Footer
                FadeTransition(
                  opacity: _footerFade,
                  child: Column(
                    children: [
                      Text(
                        'India’s leading auto parts marketplace',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '100% Genuine Spares Guaranteed',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.6),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
