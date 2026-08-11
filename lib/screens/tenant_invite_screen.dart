import 'package:flutter/material.dart';

import '../models/tenant.dart';
import '../theme/app_theme.dart';
import '../widgets/tenant_invite_content.dart';

/// Standalone screen wrapping [TenantInviteContent] — used from a tenant's
/// rent detail page ("Share invite") for anyone who hasn't joined yet. The
/// Add Tenant flow itself shows the same content inline as its "Invite" tab
/// instead of pushing this screen.
class TenantInviteScreen extends StatelessWidget {
  final Tenant tenant;
  final String? propertyTitle;

  const TenantInviteScreen({super.key, required this.tenant, this.propertyTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Invite Tenant'),
            if (propertyTitle != null)
              Text(propertyTitle!, style: const TextStyle(fontSize: 12.5, color: AppColors.muted, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      body: SafeArea(child: TenantInviteContent(tenant: tenant, propertyTitle: propertyTitle)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
          ),
        ),
      ),
    );
  }
}
