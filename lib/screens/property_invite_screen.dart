import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_config.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import 'property_join_requests_screen.dart';

/// Opened from the property dashboard's "Invite Tenant" quick action — one
/// QR code (and a matching link) for the property itself. Anyone who scans
/// it lands on a public web form (backend/public/invite.html, no sign-in
/// needed) to send a joining request, which the owner reviews under
/// "Join Requests" and approves into a real tenant.
class PropertyInviteScreen extends StatefulWidget {
  final String propertyId;
  final String propertyTitle;

  const PropertyInviteScreen({super.key, required this.propertyId, required this.propertyTitle});

  @override
  State<PropertyInviteScreen> createState() => _PropertyInviteScreenState();
}

class _PropertyInviteScreenState extends State<PropertyInviteScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Tenant'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PropertyJoinRequestsScreen(propertyId: widget.propertyId, propertyTitle: widget.propertyTitle)),
            ),
            icon: const Icon(Icons.playlist_add_check_outlined),
            tooltip: 'Join Requests',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(widget.propertyTitle, style: AppFonts.heading(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text(
              "Share this with a prospective tenant — they scan the code (or open the link) to send a joining request. Approve it under Join Requests to add them as a tenant.",
              style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 24),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: QrImageView(data: _link, size: 220, backgroundColor: Colors.white),
              ),
            ),
            const SizedBox(height: 28),
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
        ),
      ),
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
