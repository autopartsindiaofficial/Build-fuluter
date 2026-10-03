import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/auth_provider.dart';
import 'main_nav_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool _loading = false;
  String? _errorMessage;
  bool _isSignUp = false;
  bool _obscurePassword = true;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _onSuccessRedirect() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✨ Welcome to Auto Parts India!'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
    if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainNavScreen(),
          transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final auth = Provider.of<AppAuthProvider>(context, listen: false);
      await auth.signInWithGoogle();
      _onSuccessRedirect();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to sign in with Google. Please check your network connection and try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleEmailSubmit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password.');
      return;
    }
    if (_isSignUp && password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final auth = Provider.of<AppAuthProvider>(context, listen: false);
      if (_isSignUp) {
        await auth.signUpWithEmail(email, password, name.isNotEmpty ? name : null);
      } else {
        await auth.signInWithEmail(email, password);
      }
      _onSuccessRedirect();
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceFirst('Exception: ', '').trim();
        final lower = msg.toLowerCase();
        if (lower.contains('user-not-found') || lower.contains('wrong-password') || lower.contains('invalid-credential')) {
          msg = 'Invalid email or password. Please verify and try again.';
        } else if (lower.contains('email-already-in-use')) {
          msg = 'An account with this email already exists.';
        } else if (lower.contains('weak-password')) {
          msg = 'Password is too short. Please enter at least 6 characters.';
        } else if (lower.contains('network') || lower.contains('connection')) {
          msg = 'Unable to connect. Please check your internet connection.';
        } else if (lower.contains('too-many-requests')) {
          msg = 'Too many attempts. Please try again in a moment.';
        }
        setState(() {
          _errorMessage = msg;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final resetCtrl = TextEditingController(text: _emailCtrl.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your registered email address and we will send you a password reset link.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: resetCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006DFD),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final em = resetCtrl.text.trim();
              if (em.isNotEmpty) {
                try {
                  final auth = Provider.of<AppAuthProvider>(context, listen: false);
                  await auth.sendPasswordReset(em);
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset link sent to your email.'),
                        backgroundColor: Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (err) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed: $err'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleGLogo() {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleGLogoPainter()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        top: false,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              // 1. TOP HERO ARTWORK FROM REFERENCE IMAGE
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: const Color(0xFF0F172A),
                    child: Image.asset(
                      'assets/images/signin_hero.png',
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      errorBuilder: (_, __, ___) {
                        // Fallback to reference asset
                        return Image.asset(
                          'assets/images/splash_reference.png',
                          width: double.infinity,
                          height: 240,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),

                  // Optional Back Button
                  if (canGoBack)
                    Positioned(
                      top: 40,
                      left: 16,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                ],
              ),

              // 2. BOTTOM WHITE SHEET SIGN-IN CARD MATCHING REFERENCE IMAGE
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Typography matching reference image
                        Text(
                          _isSignUp ? 'Create Account on' : 'Welcome to',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const Text(
                          'Auto Parts India',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Buy and sell new & used auto spare parts',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Error Banner
                        if (_errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // A. Google Sign-In Button matching reference image
                        InkWell(
                          onTap: _loading ? null : _handleGoogleSignIn,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                _buildGoogleGLogo(),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Continue with Google',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 22),
                              ],
                            ),
                          ),
                        ),

                        // B. OR Divider matching reference image
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: const [
                              Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'OR',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                                ),
                              ),
                              Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                            ],
                          ),
                        ),

                        // C. Form Fields
                        if (_isSignUp) ...[
                          TextField(
                            controller: _nameCtrl,
                            decoration: InputDecoration(
                              hintText: 'Full Name',
                              prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF006DFD), width: 1.5)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Email address',
                            prefixIcon: const Icon(Icons.mail_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF006DFD), width: 1.5)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 10),

                        TextField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF94A3B8), size: 20),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF006DFD), width: 1.5)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),

                        // Forgot password link
                        if (!_isSignUp)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 6, bottom: 8),
                              child: InkWell(
                                onTap: _showForgotPasswordDialog,
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF006DFD),
                                  ),
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 12),

                        // D. Primary Blue Button matching reference image
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF006DFD), // Exact royal blue from reference
                              foregroundColor: Colors.white,
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                            ),
                            onPressed: _loading ? null : _handleEmailSubmit,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _isSignUp ? 'Create Account' : 'Sign In',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                _loading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Icon(Icons.chevron_right_rounded, size: 22),
                              ],
                            ),
                          ),
                        ),

                        // Toggle between Sign In & Sign Up
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: InkWell(
                              onTap: () => setState(() {
                                _isSignUp = !_isSignUp;
                                _errorMessage = null;
                              }),
                              child: Text(
                                _isSignUp ? 'Already have an account? Sign In' : 'Don\'t have an account? Sign Up',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF006DFD),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // E. Legal Footer matching reference image
                        const SizedBox(height: 24),
                        const Center(
                          child: Text(
                            'By signing in, you agree to our\nTerms of Service and Privacy Policy',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF94A3B8),
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
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

// Google 4-Color 'G' Icon Painter
class _GoogleGLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Paint paint = Paint()..style = PaintingStyle.fill;

    // Blue
    paint.color = const Color(0xFF4285F4);
    final Path bluePath = Path()
      ..moveTo(w * 0.94, h * 0.51)
      ..lineTo(w * 0.5, h * 0.51)
      ..lineTo(w * 0.5, h * 0.69)
      ..lineTo(w * 0.75, h * 0.69)
      ..cubicTo(w * 0.72, h * 0.77, w * 0.62, h * 0.85, w * 0.5, h * 0.85)
      ..lineTo(w * 0.5, h * 1.0)
      ..cubicTo(w * 0.75, h * 1.0, w * 0.95, h * 0.82, w * 0.94, h * 0.51)
      ..close();
    canvas.drawPath(bluePath, paint);

    // Green
    paint.color = const Color(0xFF34A853);
    final Path greenPath = Path()
      ..moveTo(w * 0.5, h * 1.0)
      ..cubicTo(w * 0.35, h * 1.0, w * 0.22, h * 0.9, w * 0.16, h * 0.77)
      ..lineTo(w * 0.31, h * 0.65)
      ..cubicTo(w * 0.35, h * 0.73, w * 0.42, h * 0.78, w * 0.5, h * 0.78)
      ..lineTo(w * 0.5, h * 1.0)
      ..close();
    canvas.drawPath(greenPath, paint);

    // Yellow
    paint.color = const Color(0xFFFBBC05);
    final Path yellowPath = Path()
      ..moveTo(w * 0.16, h * 0.77)
      ..cubicTo(w * 0.12, h * 0.69, w * 0.1, h * 0.6, w * 0.1, h * 0.5)
      ..cubicTo(w * 0.1, h * 0.4, w * 0.12, h * 0.31, w * 0.16, h * 0.23)
      ..lineTo(w * 0.31, h * 0.35)
      ..cubicTo(w * 0.29, h * 0.4, w * 0.27, h * 0.45, w * 0.27, h * 0.5)
      ..cubicTo(w * 0.27, h * 0.55, w * 0.29, h * 0.6, w * 0.31, h * 0.65)
      ..close();
    canvas.drawPath(yellowPath, paint);

    // Red
    paint.color = const Color(0xFFEA4335);
    final Path redPath = Path()
      ..moveTo(w * 0.16, h * 0.23)
      ..cubicTo(w * 0.22, h * 0.1, w * 0.35, h * 0.0, w * 0.5, h * 0.0)
      ..cubicTo(w * 0.65, h * 0.0, w * 0.75, h * 0.06, w * 0.81, h * 0.13)
      ..lineTo(w * 0.68, h * 0.26)
      ..cubicTo(w * 0.63, h * 0.21, w * 0.57, h * 0.18, w * 0.5, h * 0.18)
      ..cubicTo(w * 0.42, h * 0.18, w * 0.35, h * 0.23, w * 0.31, h * 0.31)
      ..close();
    canvas.drawPath(redPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
