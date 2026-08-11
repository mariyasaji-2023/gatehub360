import 'dart:async';

import 'package:flutter/material.dart';

import '../models/society.dart';
import '../models/society_bill.dart';
import '../models/society_flat.dart';
import '../models/society_join_request.dart';
import '../models/society_search_result.dart';
import '../services/auth_service.dart';
import '../services/society_api.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import '../widgets/flat_picker_sheet.dart';
import '../widgets/gradient_banner.dart';
import '../widgets/home_greeting_header.dart';
import '../widgets/pill_badge.dart';
import '../widgets/section_hero.dart';
import 'profile_screen.dart';
import 'property_list_screen.dart';
import 'services_list_screen.dart';
import 'society_billing_screen.dart';
import 'society_complaints_screen.dart';
import 'society_dashboard_screen.dart';
import 'society_directory_screen.dart';
import 'society_flats_screen.dart';
import 'society_notices_screen.dart';

class SocietyScreen extends StatefulWidget {
  const SocietyScreen({super.key});

  @override
  State<SocietyScreen> createState() => _SocietyScreenState();
}

class _SocietyScreenState extends State<SocietyScreen> {
  bool _loading = true;
  String? _error;
  AuthUser? _user;
  UserRole? _role;
  Society? _society;
  List<Society> _societies = [];
  SocietyJoinRequest? _myRequest;
  String? _dismissedRequestId;
  List<SocietyBill> _recentBills = [];

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
      if (user.role == UserRole.apartmentAssociation) {
        final societies = await SocietyApi.fetchMine();
        if (!mounted) return;
        setState(() {
          _user = user;
          _role = user.role;
          _societies = societies;
          _loading = false;
        });
      } else {
        final society = await SocietyApi.fetchMySociety();
        final myRequest = society == null ? await SocietyApi.fetchMyJoinRequest() : null;
        // Recent Activity on the home view is real billing history, not
        // placeholder data — only fetch it once we know the resident has a
        // society (and therefore a flat) to bill.
        final recentBills = society == null ? <SocietyBill>[] : await _fetchRecentBills();
        if (!mounted) return;
        setState(() {
          _user = user;
          _role = user.role;
          _society = society;
          _myRequest = myRequest;
          _recentBills = recentBills;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Something went wrong. Please try again.';
        _loading = false;
      });
    }
  }

  Future<void> _enterSociety(Society society) async {
    try {
      await SocietyApi.switchSociety(society.id);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => SocietyDashboardScreen(society: society)));
      if (!mounted) return;
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openAddSociety() async {
    final created = await showModalBottomSheet<Society>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddSocietySheet(),
    );
    if (created == null || !mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => SocietyDashboardScreen(society: created)));
    if (!mounted) return;
    _load();
  }

  Future<void> _leaveSociety() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leave society?'),
        content: const Text("You'll lose access to its notices, complaints, directory and billing until you join again."),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Leave')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await SocietyApi.leaveSociety();
      _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openEnterSociety() async {
    final entered = await showModalBottomSheet<Society>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _EnterSocietySheet(),
    );
    if (entered == null || !mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => SocietyDashboardScreen(society: entered)));
    if (!mounted) return;
    _load();
  }

  bool get _showAddSocietyButton => _role == UserRole.apartmentAssociation && !_loading && _error == null;

  // The "join a society" empty state is the one screen with nothing else on
  // it — no banner, no listings — so it's the one that benefits from a
  // decorative accent instead of reading as a blank page.
  bool get _showEmptyStateDecoration =>
      !_loading && _error == null && _role != UserRole.apartmentAssociation && _society == null;

  /// Most recent bills first (by period), capped to what the home view's
  /// Recent Activity card shows — the full history stays one tap away on
  /// the Billing screen.
  Future<List<SocietyBill>> _fetchRecentBills() async {
    final bills = await SocietyApi.fetchBills();
    bills.sort((a, b) {
      final byYear = b.year.compareTo(a.year);
      return byYear != 0 ? byYear : b.month.compareTo(a.month);
    });
    return bills.take(3).toList();
  }

  // Society is only the landing tab for associations — tenants land on
  // Services first (which has its own greeting), so showing "Hello, Welcome
  // Back!" again here would be a redundant repeat for them.
  bool get _showHomeHeader => !_loading && _error == null && _role == UserRole.apartmentAssociation;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Purely-black tiles left the "join a society" empty state with
            // nothing but a card floating on a blank page — these faint
            // outline shapes echo the corner accents from the marketing
            // mockup, anchored to the screen so they don't scroll with content.
            if (_showEmptyStateDecoration) ..._EmptyStateDecoration.corners(),
            RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  if (_showHomeHeader)
                    HomeGreetingHeader(
                      name: _user?.name,
                      photoUrl: _user?.photoURL,
                      onBellTap: _society != null
                          ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SocietyNoticesScreen()))
                          : null,
                      onAvatarTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
                    )
                  else
                    const SectionHero(
                      titleStart: 'Housing Society',
                      titleHighlight: 'Management',
                      accentColor: AppColors.brand,
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildBody(),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _showAddSocietyButton
            ? Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FilledActionBar(
                      icon: Icons.vpn_key_outlined,
                      title: 'Enter Existing Society',
                      subtitle: 'Using an invite code',
                      onTap: _openEnterSociety,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _openAddSociety,
                      icon: const Icon(Icons.add),
                      label: const Text('Add New Society'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, color: AppColors.muted)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_role == UserRole.apartmentAssociation) {
      return _MySocietiesGrid(societies: _societies, onTapSociety: _enterSociety);
    }

    if (_society == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_myRequest?.status == JoinRequestStatus.pending) ...[
            DarkCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Request pending', style: AppFonts.heading(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    'Waiting for ${_myRequest!.societyName ?? 'the society'} to approve your request to join.',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else if (_myRequest?.status == JoinRequestStatus.rejected && _myRequest!.id != _dismissedRequestId) ...[
            DarkCard(
              borderColor: AppColors.danger,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Your request to join ${_myRequest!.societyName ?? 'that society'} was declined.',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      final id = _myRequest!.id;
                      setState(() => _dismissedRequestId = id);
                      unawaited(SocietyApi.dismissJoinRequest(id));
                    },
                    child: const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Icon(Icons.close, size: 18, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          _JoinSocietyCard(onJoined: _load),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SocietySelectorBanner(society: _society!),
        const SizedBox(height: 24),
        Text('Quick Actions', style: AppFonts.heading(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.receipt_long_outlined,
                color: AppColors.brand,
                label: 'Pay Bills',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SocietyBillingScreen())),
              ),
            ),
            Expanded(
              child: _QuickAction(
                icon: Icons.report_problem_outlined,
                color: AppColors.danger,
                label: 'Raise\nComplaint',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SocietyComplaintsScreen())),
              ),
            ),
            Expanded(
              child: _QuickAction(
                icon: Icons.campaign_outlined,
                color: AppColors.amber,
                label: 'Notices',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SocietyNoticesScreen())),
              ),
            ),
            Expanded(
              child: _QuickAction(
                icon: Icons.people_outline,
                color: AppColors.success,
                label: 'Directory',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SocietyDirectoryScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Text('Explore', style: AppFonts.heading(fontSize: 17, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _ExploreCard(
                icon: Icons.villa_outlined,
                title: 'Find Properties',
                subtitle: 'Rent, PG & More',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PropertyListScreen())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ExploreCard(
                icon: Icons.handyman_outlined,
                title: 'Services',
                subtitle: 'Book & Manage',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ServicesListScreen())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MoreLinkRow(
          icon: Icons.door_front_door_outlined,
          title: 'Society Flats',
          subtitle: 'View availability',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SocietyFlatsScreen())),
        ),
        const SizedBox(height: 24),
        GradientBanner(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SocietyBillingScreen())),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(Icons.verified_user_outlined, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Secure Payments', style: AppFonts.heading(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 2),
                    const Text('Safe, Fast, Reliable', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Activity', style: AppFonts.heading(fontSize: 17, fontWeight: FontWeight.w700)),
            InkWell(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SocietyBillingScreen())),
              child: const Text('View all', style: TextStyle(fontSize: 12.5, color: AppColors.brand, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _RecentActivity(bills: _recentBills),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _leaveSociety,
            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger), foregroundColor: AppColors.danger),
            child: const Text('Leave Society'),
          ),
        ),
      ],
    );
  }
}

