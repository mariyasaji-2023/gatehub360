import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'role_selection_screen.dart';
import 'root_shell.dart';

/// Decides the start screen based on the real Firebase session instead of
/// always opening on the login screen, so a killed/restarted app doesn't
/// look like it logged the user out.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data == null) {
          return const LoginScreen();
        }
        return const _RoleRouter();
      },
    );
  }
}

class _RoleRouter extends StatefulWidget {
  const _RoleRouter();

  @override
  State<_RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<_RoleRouter> {
  bool _loading = true;
  UserRole? _role;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = await AuthService.syncCurrentUser();
      if (!mounted) return;
      setState(() {
        _role = user.role;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _role == null ? const RoleSelectionScreen() : const RootShell();
  }
}
