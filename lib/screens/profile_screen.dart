import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firebase_auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import '../widgets/pill_badge.dart';
import 'login_screen.dart';
import 'my_bookings_screen.dart';
import 'role_selection_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AuthUser? _user;
  bool _loading = true;
  bool _loggingOut = false;

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
        _user = user;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _handleChangeRole() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoleSelectionScreen(initialRole: _user?.role),
      ),
    );
  }

  Future<void> _handleLogout() async {
    setState(() => _loggingOut = true);
    await FirebaseAuthService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String _roleLabel(UserRole? role, ServiceType? serviceType) {
    final base = switch (role) {
      UserRole.apartmentAssociation => 'Apartment Association',
      UserRole.pgOwner => 'PG Owner',
      UserRole.propertyOwner => 'Property Owner',
      UserRole.tenant => 'Tenant',
      UserRole.serviceProvider => 'Service Provider',
      null => 'Not set',
    };
    if (role == UserRole.serviceProvider && serviceType != null) {
      final specialty = serviceType == ServiceType.plumber ? 'Plumbing' : 'Electrician';
      return '$base · $specialty';
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final name = _user?.name ?? firebaseUser?.displayName;
    final email = _user?.email ?? firebaseUser?.email;
    final photoURL = _user?.photoURL ?? firebaseUser?.photoURL;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.surfaceAlt,
                      backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                      child: photoURL == null
                          ? const Icon(Icons.person, size: 44, color: AppColors.muted)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    (name == null || name.isEmpty) ? 'GateHub360 User' : name,
                    textAlign: TextAlign.center,
                    style: AppFonts.heading(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  if (email != null) ...[
                    const SizedBox(height: 4),
                    Text(email, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, color: AppColors.muted)),
                  ],
                  const SizedBox(height: 12),
                  Center(child: PillBadge(label: _roleLabel(_user?.role, _user?.serviceType), color: AppColors.brand)),
                  const SizedBox(height: 28),
                  DarkCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _InfoRow(icon: Icons.badge_outlined, label: 'Name', value: name ?? '—'),
                        const Divider(height: 1),
                        _InfoRow(icon: Icons.email_outlined, label: 'Email', value: email ?? '—'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (_user?.role != UserRole.serviceProvider) ...[
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
                      ),
                      icon: const Icon(Icons.receipt_long_outlined, color: AppColors.brand),
                      label: const Text('My Bookings', style: TextStyle(color: AppColors.brand)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.brand)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton.icon(
                    onPressed: _handleChangeRole,
                    icon: const Icon(Icons.swap_horiz, color: AppColors.brand),
                    label: const Text('Change Role', style: TextStyle(color: AppColors.brand)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.brand)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _loggingOut ? null : _handleLogout,
                    icon: _loggingOut
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : const Icon(Icons.logout, color: AppColors.danger),
                    label: Text(_loggingOut ? 'Logging out…' : 'Log Out', style: const TextStyle(color: AppColors.danger)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
                  ),
                ],
              ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.muted),
          const SizedBox(width: 14),
          Text(label, style: const TextStyle(fontSize: 13.5, color: AppColors.muted)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
