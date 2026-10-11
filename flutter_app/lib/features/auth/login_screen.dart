import 'package:flutter/material.dart';

import '../../core/services/firebase_auth_service.dart';
import '../../core/utils/responsive.dart';
import '../shell/admin_shell.dart';
import '../shell/user_shell.dart';
import 'auth_brand_logo.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuthService _authService = FirebaseAuthService();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _isAdmin = false;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter your email address and password.');
      return;
    }

    setState(() => _loading = true);

    final result = await _authService.loginUser(
      email: email,
      password: password,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] != true) {
      _showMessage(
        result['message']?.toString() ??
            'The email address or password you entered is incorrect.',
      );
      return;
    }

    final role = result['role']?.toString() ?? 'user';

    if (_isAdmin && role != 'admin') {
      _showMessage('This account does not have administrator access.');
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => role == 'admin' ? const AdminShell() : const UserShell(),
      ),
    );
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = Responsive.isCompact(context);
    final maxWidth = Responsive.pageMaxWidth(context);

    return Scaffold(
      backgroundColor: const Color(0xFF221E1D),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF302A28), Color(0xFF221E1D)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -40,
              left: -30,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.9,
                  child: _CornerAccent(),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    Responsive.horizontalPadding(context),
                    compact ? 14 : 18,
                    Responsive.horizontalPadding(context),
                    compact ? 14 : 18,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth > 420 ? 420 : maxWidth),
                    child: Column(
                      children: [
                        SizedBox(height: compact ? 12 : 22),
                        AuthBrandLogo(size: compact ? 96 : 112),
                        SizedBox(height: compact ? 14 : 18),
                        Text(
                          'Secure Lens Pro',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 24 : 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: compact ? 20 : 24),
                        Row(
                          children: [
                            Expanded(
                              child: _ModeChip(
                                compact: compact,
                                text: 'User',
                                selected: !_isAdmin,
                                onTap: () => setState(() => _isAdmin = false),
                              ),
                            ),
                            SizedBox(width: compact ? 8 : 10),
                            Expanded(
                              child: _ModeChip(
                                compact: compact,
                                text: 'Admin',
                                selected: _isAdmin,
                                onTap: () => setState(() => _isAdmin = true),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? 16 : 18),
                        _FieldLabel(
                          compact: compact,
                          text: 'Email',
                        ),
                        const SizedBox(height: 8),
                        _GlowField(
                          compact: compact,
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compact ? 14 : 15,
                            ),
                            decoration: InputDecoration(
                              hintText: _isAdmin ? 'Admin email' : 'Email',
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 14 : 16),
                        _FieldLabel(
                          compact: compact,
                          text: 'Password',
                        ),
                        const SizedBox(height: 8),
                        _GlowField(
                          compact: compact,
                          child: TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compact ? 14 : 15,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Password',
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: const Color(0xFFC7B9B2),
                                  size: compact ? 20 : 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 10 : 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: const Color(0xFFFFCEB6),
                                fontSize: compact ? 12.5 : 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: compact ? 8 : 10),
                        _PrimaryGlowButton(
                          compact: compact,
                          text: _loading ? 'Signing in...' : 'Login',
                          onTap: _loading ? null : _login,
                        ),
                        SizedBox(height: compact ? 10 : 12),
                        TextButton(
                          onPressed: _isAdmin
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SignUpScreen(),
                                    ),
                                  );
                                },
                          child: Text(
                            'Sign up',
                            style: TextStyle(
                              color: const Color(0xFFFFCEB6),
                              fontSize: compact ? 14 : 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerAccent extends StatelessWidget {
  const _CornerAccent();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(220, 220),
      painter: _CornerArcPainter(),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.text,
    required this.selected,
    required this.onTap,
    required this.compact,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: compact ? 40 : 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF2A47F) : const Color(0xFF3A3431),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFFFFD7C4)
                : const Color(0xFF695D58),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFFF2A47F).withOpacity(0.22),
                    blurRadius: 14,
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? const Color(0xFF2B2524) : Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: compact ? 13.5 : 14,
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.text,
    required this.compact,
  });

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 14 : 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _GlowField extends StatelessWidget {
  const _GlowField({
    required this.child,
    required this.compact,
  });

  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF4A413E).withOpacity(0.80),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xAAF2A47F), width: 1.15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF2A47F).withOpacity(0.12),
            blurRadius: 14,
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: InputDecorationTheme(
            hintStyle: TextStyle(
              color: const Color(0xFFC7B9B2),
              fontSize: compact ? 13.5 : 14.5,
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: compact ? 14 : 16,
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _PrimaryGlowButton extends StatelessWidget {
  const _PrimaryGlowButton({
    required this.text,
    required this.onTap,
    required this.compact,
  });

  final String text;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: compact ? 52 : 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFFE68F66), Color(0xFFF6B493)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF2A47F).withOpacity(0.28),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: const Color(0xFF2B2524),
            fontSize: compact ? 16 : 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CornerArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0x66F1A17D)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0x99F5BC9C);

    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      3.55,
      1.25,
      false,
      glow,
    );
    canvas.drawArc(
      Rect.fromLTWH(18, 18, size.width - 36, size.height - 36),
      3.7,
      1.0,
      false,
      stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
