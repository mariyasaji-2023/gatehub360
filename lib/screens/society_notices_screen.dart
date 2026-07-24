import 'package:flutter/material.dart';

import '../models/society_notice.dart';
import '../services/auth_service.dart';
import '../services/society_api.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';

class SocietyNoticesScreen extends StatefulWidget {
  const SocietyNoticesScreen({super.key});

  @override
  State<SocietyNoticesScreen> createState() => _SocietyNoticesScreenState();
}

class _SocietyNoticesScreenState extends State<SocietyNoticesScreen> {
  List<SocietyNotice> _notices = [];
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
      final notices = await SocietyApi.fetchNotices();
      if (!mounted) return;
      setState(() {
        _isAssociation = user.role == UserRole.apartmentAssociation;
        _notices = notices;
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

  Future<void> _openForm() async {
    final result = await showModalBottomSheet<({String title, String message})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NoticeFormSheet(),
    );
    if (result == null) return;

    try {
      await SocietyApi.createNotice(title: result.title, message: result.message);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete(SocietyNotice notice) async {
    try {
      await SocietyApi.deleteNotice(notice.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notices')),
      floatingActionButton: _isAssociation
          ? FloatingActionButton.extended(
              onPressed: _openForm,
              icon: const Icon(Icons.add),
              label: const Text('Add Notice'),
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
                        if (_notices.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'No notices yet.',
                                style: TextStyle(fontSize: 13.5, color: AppColors.muted),
                              ),
                            ),
                          ),
                        ..._notices.map((n) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: DarkCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(n.title, style: AppFonts.heading(fontSize: 15, fontWeight: FontWeight.w700)),
                                        ),
                                        if (_isAssociation)
                                          InkWell(
                                            onTap: () => _delete(n),
                                            child: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(n.message, style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.5)),
                                    const SizedBox(height: 10),
                                    Text(_formatDate(n.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
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

class _NoticeFormSheet extends StatefulWidget {
  const _NoticeFormSheet();

  @override
  State<_NoticeFormSheet> createState() => _NoticeFormSheetState();
}

class _NoticeFormSheetState extends State<_NoticeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((title: _titleController.text.trim(), message: _messageController.text.trim()));
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
                Text('Add Notice', style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _messageController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Message'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(onPressed: _save, child: const Text('Post Notice')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
