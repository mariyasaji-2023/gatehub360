import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_config.dart';
import '../theme/app_theme.dart';
import 'dark_card.dart';

/// The property-wide QR/link block — always available (doesn't depend on
/// any tenant having been created). Anyone who scans it lands on the
/// public join-request web form (backend/public/invite.html, no sign-in
/// needed); the owner reviews submissions under Join Requests.
///
/// Lives inline as AddTenantScreen's "Invite" tab; previously its own
/// dashboard quick action, folded in here so there's one place for
/// everything tenant-related instead of two.
class PropertyInviteContent extends StatefulWidget {
  final String propertyId;
  final String propertyTitle;

  const PropertyInviteContent({super.key, required this.propertyId, required this.propertyTitle});

  @override
  State<PropertyInviteContent> createState() => _PropertyInviteContentState();
}

class _PropertyInviteContentState extends State<PropertyInviteContent> {
  late final TextEditingController _phoneController = TextEditingController();
  late final String _link = inviteUrlFor(widget.propertyId);
  bool _sending = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _message =>
      "Hi, you're invited to join ${widget.propertyTitle} on GateHub360. "
      'Fill in your details here to send a joining request to the owner: $_link';

  // wa.me needs a country code. A bare 10-digit Indian mobile number is the
  // common case here, so it gets the +91 prefix; anything else is passed
  // through as-is.
  String _digitsForWhatsApp(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length == 10 ? '91$digits' : digits;
  }

  Future<void> _send(Future<bool> Function(String phone) launch) async {
    final phone = _phoneController.text.trim();
    if (phone.replaceAll(RegExp(r'\D'), '').length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid number first')));
      return;
    }
    setState(() => _sending = true);
    try {
      final launched = await launch(phone);
      if (!mounted) return;
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't open the app to send this")));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<bool> _launchSms(String phone) {
    final uri = Uri(scheme: 'sms', path: phone, queryParameters: {'body': _message});
    return launchUrl(uri);
  }

  Future<bool> _launchWhatsApp(String phone) {
    final uri = Uri.parse('https://wa.me/${_digitsForWhatsApp(phone)}?text=${Uri.encodeComponent(_message)}');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Anyone can scan this or open the link to send a joining request — approve it under Join Requests to add them as a tenant.",
          style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 20),
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: QrImageView(data: _link, size: 200, backgroundColor: Colors.white),
          ),
        ),
        const SizedBox(height: 24),
        Text('Send it directly', style: AppFonts.heading(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Number to invite'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _shareButton(
                icon: Icons.sms_outlined,
                label: 'SMS',
                color: AppColors.brand,
                onTap: _sending ? null : () => _send(_launchSms),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _shareButton(
                icon: Icons.chat_outlined,
                label: 'WhatsApp',
                color: AppColors.success,
                onTap: _sending ? null : () => _send(_launchWhatsApp),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _shareButton({required IconData icon, required String label, required Color color, required VoidCallback? onTap}) {
    return DarkCard(
      padding: const EdgeInsets.symmetric(vertical: 16),
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