/// Compact "which society am I in" identity card — the blue gradient banner
/// from the mockup, sized down to a single row since a resident belongs to
/// exactly one society (unlike the association's multi-society switcher).
class _SocietySelectorBanner extends StatelessWidget {
  final Society society;
  const _SocietySelectorBanner({required this.society});

  @override
  Widget build(BuildContext context) {
    return GradientBanner(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  society.name,
                  style: AppFonts.heading(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  society.address,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.apartment, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.color, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.text, height: 1.2),
        ),
      ],
    );
  }
}

class _ExploreCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExploreCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DarkCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.brand.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.brand, size: 20),
          ),
          const SizedBox(height: 10),
          Text(title, style: AppFonts.heading(fontSize: 13.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _MoreLinkRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MoreLinkRow({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DarkCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.brand),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppFonts.heading(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 20, color: AppColors.muted),
        ],
      ),
    );
  }
}

/// Real billing history (most recent bills), not placeholder data — mirrors
/// the mockup's "Maintenance Bill · Paid Successfully" activity row.
class _RecentActivity extends StatelessWidget {
  final List<SocietyBill> bills;
  const _RecentActivity({required this.bills});

  @override
  Widget build(BuildContext context) {
    if (bills.isEmpty) {
      return const DarkCard(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('No billing activity yet.', style: TextStyle(fontSize: 12.5, color: AppColors.muted)),
        ),
      );
    }
    return Column(
      children: bills
          .map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DarkCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: (b.paid ? AppColors.success : AppColors.amber).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.receipt_long_outlined,
                          size: 18,
                          color: b.paid ? AppColors.success : AppColors.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Maintenance Bill', style: AppFonts.heading(fontSize: 13.5, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(b.periodLabel, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${b.amount}', style: AppFonts.heading(fontSize: 13.5, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          PillBadge(label: b.paid ? 'Paid' : 'Due', color: b.paid ? AppColors.success : AppColors.amber),
                        ],
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

/// The colorful building-cluster graphic bleeding off the right edge — a
/// black page with a single centered card otherwise reads as empty/broken
/// rather than intentionally minimal. `IgnorePointer` so it never intercepts
/// a tap meant for the content above.
class _EmptyStateDecoration {
  static List<Widget> corners() => const [
        Positioned(
          right: -10,
          bottom: 0,
          child: IgnorePointer(
            child: Image(image: AssetImage('assets/images/city_buildings.png'), width: 200),
          ),
        ),
      ];
}

class _MySocietiesGrid extends StatelessWidget {
  final List<Society> societies;
  final ValueChanged<Society> onTapSociety;

  const _MySocietiesGrid({required this.societies, required this.onTapSociety});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('My Societies', style: AppFonts.heading(fontSize: 19, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          societies.isEmpty ? 'Create your first society or enter one you already manage.' : 'Tap a society to manage it.',
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        if (societies.isNotEmpty) ...[
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
            children: societies
                .map((s) => DarkCard(
                      padding: const EdgeInsets.all(16),
                      onTap: () => onTapSociety(s),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.apartment, size: 26, color: AppColors.brand),
                          const SizedBox(height: 12),
                          Text(s.name, style: AppFonts.heading(fontSize: 14.5, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Text(s.address, style: const TextStyle(fontSize: 11.5, color: AppColors.muted), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _FilledActionBar extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FilledActionBar({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.brandLight.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.brandLight.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 24, color: AppColors.brandLight),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppFonts.heading(fontSize: 14.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.brandLight),
            ],
          ),
        ),
      ),
    );
  }
}

class _JoinSocietyCard extends StatefulWidget {
  final VoidCallback onJoined;
  const _JoinSocietyCard({required this.onJoined});

  @override
  State<_JoinSocietyCard> createState() => _JoinSocietyCardState();
}

class _JoinSocietyCardState extends State<_JoinSocietyCard> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    final code = _codeController.text.trim();
    setState(() => _saving = true);
    try {
      final result = await SocietyApi.fetchFlatsForCode(code);
      if (!mounted) return;
      setState(() => _saving = false);
      if (result.flats.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This society has not added any flats yet. Ask your association to add flats first.')),
        );
        return;
      }
      final picked = await showModalBottomSheet<SocietyFlat>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => FlatPickerSheet(
          title: 'Join ${result.societyName}',
          flats: result.flats,
          emptyMessage: 'No flats have been added yet. Ask your association to add flats before joining.',
        ),
      );
      if (picked == null || !mounted) return;
      await SocietyApi.joinSociety(code: code, flatId: picked.id);
      widget.onJoined();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openSearchCommunity() async {
    final joined = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SearchCommunitySheet(),
    );
    if (joined == true) widget.onJoined();
  }

  @override
  Widget build(BuildContext context) {
    return DarkCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Join your society', style: AppFonts.heading(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text(
              'Ask your apartment association for the invite code.',
              style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Invite code'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Text('Join Society'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _openSearchCommunity,
                child: const Text('Search Community'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchCommunitySheet extends StatefulWidget {
  const _SearchCommunitySheet();

  @override
  State<_SearchCommunitySheet> createState() => _SearchCommunitySheetState();
}

class _SearchCommunitySheetState extends State<_SearchCommunitySheet> {
  final _queryController = TextEditingController();
  Timer? _debounce;
  bool _searching = false;
  bool _searched = false;
  String? _error;
  List<SocietySearchResult> _results = [];

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _search);
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    setState(() {
      _searching = true;
      _error = null;
      _searched = true;
    });
    try {
      final results = await SocietyApi.searchSocieties(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _searching = false;
      });
    }
  }

  Future<void> _join(SocietySearchResult society) async {
    try {
      await SocietyApi.createJoinRequest(societyId: society.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent — waiting for the association to approve.')),
      );
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Search Community', style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text(
                'Search by society name or location.',
                style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      decoration: const InputDecoration(labelText: 'Name, area or city'),
                      onChanged: _onQueryChanged,
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 50,
                    width: 50,
                    child: ElevatedButton(
                      onPressed: _searching ? null : _search,
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                      child: _searching
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                          : const Icon(Icons.search),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.danger)),
              ],
              if (_searched && !_searching && _error == null) ...[
                const SizedBox(height: 14),
                if (_results.isEmpty)
                  const Text('No matching communities found.', style: TextStyle(fontSize: 12.5, color: AppColors.muted))
                else
                  ..._results.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.name, style: AppFonts.heading(fontSize: 14, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text(
                                      [s.area, s.city, s.state].where((v) => v.isNotEmpty).join(', '),
                                      style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () => _join(s),
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.brand), minimumSize: const Size(0, 36)),
                                child: const Text('Join', style: TextStyle(color: AppColors.brand, fontSize: 12.5)),
                              ),
                            ],
                          ),
                        ),
                      )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}


