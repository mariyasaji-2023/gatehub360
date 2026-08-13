import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/rent_payment.dart';
import '../models/tenant.dart';
import '../services/cloudinary_api.dart';
import '../services/property_api.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import '../widgets/pill_badge.dart';
import 'tenant_invite_screen.dart';

/// One tenant's full rent picture, opened from Collect Payment — due months
/// with a "Mark Collected" action (owner recorded cash/UPI/bank transfer
/// themselves), plus paid history including anything the tenant paid online.
class TenantRentDetailScreen extends StatefulWidget {
  final String propertyId;
  final Tenant tenant;

  const TenantRentDetailScreen({super.key, required this.propertyId, required this.tenant});

  @override
  State<TenantRentDetailScreen> createState() => _TenantRentDetailScreenState();
}

class _TenantRentDetailScreenState extends State<TenantRentDetailScreen> {
  TenantRentDetail? _detail;
  TenantRentDetail? _maintenanceDetail;
  bool _loading = true;
  String? _error;
  DueMonth? _collecting;
  DueMonth? _collectingMaintenance;
  bool _savingMaintenanceAmount = false;
  // null = not uploading; 0-1 = in-progress upload fraction.
  double? _kycUploadProgress;
  double? _agreementUploadProgress;
  bool _updatingMoveOut = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        PropertyApi.fetchTenantRent(widget.propertyId, widget.tenant.id),
        PropertyApi.fetchTenantMaintenance(widget.propertyId, widget.tenant.id),
      ]);
      if (!mounted) return;
      setState(() {
        _detail = results[0];
        _maintenanceDetail = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load rent details. Pull to retry.';
        _loading = false;
      });
    }
  }

  Future<void> _collect(DueMonth due) async {
    final method = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => _MethodPickerSheet(due: due),
    );
    if (method == null) return;

    setState(() => _collecting = due);
    try {
      await PropertyApi.collectRentManually(widget.propertyId, widget.tenant.id, month: due.month, year: due.year, method: method);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${due.label} marked collected')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not record payment: $e')));
    } finally {
      if (mounted) setState(() => _collecting = null);
    }
  }

  Future<void> _collectMaintenance(DueMonth due) async {
    final method = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => _MethodPickerSheet(due: due),
    );
    if (method == null) return;

    setState(() => _collectingMaintenance = due);
    try {
      await PropertyApi.collectMaintenanceManually(widget.propertyId, widget.tenant.id, month: due.month, year: due.year, method: method);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${due.label} marked collected')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not record payment: $e')));
    } finally {
      if (mounted) setState(() => _collectingMaintenance = null);
    }
  }

  Future<void> _editMaintenanceAmount() async {
    final controller = TextEditingController(
      text: (_maintenanceDetail?.tenant.maintenanceAmount ?? 0) > 0 ? '${_maintenanceDetail!.tenant.maintenanceAmount}' : '',
    );
    final amount = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Monthly Maintenance'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '₹ Amount', hintText: 'Leave blank for no maintenance charge'),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (amount == null || !mounted) return;

    setState(() => _savingMaintenanceAmount = true);
    try {
      await PropertyApi.updateTenant(
        widget.propertyId,
        widget.tenant.id,
        maintenanceAmount: amount.trim().isEmpty ? 0 : num.tryParse(amount.trim()) ?? 0,
        updateMaintenanceAmount: true,
      );
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update maintenance amount: $e')));
    } finally {
      if (mounted) setState(() => _savingMaintenanceAmount = false);
    }
  }

  // KYC and the rental agreement are handled identically - just a photo or
  // PDF uploaded straight to Cloudinary, with the resulting URL saved on
  // the tenant. `isKyc` picks which field it lands in and which progress
  // indicator to drive.
  Future<void> _pickAndUploadDocument({required bool isKyc}) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf']);
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() => isKyc ? _kycUploadProgress = 0 : _agreementUploadProgress = 0);
    try {
      final url = await CloudinaryApi.uploadFile(
        File(path),
        onProgress: (p) {
          if (!mounted) return;
          setState(() => isKyc ? _kycUploadProgress = p : _agreementUploadProgress = p);
        },
      );
      await PropertyApi.updateTenant(
        widget.propertyId,
        widget.tenant.id,
        kycDocumentUrl: isKyc ? url : null,
        updateKycDocumentUrl: isKyc,
        rentalAgreementUrl: isKyc ? null : url,
        updateRentalAgreementUrl: !isKyc,
      );
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not upload: $e')));
    } finally {
      if (mounted) setState(() => isKyc ? _kycUploadProgress = null : _agreementUploadProgress = null);
    }
  }

  Future<void> _viewDocument(String url) async {
    final launched = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open document')));
    }
  }

  Future<void> _markMovedOut() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: widget.tenant.moveInDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;

    setState(() => _updatingMoveOut = true);
    try {
      await PropertyApi.updateTenant(
        widget.propertyId,
        widget.tenant.id,
        status: 'moved_out',
        moveOutDate: picked,
        updateMoveOutDate: true,
      );
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as moved out')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update: $e')));
    } finally {
      if (mounted) setState(() => _updatingMoveOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.tenant.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(onRefresh: _load, child: _buildBody(_detail!, _maintenanceDetail!)),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(TenantRentDetail detail, TenantRentDetail maintenance) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('₹${detail.tenant.monthlyRent}/month', style: AppFonts.heading(fontSize: 17, fontWeight: FontWeight.w800)),
                  ),
                  PillBadge(
                    label: detail.tenant.status == 'active' ? 'Active' : detail.tenant.status[0].toUpperCase() + detail.tenant.status.substring(1),
                    color: detail.tenant.status == 'active' ? AppColors.success : AppColors.muted,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if ((detail.tenant.roomNumber ?? '').isEmpty)
                _detailRow(Icons.call_outlined, detail.tenant.phone)
              else ...[
                _detailRow(Icons.door_front_door_outlined, 'Room ${detail.tenant.roomNumber}'),
                const SizedBox(height: 6),
                _detailRow(Icons.call_outlined, detail.tenant.phone),
              ],
              if ((detail.tenant.email ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                _detailRow(Icons.mail_outline, detail.tenant.email!),
              ],
              if (detail.tenant.securityDeposit != null) ...[
                const SizedBox(height: 6),
                _detailRow(Icons.savings_outlined, 'Advance ₹${detail.tenant.securityDeposit}'),
              ],
              const SizedBox(height: 6),
              _detailRow(Icons.event_outlined, 'Joined ${_formatDate(detail.tenant.moveInDate)}'),
              if (detail.tenant.moveOutDate != null) ...[
                const SizedBox(height: 6),
                _detailRow(Icons.event_busy_outlined, 'Moved out ${_formatDate(detail.tenant.moveOutDate!)}'),
              ],
              if (detail.tenant.status == 'active') ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _updatingMoveOut ? null : _markMovedOut,
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.border)),
                    icon: _updatingMoveOut
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.event_busy_outlined, size: 16),
                    label: const Text('Mark as Moved Out', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        DarkCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Documents', style: AppFonts.heading(fontSize: 14.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _DocumentRow(
                label: 'KYC Document',
                url: detail.tenant.kycDocumentUrl,
                uploadProgress: _kycUploadProgress,
                onUpload: () => _pickAndUploadDocument(isKyc: true),
                onView: _viewDocument,
              ),
              const SizedBox(height: 10),
              _DocumentRow(
                label: 'Rental Agreement',
                url: detail.tenant.rentalAgreementUrl,
                uploadProgress: _agreementUploadProgress,
                onUpload: () => _pickAndUploadDocument(isKyc: false),
                onView: _viewDocument,
              ),
            ],
          ),
        ),
        if (detail.tenant.isLinked == false) ...[
          const SizedBox(height: 14),
          DarkCard(
            borderColor: AppColors.amber,
            child: Row(
              children: [
                const Icon(Icons.key_outlined, color: AppColors.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Hasn't joined yet — share this code", style: TextStyle(fontSize: 12, color: AppColors.muted)),
                      const SizedBox(height: 3),
                      Text(
                        detail.tenant.joinCode ?? '——————',
                        style: AppFonts.heading(fontSize: 20, fontWeight: FontWeight.w800).copyWith(letterSpacing: 3),
                      ),
                    ],
                  ),
                ),
                if (detail.tenant.joinCode != null) ...[
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: detail.tenant.joinCode!));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied')));
                    },
                    icon: const Icon(Icons.copy_outlined, size: 18, color: AppColors.muted),
                    tooltip: 'Copy code',
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => TenantInviteScreen(tenant: detail.tenant)),
                    ),
                    icon: const Icon(Icons.qr_code_2_outlined, size: 18, color: AppColors.muted),
                    tooltip: 'Share invite',
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text('Due', style: AppFonts.heading(fontSize: 15.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (detail.due.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Nothing pending — fully paid up.', style: TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w600)),
          )
        else
          for (final due in detail.due)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DarkCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(due.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('₹${due.amount}', style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 34,
                      width: 128,
                      child: _collecting == due
                          ? const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: CircularProgressIndicator(strokeWidth: 2))
                          : ElevatedButton(
                              onPressed: () => _collect(due),
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14)),
                              child: const Text('Mark Collected', style: TextStyle(fontSize: 12.5)),
                            ),
                    ),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 24),
        Text('History', style: AppFonts.heading(fontSize: 15.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (detail.payments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No payments recorded yet.', style: TextStyle(fontSize: 13, color: AppColors.muted)),
          )
        else
          for (final payment in detail.payments)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DarkCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(payment.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('₹${payment.amount} · ${_formatDate(payment.paidAt)}', style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    PillBadge(label: payment.methodLabel, color: payment.method == 'online' ? AppColors.brand : AppColors.success),
                  ],
                ),
              ),
            ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Text('Maintenance', style: AppFonts.heading(fontSize: 15.5, fontWeight: FontWeight.w700))),
            _savingMaintenanceAmount
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : _TextLink(
                    label: maintenance.tenant.maintenanceAmount > 0 ? 'Edit Amount' : 'Set Amount',
                    onTap: _editMaintenanceAmount,
                  ),
          ],
        ),
        const SizedBox(height: 10),
        if (maintenance.tenant.maintenanceAmount <= 0)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('No monthly maintenance charge set for this tenant.', style: TextStyle(fontSize: 13, color: AppColors.muted)),
          )
        else ...[
          Text('₹${maintenance.tenant.maintenanceAmount}/month', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          if (maintenance.due.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Nothing pending — fully paid up.', style: TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w600)),
            )
          else
            for (final due in maintenance.due)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DarkCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(due.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text('₹${due.amount}', style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 34,
                        width: 128,
                        child: _collectingMaintenance == due
                            ? const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: CircularProgressIndicator(strokeWidth: 2))
                            : ElevatedButton(
                                onPressed: () => _collectMaintenance(due),
                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14)),
                                child: const Text('Mark Collected', style: TextStyle(fontSize: 12.5)),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
          if (maintenance.payments.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final payment in maintenance.payments)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DarkCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(payment.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text('₹${payment.amount} · ${_formatDate(payment.paidAt)}', style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      PillBadge(label: payment.methodLabel, color: payment.method == 'online' ? AppColors.brand : AppColors.success),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ],
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.muted),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5, color: AppColors.muted))),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}

