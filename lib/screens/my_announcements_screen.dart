import 'package:flutter/material.dart';

import '../models/property_announcement.dart';
import '../services/auth_service.dart';
import '../services/rent_api.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import '../widgets/pill_badge.dart';

/// Tenant-facing, read-only — announcements from every property this
/// signed-in user has actually joined (linked their account to with an
/// owner-shared join code). A property they haven't joined never shows up
/// here; see RentApi.fetchMyAnnouncements / backend/routes/rent.js.
class MyAnnouncementsScreen extends StatefulWidget {
  const MyAnnouncementsScreen({super.key});

  @override
  State<MyAnnouncementsScreen> createState() => _MyAnnouncementsScreenState();
}

class _MyAnnouncementsScreenState extends State<MyAnnouncementsScreen> {
  List<PropertyAnnouncement>? _announcements;
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
      final announcements = await RentApi.fetchMyAnnouncements();
      if (!mounted) return;
      setState(() {
        _announcements = announcements;
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

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildError()
                  : (_announcements?.isEmpty ?? true)
                      ? _buildEmpty()
                      : _buildList(_announcements!),
        ),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
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
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: const [
        SizedBox(height: 40),
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              "No announcements yet. Once you join a property with your owner's code, their announcements will show up here.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<PropertyAnnouncement> announcements) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        for (final a in announcements)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: DarkCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.campaign_outlined, size: 18, color: AppColors.amber),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(a.title, style: AppFonts.heading(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(a.message, style: const TextStyle(fontSize: 13, color: AppColors.muted, height: 1.5)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (a.propertyTitle != null) ...[
                        PillBadge(label: a.propertyTitle!, color: AppColors.brand),
                        const SizedBox(width: 8),
                      ],
                      Text(_formatDate(a.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
