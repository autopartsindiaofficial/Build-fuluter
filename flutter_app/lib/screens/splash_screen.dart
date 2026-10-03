import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
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

    // Match Android Status & Navigation Bars to Dark Slate #25242E Splash
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF25242E),
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();

    // Fast, seamless initialization
    _initialTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) _checkAppUpdate();
    });
  }

  @override
  void dispose() {
    _initialTimer?.cancel();
    _fallbackTimer?.cancel();
    _animController.dispose();
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
          transitionDuration: const Duration(milliseconds: 350),
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
    _fallbackTimer = Timer(const Duration(milliseconds: 1800), () {
      _safeProceed();
    });

    try {
      final doc = await _db
          .collection('app_version')
          .doc('config')
          .get()
          .timeout(const Duration(milliseconds: 1500));

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
      debugPrint('[Splash] Update check completed or skipped: $e');
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
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.system_update_rounded, color: Color(0xFF0075FF), size: 26),
              SizedBox(width: 10),
              Text('Update Required', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF0F172A))),
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
      backgroundColor: const Color(0xFF25242E), // Exact background color matching reference image
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: Color(0xFF25242E),
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              // Exact Reference Image Splash Screen
              FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: Image.asset(
                    'assets/images/splash_reference.png',
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      // Graceful fallback to root assets path if nested path fails
                      return Image.asset(
                        'assets/splash_reference.png',
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) {
                          // Beautiful vector fallback with identical styling
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF7300),
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF7300).withOpacity(0.35),
                                      blurRadius: 32,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.directions_car_filled_rounded,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'Auto ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  Text(
                                    'Parts',
                                    style: TextStyle(
                                      color: Color(0xFFFF7300),
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '—  I N D I A  —',
                                style: TextStyle(
                                  color: Color(0xFFE5E7EB),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 4.0,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              // Subtle bottom loading spinner matching brand orange
              Positioned(
                bottom: 36,
                child: SafeArea(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF7300),
                        strokeWidth: 2.2,
                      ),
                    ),
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