class _MethodPickerSheet extends StatelessWidget {
  final DueMonth due;
  const _MethodPickerSheet({required this.due});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text('How was ${due.label} collected?', style: AppFonts.heading(fontSize: 15.5, fontWeight: FontWeight.w700)),
          ),
          for (final entry in const [('cash', 'Cash'), ('upi', 'UPI'), ('bank_transfer', 'Bank Transfer')])
            ListTile(
              title: Text(entry.$2),
              onTap: () => Navigator.of(context).pop(entry.$1),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// One row of the "Documents" card - either an "Upload" button, an
/// in-progress percentage, or "Uploaded" with View/Replace actions.
class _DocumentRow extends StatelessWidget {
  final String label;
  final String? url;
  // null = not uploading; 0-1 = in-progress upload fraction.
  final double? uploadProgress;
  final VoidCallback onUpload;
  final void Function(String url) onView;

  const _DocumentRow({
    required this.label,
    required this.url,
    required this.uploadProgress,
    required this.onUpload,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final progress = uploadProgress;
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))),
        if (progress != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, value: progress > 0 ? progress : null)),
              const SizedBox(width: 8),
              Text('${(progress * 100).round()}%', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          )
        else if (url == null)
          // Deliberately not an OutlinedButton - Material's ButtonStyleButton
          // (OutlinedButton/TextButton/ElevatedButton, .icon() or not) hits a
          // real Flutter layout bug ("BoxConstraints forces an infinite
          // width") when placed inside this Row, because its _InputPadding
          // minimum-tap-target wrapper can't handle the unbounded width a
          // Row hands non-flex children. A plain InkWell sidesteps it.
          _PillButton(icon: Icons.upload_file_outlined, label: 'Upload', onTap: onUpload)
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TextLink(label: 'View', onTap: () => onView(url!)),
              const SizedBox(width: 16),
              _TextLink(label: 'Replace', onTap: onUpload),
            ],
          ),
      ],
    );
  }
}

/// Small bordered tap target used in place of OutlinedButton - see the
/// comment in _DocumentRow.build() for why.
class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PillButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: AppColors.text),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.text)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small tap target used in place of TextButton - see the comment in
/// _DocumentRow.build() for why.
class _TextLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TextLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.brand, fontWeight: FontWeight.w600)),
    );
  }
}
