import 'package:flutter/material.dart';
import '../models/property_unit.dart';
import '../models/tenant.dart';
import '../services/property_api.dart';
import '../theme/app_theme.dart';
import '../widgets/pill_badge.dart';
import '../widgets/property_invite_content.dart';
import '../widgets/tenant_invite_content.dart';
import 'property_join_requests_screen.dart';

const _monthAbbr = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

// Option lists for the picker rows below. `0` / `''` is always the "not
// set" sentinel rather than a nullable value, so a picker's return value is
// unambiguous: null means "sheet dismissed, no change", any real option
// (including the "not set" one) means "user made a choice".
const _lockInOptions = <(int, String)>[
  (0, 'No Lock-in'),
  (1, '1 Month'),
  (2, '2 Months'),
  (3, '3 Months'),
  (6, '6 Months'),
  (11, '11 Months'),
  (12, '12 Months'),
];
const _noticePeriodOptions = <(int, String)>[
  (0, 'No Notice Period'),
  (7, '7 Days'),
  (15, '15 Days'),
  (30, '30 Days'),
  (45, '45 Days'),
  (60, '60 Days'),
  (90, '90 Days'),
];
const _agreementPeriodOptions = <(int, String)>[
  (0, 'Not Set'),
  (6, '6 Months'),
  (11, '11 Months'),
  (12, '12 Months'),
  (24, '24 Months'),
  (36, '36 Months'),
];
const _rentDueDayOptions = <(int, String)>[
  (0, 'Not Set'),
  (1, '1st of month'),
  (5, '5th of month'),
  (10, '10th of month'),
  (15, '15th of month'),
  (20, '20th of month'),
  (25, '25th of month'),
  (31, 'Last day of month'),
];
const _tenantTypeOptions = <(String, String)>[
  ('', 'Not Set'),
  ('family', 'Family'),
  ('bachelor_male', 'Bachelor (Male)'),
  ('bachelor_female', 'Bachelor (Female)'),
  ('company', 'Company Lease'),
  ('student', 'Student'),
  ('other', 'Other'),
];

/// Opened from the property dashboard's "Add Tenant" quick action. Laid out
/// as two tabs (Tenant Details / Stay Details) to match the reference
/// design — fields backed by real data are fully functional; a few that
/// would need infrastructure this app doesn't have yet (contacts picker,
/// WhatsApp sending, per-meter electricity tracking) are shown but marked
/// "Coming soon". "Booked By" (which staff member handled it) was dropped
/// entirely rather than stubbed, since this app has no staff/team concept
/// at all - not even a "coming soon" placeholder made sense for it.
class AddTenantScreen extends StatefulWidget {
  final String propertyId;
  final String? propertyTitle;

  const AddTenantScreen({super.key, required this.propertyId, this.propertyTitle});

  @override
  State<AddTenantScreen> createState() => _AddTenantScreenState();
}

