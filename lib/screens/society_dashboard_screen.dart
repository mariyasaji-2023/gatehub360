import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/society.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import '../widgets/gradient_banner.dart';
import 'society_billing_screen.dart';
import 'society_complaints_screen.dart';
import 'society_directory_screen.dart';
import 'society_flats_screen.dart';
import 'society_join_requests_screen.dart';
import 'society_notices_screen.dart';

/// Pushed route used when an Apartment Association enters a society from the
/// "My Societies" tile grid.
class SocietyDashboardScreen extends StatelessWidget {
  final Society society;
  const SocietyDashboardScreen({super.key, required this.society});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(society.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SocietyDashboardBody(society: society, isAssociation: true),
          ],
        ),
      ),
    );
  }
}

/// The society info card + Notices/Complaints/Directory/Billing grid, shared
/// by the association's pushed dashboard and the resident's inline Society tab.
class SocietyDashboardBody extends StatelessWidget {
  final Society society;
  final bool isAssociation;
  const SocietyDashboardBody({super.key, required this.society, required this.isAssociation});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GradientBanner(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(society.name, style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Text(society.address, style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
              const SizedBox(height: 2),
              Text(
                '${society.area}, ${society.city}, ${society.state} - ${society.pincode}',
                style: const TextStyle(fontSize: 12.5, color: Colors.white70),
              ),
              if (isAssociation) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: Colors.white24),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Invite code', style: TextStyle(fontSize: 11.5, color: Colors.white70)),
                          const SizedBox(height: 4),
                          Text(society.code, style: AppFonts.heading(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: society.code));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite code copied')));
                      },
                      icon: const Icon(Icons.copy, size: 16, color: Colors.white),
                      label: const Text('Copy', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white54), minimumSize: const Size(0, 40)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Manage', style: AppFonts.heading(fontSize: 19, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            _FeatureTile(
              icon: Icons.door_front_door_outlined,
              color: AppColors.success,
              title: 'Flats',
              subtitle: isAssociation ? 'Manage units' : 'View availability',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SocietyFlatsScreen())),
            ),
            if (isAssociation)
              _FeatureTile(
                icon: Icons.person_add_alt_outlined,
                color: AppColors.brand,
                title: 'Join Requests',
                subtitle: 'Approve tenants',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SocietyJoinRequestsScreen())),
              ),
            _FeatureTile(
              icon: Icons.campaign_outlined,
              color: AppColors.amber,
              title: 'Notices',
              subtitle: isAssociation ? 'Post & manage' : 'View updates',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SocietyNoticesScreen())),
            ),
            _FeatureTile(
              icon: Icons.build_outlined,
              color: AppColors.danger,
              title: 'Complaints',
              subtitle: isAssociation ? 'Track & resolve' : 'Raise & track',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SocietyComplaintsScreen())),
            ),
            _FeatureTile(
              icon: Icons.people_outline,
              color: AppColors.brand,
              title: 'Directory',
              subtitle: 'Residents',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SocietyDirectoryScreen())),
            ),
            _FeatureTile(
              icon: Icons.account_balance_wallet_outlined,
              color: AppColors.brandLight,
              title: 'Billing',
              subtitle: isAssociation ? 'Generate & track' : 'Pay maintenance',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SocietyBillingScreen())),
            ),
          ],
        ),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureTile({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DarkCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 26, color: color),
          const SizedBox(height: 12),
          Text(title, style: AppFonts.heading(fontSize: 14.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
        ],
      ),
    );
  }
}
