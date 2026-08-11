import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/tenant.dart';
import '../theme/app_theme.dart';
import 'dark_card.dart';

/// The join-code / QR / SMS / WhatsApp share block for a tenant — the join
/// code as text, as a scannable QR, and one-tap buttons to text it.
/// Reused both as [TenantInviteScreen]'s body and as the "Invite" tab
/// inside AddTenantScreen once a tenant has actually been created.
///
/// The QR just encodes the join code itself (not a deep link) — this app
/// has no QR *scanner* or app-link handler yet, so a generic phone camera
/// reading the code and letting the tenant paste it into "Join with code"
/// is the honest, fully-working version of this feature today.
class TenantInviteContent extends StatefulWidget {
  final Tenant tenant;
  final String? propertyTitle;

  const TenantInviteContent({super.key, required this.tenant, this.propertyTitle});

  @override
  State<TenantInviteContent> createState() => _TenantInviteContentState();
}

class _TenantInviteContentState extends State<TenantInviteContent> {
  late final TextEditingController _phoneController = TextEditingController(text: widget.tenant.phone);
  bool _sending = false;

  @override
  void didUpdateWidget(covariant TenantInviteContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tenant.id != widget.tenant.id) _phoneController.text = widget.tenant.phone;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String get _code => widget.tenant.joinCode ?? '';

  String get _message =>
      "Hi ${widget.tenant.name}, you've been added as a tenant"
      '${widget.propertyTitle != null ? ' at ${widget.propertyTitle}' : ''} on GateHub360. '
      'Download the GateHub360 app and enter this code to link your account and see/pay your rent: $_code';

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _code));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied')));
  }

  // wa.me needs a country code. Tenant numbers in this app are otherwise
  // untouched free text - a bare 10-digit Indian mobile number is the
  // common case, so it gets the +91 prefix; anything else (already has a
  // country code, has a leading 0, etc.) is passed through as-is.
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text('${widget.tenant.name} added', style: AppFonts.heading(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text(
          "Share this code so they can link their account and start seeing/paying their rent.",
          style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
        ),
        const SizedBox(height: 18),
        DarkCard(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _code.isEmpty ? '——————' : _code,
                style: AppFonts.heading(fontSize: 28, fontWeight: FontWeight.w800).copyWith(letterSpacing: 4),
              ),
              if (_code.isNotEmpty) ...[
                const SizedBox(width: 10),
                InkWell(onTap: _copyCode, child: const Icon(Icons.copy_outlined, size: 20, color: AppColors.muted)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_code.isNotEmpty) ...[
          const Center(child: Text('Scan to get the code', style: TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600))),
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: QrImageView(data: _code, size: 200, backgroundColor: Colors.white),
            ),
          ),
          const SizedBox(height: 28),
        ],
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
