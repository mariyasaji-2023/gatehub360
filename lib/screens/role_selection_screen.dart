import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import 'root_shell.dart';

class _RoleOption {
  final UserRole role;
  final String emoji;
  final String title;
  final String subtitle;
  final bool disabled;

  const _RoleOption({
    required this.role,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.disabled = false,
  });
}

const _roleOptions = [
  _RoleOption(
    role: UserRole.apartmentAssociation,
    emoji: '🏢',
    title: 'Apartment Association',
    subtitle: 'Society Management — visitors, maintenance & complaints',
    // Temporarily on hold — re-enable by removing this flag.
    disabled: true,
  ),
  _RoleOption(
    role: UserRole.propertyOwner,
    emoji: '🏘️',
    title: 'Property Owner',
    subtitle: 'Buy, Rent & Sell Property — list your property',
  ),
  _RoleOption(
    role: UserRole.tenant,
    emoji: '🔑',
    title: 'Tenant',
    subtitle: 'Find a PG, hostel or property to move into',
  ),
  _RoleOption(
    role: UserRole.serviceProvider,
    emoji: '🔧',
    title: 'Service Provider',
    subtitle: 'Offer Home Services — list your own services for customers to book',
  ),
];

class RoleSelectionScreen extends StatefulWidget {
  final UserRole? initialRole;

  const RoleSelectionScreen({super.key, this.initialRole});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  late UserRole? _selectedRole = widget.initialRole;
  bool _saving = false;

  bool get _canContinue => _selectedRole != null;

  Future<void> _handleContinue() async {
    if (!_canContinue || _saving) return;
    setState(() => _saving = true);
    try {
      await AuthService.updateRole(role: _selectedRole!);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RootShell()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save your selection. Check your connection and try again.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('How will you use GateHub360?', style: AppFonts.heading(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text(
                'Choose one to personalize your experience',
                style: TextStyle(fontSize: 14, color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _roleOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final option = _roleOptions[index];
                    final selected = !option.disabled && _selectedRole == option.role;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Opacity(
                          opacity: option.disabled ? 0.45 : 1,
                          child: DarkCard(
                            borderColor: selected ? AppColors.brand : null,
                            onTap: option.disabled ? null : () => setState(() => _selectedRole = option.role),
                            child: Row(
                              children: [
                                Text(option.emoji, style: const TextStyle(fontSize: 28)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            option.title,
                                            style: AppFonts.heading(fontSize: 15, fontWeight: FontWeight.w700),
                                          ),
                                          if (option.disabled) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.muted.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: const Text(
                                                'Coming soon',
                                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.muted),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(option.subtitle, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                                    ],
                                  ),
                                ),
                                Icon(
                                  selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                  color: selected ? AppColors.brand : AppColors.muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _canContinue && !_saving ? _handleContinue : null,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