class _AddTenantScreenState extends State<AddTenantScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Tenant Details
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _altPhoneController = TextEditingController();
  final _roomController = TextEditingController();
  String _stayType = 'long';
  DateTime _moveInDate = DateTime.now();
  DateTime? _moveOutDate;

  // Stay Details
  final _rentController = TextEditingController();
  final _depositController = TextEditingController();
  final _referredByController = TextEditingController();
  int _lockInMonths = 0;
  int _noticePeriodDays = 0;
  int _agreementPeriodMonths = 0;
  int _rentDueDay = 0;
  String _tenantType = '';
  String _remarks = '';
  String _otherDetails = '';
  // Payment method chosen for this calendar month's (possibly prorated)
  // rent, if the owner wants to mark it collected right away — null until
  // they do. Recorded via the real Collect Payment endpoint right after
  // the tenant is created.
  String? _collectCurrentMonthMethod;

  List<PropertyUnit> _units = [];
  bool _loadingUnits = true;

  bool _saving = false;
  // Set once PropertyApi.addTenant() succeeds - the Invite tab needs a real
  // join code from the backend, so it can't show anything until then.
  Tenant? _createdTenant;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    try {
      final units = await PropertyApi.fetchUnits(widget.propertyId);
      if (!mounted) return;
      setState(() {
        _units = units;
        _loadingUnits = false;
      });
    } catch (_) {
      // Fine to fail quietly — Room/Flat just falls back to free text.
      if (!mounted) return;
      setState(() => _loadingUnits = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _roomController.dispose();
    _rentController.dispose();
    _depositController.dispose();
    _referredByController.dispose();
    super.dispose();
  }

  // --- Actions ---

  Future<void> _pickMoveInDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _moveInDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked == null) return;
    setState(() {
      _moveInDate = picked;
      if (_moveOutDate != null && !_moveOutDate!.isAfter(_moveInDate)) _moveOutDate = null;
    });
  }

  Future<void> _pickMoveOutDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _moveOutDate ?? _moveInDate.add(const Duration(days: 330)),
      firstDate: _moveInDate.add(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _moveOutDate = picked);
  }

  int? _stayMonths() {
    if (_moveOutDate == null) return null;
    final months = (_moveOutDate!.year - _moveInDate.year) * 12 + (_moveOutDate!.month - _moveInDate.month);
    return months <= 0 ? 1 : months;
  }

  Future<void> _pickRoom() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RoomPickerSheet(units: _units),
    );
    if (selected != null) setState(() => _roomController.text = selected);
  }

  Future<T?> _pickOption<T>(String title, List<(T, String)> options, T selected) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OptionPickerSheet<T>(title: title, options: options, selected: selected),
    );
  }

  Future<void> _editRemarks() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TextEditSheet(title: 'Remarks', initialValue: _remarks),
    );
    if (result != null) setState(() => _remarks = result);
  }

  Future<void> _editOtherDetails() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TextEditSheet(title: 'Other Details', initialValue: _otherDetails),
    );
    if (result != null) setState(() => _otherDetails = result);
  }

  Future<void> _pickCollectMethod() async {
    final method = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _CollectMethodSheet(current: _collectCurrentMonthMethod),
    );
    if (method == null) return;
    setState(() => _collectCurrentMonthMethod = method.isEmpty ? null : method);
  }

  void _comingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon')));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final tenant = await PropertyApi.addTenant(
        widget.propertyId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        roomNumber: _roomController.text.trim(),
        monthlyRent: num.parse(_rentController.text.trim()),
        moveInDate: _moveInDate,
        altPhone: _altPhoneController.text.trim(),
        moveOutDate: _moveOutDate,
        stayType: _stayType,
        lockInMonths: _lockInMonths > 0 ? _lockInMonths : null,
        noticePeriodDays: _noticePeriodDays > 0 ? _noticePeriodDays : null,
        agreementPeriodMonths: _agreementPeriodMonths > 0 ? _agreementPeriodMonths : null,
        rentDueDay: _rentDueDay > 0 ? _rentDueDay : null,
        securityDeposit: _depositController.text.trim().isEmpty ? null : num.tryParse(_depositController.text.trim()),
        referredBy: _referredByController.text.trim(),
        remarks: _remarks,
        tenantType: _tenantType.isEmpty ? null : _tenantType,
        otherDetails: _otherDetails,
      );

      if (_collectCurrentMonthMethod != null) {
        final now = DateTime.now();
        try {
          await PropertyApi.collectRentManually(
            widget.propertyId,
            tenant.id,
            month: now.month,
            year: now.year,
            method: _collectCurrentMonthMethod!,
          );
        } catch (_) {
          // Tenant is already created - a failed "mark collected" here
          // shouldn't block the flow. The owner can record it later from
          // Collect Payment.
        }
      }

      if (!mounted) return;
      setState(() {
        _createdTenant = tenant;
        _saving = false;
      });
      _tabController.animateTo(2);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not add tenant: $e')));
    }
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  String _optionLabel<T>(List<(T, String)> options, T value) =>
      options.firstWhere((o) => o.$1 == value, orElse: () => options.first).$2;

  // --- Row-style field building blocks ---

  Widget _row({required String label, required Widget value, VoidCallback? onTap, Widget? trailingIcon}) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(width: 118, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted))),
          Expanded(child: value),
          if (trailingIcon != null) ...[const SizedBox(width: 6), trailingIcon],
        ],
      ),
    );
    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }

  Widget _group(List<Widget> rows) => Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            for (int i = 0; i < rows.length; i++) ...[
              rows[i],
              if (i != rows.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          ],
        ),
      );

  Widget _textField(
    TextEditingController controller, {
    required String hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textAlign: TextAlign.right,
      validator: validator,
      onChanged: (_) => setState(() {}), // keeps the Aug-rent preview live
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
      decoration: InputDecoration(
        isDense: true,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.muted, fontWeight: FontWeight.w500),
        errorStyle: const TextStyle(fontSize: 10.5),
      ),
    );
  }

  Widget _pickerValue(String text, {bool placeholder = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: placeholder ? AppColors.muted : AppColors.text),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.muted),
      ],
    );
  }

  Widget _editableTextValue(String value, {required String hint}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            value.isEmpty ? hint : value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: value.isEmpty ? AppColors.muted : AppColors.text),
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.edit_outlined, size: 15, color: AppColors.brand),
      ],
    );
  }

  Widget _dateValue(DateTime? date, {String placeholderText = ''}) {
    final text = date == null ? placeholderText : _formatDate(date);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            text,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: date == null ? AppColors.muted : AppColors.text),
          ),
        ),
        const SizedBox(width: 6),
        const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.muted),
      ],
    );
  }

  Widget _durationBadge(int months) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$months Month${months > 1 ? 's' : ''}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.success)),
          const SizedBox(width: 6),
          InkWell(onTap: () => setState(() => _moveOutDate = null), child: const Icon(Icons.close, size: 14, color: AppColors.success)),
        ],
      ),
    );
  }

  Widget _contactIcon() => IconButton(
        onPressed: _comingSoon,
        icon: const Icon(Icons.contact_page_outlined, size: 18, color: AppColors.muted),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: 'Pick from contacts (coming soon)',
      );

  Widget _stubCheckboxRow() {
    return InkWell(
      onTap: _comingSoon,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.check_box_outline_blank, size: 20, color: AppColors.muted),
            const SizedBox(width: 10),
            const Expanded(child: Text('Send WhatsApp Rent Reminder', style: TextStyle(fontSize: 13, color: AppColors.muted))),
            _soonBadge(),
          ],
        ),
      ),
    );
  }

  Widget _soonBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(6)),
        child: const Text('Soon', style: TextStyle(fontSize: 10.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
      );

  Widget _stubRow(String label) => _row(label: label, value: _pickerValue('Coming soon', placeholder: true), onTap: _comingSoon);

  // --- Tabs ---

  Widget _buildTenantDetailsTab() {
    final months = _stayMonths();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _group([
          _row(
            label: 'Name',
            value: _textField(
              _nameController,
              hint: 'Add Name',
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? "Enter the tenant's name" : null,
            ),
            trailingIcon: _contactIcon(),
          ),
          _row(
            label: 'Phone',
            value: _textField(
              _phoneController,
              hint: 'Add Phone',
              keyboardType: TextInputType.phone,
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                return digits.length < 10 ? 'Enter a valid phone number' : null;
              },
            ),
            trailingIcon: _contactIcon(),
          ),
          _row(
            label: 'Alt Phone',
            value: _textField(_altPhoneController, hint: 'Add Alt Phone', keyboardType: TextInputType.phone),
            trailingIcon: _contactIcon(),
          ),
        ]),
        const SizedBox(height: 4),
        _stubCheckboxRow(),
        const SizedBox(height: 10),
        _group([
          _row(
            label: 'Property',
            value: Text(
              widget.propertyTitle ?? 'This property',
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
            ),
          ),
          _row(
            label: 'Room/Flat',
            value: _loadingUnits
                ? const Align(alignment: Alignment.centerRight, child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                : _units.isEmpty
                    ? _textField(_roomController, hint: 'Room number (optional)')
                    : _pickerValue(_roomController.text.isEmpty ? 'Select Room' : _roomController.text, placeholder: _roomController.text.isEmpty),
            onTap: _units.isEmpty ? null : _pickRoom,
          ),
        ]),
        const SizedBox(height: 14),
        _group([
          _row(
            label: 'Stay Type',
            value: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _stayTypeSegment('Long', 'long'),
                const SizedBox(width: 8),
                _stayTypeSegment('Short', 'short'),
              ],
            ),
          ),
          _row(label: 'Move-in', value: _dateValue(_moveInDate), onTap: _pickMoveInDate),
          if (months != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Align(alignment: Alignment.centerLeft, child: _durationBadge(months)),
            ),
          _row(label: 'Move-out', value: _dateValue(_moveOutDate, placeholderText: 'Set move-out'), onTap: _pickMoveOutDate),
        ]),
      ],
    );
  }

  Widget _stayTypeSegment(String label, String value) {
    final selected = _stayType == value;
    return InkWell(
      onTap: () => setState(() => _stayType = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.brand : AppColors.border),
        ),
        child: Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: selected ? AppColors.brand : AppColors.muted)),
      ),
    );
  }

  Widget _buildStayDetailsTab() {
    final now = DateTime.now();
    final monthAbbr = _monthAbbr[now.month - 1];
    final periodStartDay = (_moveInDate.year == now.year && _moveInDate.month == now.month) ? _moveInDate.day : 1;
    final periodEndDate = DateTime(now.year, now.month + 1, 0);
    final rentValue = num.tryParse(_rentController.text.trim());
    final collected = _collectCurrentMonthMethod != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _group([
          _row(
            label: 'Lock-in Period',
            value: _pickerValue(_optionLabel(_lockInOptions, _lockInMonths), placeholder: _lockInMonths == 0),
            onTap: () async {
              final picked = await _pickOption('Lock-in Period', _lockInOptions, _lockInMonths);
              if (picked != null) setState(() => _lockInMonths = picked);
            },
          ),
          _row(
            label: 'Notice Period',
            value: _pickerValue(_optionLabel(_noticePeriodOptions, _noticePeriodDays), placeholder: _noticePeriodDays == 0),
            onTap: () async {
              final picked = await _pickOption('Notice Period', _noticePeriodOptions, _noticePeriodDays);
              if (picked != null) setState(() => _noticePeriodDays = picked);
            },
          ),
          _row(
            label: 'Agreement Period',
            value: _pickerValue(_optionLabel(_agreementPeriodOptions, _agreementPeriodMonths), placeholder: _agreementPeriodMonths == 0),
            onTap: () async {
              final picked = await _pickOption('Agreement Period', _agreementPeriodOptions, _agreementPeriodMonths);
              if (picked != null) setState(() => _agreementPeriodMonths = picked);
            },
          ),
        ]),
        const SizedBox(height: 14),
        _group([
          _row(
            label: 'Rental Frequency',
            value: const Text('Monthly', textAlign: TextAlign.right, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
          ),
          _row(
            label: 'Add Rent On',
            value: _pickerValue(_optionLabel(_rentDueDayOptions, _rentDueDay), placeholder: _rentDueDay == 0),
            onTap: () async {
              final picked = await _pickOption('Add Rent On', _rentDueDayOptions, _rentDueDay);
              if (picked != null) setState(() => _rentDueDay = picked);
            },
          ),
          _row(
            label: 'Fixed Rent',
            value: _textField(
              _rentController,
              hint: '₹ Amount',
              keyboardType: TextInputType.number,
              validator: (v) {
                final amount = num.tryParse((v ?? '').trim());
                return (amount == null || amount <= 0) ? 'Enter a valid amount' : null;
              },
            ),
          ),
          _row(label: 'Security Deposit', value: _textField(_depositController, hint: '₹ Amount', keyboardType: TextInputType.number)),
        ]),
        const SizedBox(height: 14),
        _group([
          _row(label: 'Referred by', value: _textField(_referredByController, hint: 'Referred by')),
          _row(label: 'Remarks', value: _editableTextValue(_remarks, hint: 'Remarks'), onTap: _editRemarks),
          _stubRow('Room / Electricity Meter'),
          _stubRow('Tenant / Electricity Meter'),
          _row(
            label: 'Tenant Type',
            value: _pickerValue(_optionLabel(_tenantTypeOptions, _tenantType), placeholder: _tenantType.isEmpty),
            onTap: () async {
              final picked = await _pickOption('Tenant Type', _tenantTypeOptions, _tenantType);
              if (picked != null) setState(() => _tenantType = picked);
            },
          ),
          _row(label: 'Other Details', value: _editableTextValue(_otherDetails, hint: 'Other Details'), onTap: _editOtherDetails),
        ]),
        const SizedBox(height: 14),
        _group([
          _row(label: 'Opening Balance', value: _pickerValue('Other Dues', placeholder: true), onTap: _comingSoon),
        ]),
        const SizedBox(height: 14),
        _group([
          _row(
            label: '$monthAbbr Rent',
            value: Text(
              '$periodStartDay $monthAbbr to ${periodEndDate.day} $monthAbbr',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
            ),
          ),
          _row(
            label: 'Due',
            value: Text(
              rentValue == null ? '—' : '₹${collected ? 0 : rentValue}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.danger),
            ),
          ),
          _row(
            label: 'Collection',
            value: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  collected ? '₹${rentValue ?? 0}' : '₹0',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: collected ? AppColors.success : AppColors.muted),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.edit_outlined, size: 15, color: AppColors.brand),
              ],
            ),
            onTap: _pickCollectMethod,
          ),
        ]),
      ],
    );
  }

  Widget _buildInviteTab() {
    final tenant = _createdTenant;
    final propertyTitle = widget.propertyTitle ?? 'This property';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text('Invite a tenant', style: AppFonts.heading(fontSize: 17, fontWeight: FontWeight.w800))),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PropertyJoinRequestsScreen(propertyId: widget.propertyId, propertyTitle: propertyTitle)),
              ),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              icon: const Icon(Icons.playlist_add_check_outlined, size: 18),
              label: const Text('Requests', style: TextStyle(fontSize: 12.5)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        PropertyInviteContent(propertyId: widget.propertyId, propertyTitle: propertyTitle),
        if (tenant != null) ...[
          const Padding(padding: EdgeInsets.symmetric(vertical: 26), child: Divider(height: 1)),
          Text("${tenant.name}'s join code", style: AppFonts.heading(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text(
            "Since you added them yourself just now, here's their code directly — no need to wait for a joining request.",
            style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 14),
          TenantInviteContent(tenant: tenant, propertyTitle: widget.propertyTitle),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final added = _createdTenant != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Add Tenant')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            ColoredBox(
              color: AppColors.card,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.brand,
                unselectedLabelColor: AppColors.muted,
                indicatorColor: AppColors.brand,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                tabs: const [Tab(text: 'Tenant Details'), Tab(text: 'Stay Details'), Tab(text: 'Invite')],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildTenantDetailsTab(), _buildStayDetailsTab(), _buildInviteTab()],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : (added ? () => Navigator.of(context).pop<Tenant>(_createdTenant) : _submit),
              style: ElevatedButton.styleFrom(shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(added ? 'Done' : 'Add Tenant', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet listing a property's units — tapping one sets Room/Flat.
/// Shown regardless of occupied/vacant status since a Tenant record isn't
/// otherwise linked to a Unit; the badge is informational.
class _RoomPickerSheet extends StatelessWidget {
  final List<PropertyUnit> units;
  const _RoomPickerSheet({required this.units});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        decoration: const BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Room', style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: units.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final u = units[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(u.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${u.floor} · ${u.beds} bed${u.beds > 1 ? 's' : ''}', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    trailing: PillBadge(label: u.isOccupied ? 'Occupied' : 'Vacant', color: u.isOccupied ? AppColors.muted : AppColors.success),
                    onTap: () => Navigator.of(context).pop(u.label),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Generic single-select bottom sheet for the Lock-in/Notice/Agreement/Rent
/// Day/Tenant Type pickers.
class _OptionPickerSheet<T> extends StatelessWidget {
  final String title;
  final List<(T, String)> options;
  final T selected;

  const _OptionPickerSheet({required this.title, required this.options, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        decoration: const BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final (value, label) = options[i];
                  final isSelected = value == selected;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? AppColors.brand : AppColors.text)),
                    trailing: isSelected ? const Icon(Icons.check, color: AppColors.brand, size: 18) : null,
                    onTap: () => Navigator.of(context).pop(value),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small multiline text editor sheet used for Remarks / Other Details.
class _TextEditSheet extends StatefulWidget {
  final String title;
  final String initialValue;

  const _TextEditSheet({required this.title, required this.initialValue});

  @override
  State<_TextEditSheet> createState() => _TextEditSheetState();
}

class _TextEditSheetState extends State<_TextEditSheet> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: const BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              TextField(controller: _controller, autofocus: true, maxLines: 4, decoration: InputDecoration(hintText: widget.title)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: () => Navigator.of(context).pop(_controller.text.trim()), child: const Text('Save')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Payment-method picker for marking the current month's rent collected
/// right at tenant creation — same real Collect Payment flow used
/// elsewhere, just triggered a step earlier.
class _CollectMethodSheet extends StatelessWidget {
  final String? current;
  const _CollectMethodSheet({this.current});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text('Mark this month collected?', style: AppFonts.heading(fontSize: 15.5, fontWeight: FontWeight.w700)),
            ),
            for (final entry in const [('cash', 'Cash'), ('upi', 'UPI'), ('bank_transfer', 'Bank Transfer')])
              ListTile(
                title: Text(entry.$2),
                trailing: current == entry.$1 ? const Icon(Icons.check, color: AppColors.brand) : null,
                onTap: () => Navigator.of(context).pop(entry.$1),
              ),
            if (current != null)
              ListTile(
                title: const Text('Not collected yet', style: TextStyle(color: AppColors.muted)),
                onTap: () => Navigator.of(context).pop(''),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
