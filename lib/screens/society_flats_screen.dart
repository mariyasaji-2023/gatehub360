import 'package:flutter/material.dart';

import '../models/society_flat.dart';
import '../services/auth_service.dart';
import '../services/society_api.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import '../widgets/pill_badge.dart';

class SocietyFlatsScreen extends StatefulWidget {
  const SocietyFlatsScreen({super.key});

  @override
  State<SocietyFlatsScreen> createState() => _SocietyFlatsScreenState();
}

class _SocietyFlatsScreenState extends State<SocietyFlatsScreen> {
  List<SocietyFlat> _flats = [];
  bool _isAssociation = false;
  bool _loading = true;
  String? _error;

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
      final user = await AuthService.syncCurrentUser();
      final flats = await SocietyApi.fetchFlats();
      if (!mounted) return;
      setState(() {
        _isAssociation = user.role == UserRole.apartmentAssociation;
        _flats = flats;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _openAddMenu() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add, color: AppColors.brand),
              title: const Text('Add One Flat'),
              onTap: () => Navigator.of(context).pop('single'),
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add, color: AppColors.brand),
              title: const Text('Bulk Add'),
              subtitle: const Text('Paste a list of flat numbers', style: TextStyle(fontSize: 11.5)),
              onTap: () => Navigator.of(context).pop('bulk'),
            ),
          ],
        ),
      ),
    );

    if (choice == 'single') {
      await _openAddForm();
    } else if (choice == 'bulk') {
      await _openBulkAddForm();
    }
  }

  Future<void> _openAddForm() async {
    final flatNumber = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FlatFormSheet(),
    );
    if (flatNumber == null) return;

    try {
      await SocietyApi.addFlat(flatNumber);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openBulkAddForm() async {
    final flatNumbers = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _BulkFlatFormSheet(),
    );
    if (flatNumbers == null) return;

    try {
      final result = await SocietyApi.addFlatsBulk(flatNumbers);
      await _load();
      if (!mounted) return;
      final message = result.skipped > 0
          ? 'Added ${result.created} flats (${result.skipped} already existed)'
          : 'Added ${result.created} flats';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openActions(SocietyFlat flat) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'Flat ${flat.flatNumber}',
                style: AppFonts.heading(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            if (flat.status == FlatStatus.vacant)
              ListTile(
                leading: const Icon(Icons.person_outline, color: AppColors.success),
                title: const Text('Mark Occupied'),
                onTap: () => Navigator.of(context).pop('occupy'),
              )
            else
              ListTile(
                leading: const Icon(Icons.person_off_outlined, color: AppColors.muted),
                title: const Text('Mark Vacant'),
                onTap: () => Navigator.of(context).pop('vacate'),
              ),
            if (flat.status == FlatStatus.vacant)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text('Delete Flat', style: TextStyle(color: AppColors.danger)),
                onTap: () => Navigator.of(context).pop('delete'),
              ),
          ],
        ),
      ),
    );

    if (action == null || !mounted) return;
    if (action == 'occupy') {
      await _setStatus(flat, FlatStatus.occupied);
    } else if (action == 'vacate') {
      await _confirmVacate(flat);
    } else if (action == 'delete') {
      await _deleteFlat(flat);
    }
  }

  Future<void> _confirmVacate(SocietyFlat flat) async {
    final hasResident = flat.residentName != null;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark as vacant?'),
        content: Text(
          hasResident
              ? '${flat.residentName} is currently linked to this flat through the app and will be removed from the society.'
              : "This flat will be marked available for new tenants to join.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _setStatus(flat, FlatStatus.vacant);
  }

  Future<void> _setStatus(SocietyFlat flat, FlatStatus status) async {
    try {
      await SocietyApi.setFlatStatus(flat.id, status);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _deleteFlat(SocietyFlat flat) async {
    try {
      await SocietyApi.deleteFlat(flat.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flats')),
      floatingActionButton: _isAssociation
          ? FloatingActionButton.extended(
              onPressed: _openAddMenu,
              icon: const Icon(Icons.add),
              label: const Text('Add Flat'),
              backgroundColor: AppColors.brand,
            )
          : null,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? ListView(
                      children: [
                        const SizedBox(height: 40),
                        Center(
                          child: Column(
                            children: [
                              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, color: AppColors.muted)),
                              const SizedBox(height: 12),
                              OutlinedButton(onPressed: _load, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      children: [
                        if (_flats.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                _isAssociation ? 'No flats added yet. Tap "Add Flat" to get started.' : 'No flats have been added yet.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13.5, color: AppColors.muted),
                              ),
                            ),
                          ),
                        ..._flats.map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: DarkCard(
                                onTap: _isAssociation ? () => _openActions(f) : null,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Flat ${f.flatNumber}', style: AppFonts.heading(fontSize: 15, fontWeight: FontWeight.w700)),
                                          if (f.status == FlatStatus.occupied && f.residentName != null) ...[
                                            const SizedBox(height: 4),
                                            Text(f.residentName!, style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
                                          ],
                                        ],
                                      ),
                                    ),
                                    PillBadge(
                                      label: f.status.label,
                                      color: f.status == FlatStatus.vacant ? AppColors.success : AppColors.muted,
                                    ),
                                  ],
                                ),
                              ),
                            )),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _BulkFlatFormSheet extends StatefulWidget {
  const _BulkFlatFormSheet();

  @override
  State<_BulkFlatFormSheet> createState() => _BulkFlatFormSheetState();
}

class _BulkFlatFormSheetState extends State<_BulkFlatFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final flatNumbers = _controller.text
        .split(RegExp(r'[,\n]'))
        .map((n) => n.trim())
        .where((n) => n.isNotEmpty)
        .toList();
    Navigator.of(context).pop(flatNumbers);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bulk Add Flats', style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text(
                  'One flat number per line, or separate with commas.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _controller,
                  autofocus: true,
                  maxLines: 8,
                  minLines: 5,
                  decoration: const InputDecoration(labelText: 'Flat numbers', hintText: 'A-101\nA-102\nA-103'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final hasAny = v.split(RegExp(r'[,\n]')).any((n) => n.trim().isNotEmpty);
                    return hasAny ? null : 'Required';
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: _save, child: const Text('Add Flats')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FlatFormSheet extends StatefulWidget {
  const _FlatFormSheet();

  @override
  State<_FlatFormSheet> createState() => _FlatFormSheetState();
}

class _FlatFormSheetState extends State<_FlatFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Flat', style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              TextFormField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Flat number'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _save, child: const Text('Add Flat')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
