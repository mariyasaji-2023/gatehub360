import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import '../services/firebase_auth_service.dart';
import '../theme/app_theme.dart';
import 'otp_screen.dart';
import 'role_selection_screen.dart';
import 'root_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _sendingOtp = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleSendOtp() async {
    final digits = _phoneController.text.trim();
    if (digits.length != 10) {
      _showMessage('Enter a valid 10-digit mobile number');
      return;
    }

    final phoneNumber = '+91$digits';
    setState(() => _sendingOtp = true);
    try {
      await FirebaseAuthService.sendOtp(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId) {
          if (!mounted) return;
          setState(() => _sendingOtp = false);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OtpScreen(phoneNumber: phoneNumber, verificationId: verificationId),
            ),
          );
        },
        onError: (message) {
          if (!mounted) return;
          setState(() => _sendingOtp = false);
          _showMessage(message);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _sendingOtp = false);
      _showMessage('Could not send the code. Check your connection and try again.');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _googleLoading = true);
    try {
      final user = await FirebaseAuthService.signInWithGoogle();
      if (user == null) return; // user cancelled the picker
      AuthUser? syncedUser;
      try {
        syncedUser = await AuthService.syncCurrentUser();
      } catch (_) {
        // Backend sync failure shouldn't block sign-in; the app can retry later.
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => syncedUser?.role == null ? const RoleSelectionScreen() : const RootShell(),
        ),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF4F6FA),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        child: ClipOval(
                          child: Transform.scale(
                            scale: 1.15,
                            child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(children: [
                        TextSpan(text: 'GateHub', style: AppFonts.heading(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.brand)),
                        TextSpan(text: '360', style: AppFonts.heading(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.text)),
                      ]),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Welcome — sign in to continue',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: AppColors.muted),
                    ),
                    const SizedBox(height: 36),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: const InputDecoration(
                        labelText: 'Mobile number',
                        counterText: '',
                        prefixIcon: Icon(Icons.phone_outlined, color: AppColors.muted),
                        prefixText: '+91  ',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _sendingOtp ? null : _handleSendOtp,
                      child: _sendingOtp
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                            )
                          : const Text('Send OTP'),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('OR', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _googleLoading ? null : _handleGoogleSignIn,
                      icon: _googleLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2.2),
                            )
                          : SvgPicture.asset('assets/images/google_logo.svg', height: 18, width: 18),
                      label: const Text('Continue with Google'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surfaceAlt,
                        side: BorderSide(color: AppColors.muted.withValues(alpha: 0.4)),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline, size: 13, color: AppColors.muted.withValues(alpha: 0.7)),
                        const SizedBox(width: 6),
                        Text('Secured & encrypted', style: TextStyle(fontSize: 11.5, color: AppColors.muted.withValues(alpha: 0.7))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