class _AddSocietySheet extends StatefulWidget {
  const _AddSocietySheet();

  @override
  State<_AddSocietySheet> createState() => _AddSocietySheetState();
}

class _AddSocietySheetState extends State<_AddSocietySheet> {
  final _formKey = GlobalKey<FormState>();
  final _pincodeController = TextEditingController();
  final _areaController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _pincodeController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      final society = await SocietyApi.createSociety(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        pincode: _pincodeController.text.trim(),
        area: _areaController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(society);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  static String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

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
                Text('Add New Society', style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text(
                  "You'll get an invite code to share with residents once it's created.",
                  style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Pincode'),
                  validator: _required,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _areaController,
                  decoration: const InputDecoration(labelText: 'Area'),
                  validator: _required,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'City'),
                  validator: _required,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _stateController,
                  decoration: const InputDecoration(labelText: 'State'),
                  validator: _required,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Society name'),
                  validator: _required,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Community Address'),
                  validator: _required,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                        : const Text('Create Society'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EnterSocietySheet extends StatefulWidget {
  const _EnterSocietySheet();

  @override
  State<_EnterSocietySheet> createState() => _EnterSocietySheetState();
}

class _EnterSocietySheetState extends State<_EnterSocietySheet> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      final society = await SocietyApi.enterSociety(_codeController.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop(society);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _openSearch() async {
    final entered = await showModalBottomSheet<Society>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AssociationSearchSheet(),
    );
    if (entered != null && mounted) {
      Navigator.of(context).pop(entered);
    }
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
                Text('Enter Existing Society', style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text(
                  "You'll become a co-manager of this society.",
                  style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Invite code'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                        : const Text('Enter Society'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _openSearch,
                    child: const Text('Search Community'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AssociationSearchSheet extends StatefulWidget {
  const _AssociationSearchSheet();

  @override
  State<_AssociationSearchSheet> createState() => _AssociationSearchSheetState();
}

class _AssociationSearchSheetState extends State<_AssociationSearchSheet> {
  final _queryController = TextEditingController();
  Timer? _debounce;
  bool _searching = false;
  bool _searched = false;
  bool _entering = false;
  String? _error;
  List<SocietySearchResult> _results = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), _search);
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _searching = true;
      _error = null;
      _searched = true;
    });
    try {
      final results = await SocietyApi.searchSocieties(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _searching = false;
      });
    }
  }

  Future<void> _enter(SocietySearchResult result) async {
    setState(() => _entering = true);
    try {
      final society = await SocietyApi.enterSocietyBySearch(result.id);
      if (!mounted) return;
      Navigator.of(context).pop(society);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _entering = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Search Community', style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text(
                "Find a society by name or location to become its co-manager.",
                style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      decoration: const InputDecoration(labelText: 'Name, area or city'),
                      onChanged: _onQueryChanged,
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 50,
                    width: 50,
                    child: ElevatedButton(
                      onPressed: _searching ? null : _search,
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
                      child: _searching
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                          : const Icon(Icons.search),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.danger)),
              ],
              if (_searched && !_searching && _error == null) ...[
                const SizedBox(height: 14),
                if (_results.isEmpty)
                  const Text('No matching communities found.', style: TextStyle(fontSize: 12.5, color: AppColors.muted))
                else
                  ..._results.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.name, style: AppFonts.heading(fontSize: 14, fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text(
                                      [s.area, s.city, s.state].where((v) => v.isNotEmpty).join(', '),
                                      style: const TextStyle(fontSize: 11.5, color: AppColors.muted),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton(
                                onPressed: _entering ? null : () => _enter(s),
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.brand), minimumSize: const Size(0, 36)),
                                child: const Text('Enter', style: TextStyle(color: AppColors.brand, fontSize: 12.5)),
                              ),
                            ],
                          ),
                        ),
                      )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
