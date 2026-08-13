import 'package:flutter/material.dart';
import '../models/property_listing.dart';
import '../models/property_unit.dart';
import '../models/rent_payment.dart';
import '../services/auth_service.dart';
import '../services/property_api.dart';
import '../theme/app_theme.dart';
import '../widgets/amenities_card.dart';
import '../widgets/empty_state_section_card.dart';
import '../widgets/property_photo_gallery.dart';
import '../widgets/quick_actions_section.dart';
import '../widgets/stat_overview_bar.dart';
import 'add_property_complaint_screen.dart';
import 'add_rooms_screen.dart';
import 'add_tenant_screen.dart';
import 'collect_payment_screen.dart';
import 'property_announcements_screen.dart';
import 'property_complaints_screen.dart';
import 'property_units_screen.dart';
import 'tenants_screen.dart';

List<StatOverviewItem> _overviewItems(RentSummary? rent, VacancySummary? vacancy, int? openComplaints, VoidCallback onOpenComplaints) {
  final month = _monthNames[DateTime.now().month - 1];
  return [
    StatOverviewItem(icon: Icons.payments_outlined, value: '₹${rent?.todayCollection ?? 0}', label: "Today's Collection", color: AppColors.success),
    StatOverviewItem(icon: Icons.account_balance_wallet_outlined, value: '₹${rent?.thisMonthCollection ?? 0}', label: '$month Collection', color: AppColors.success),
    StatOverviewItem(icon: Icons.receipt_long_outlined, value: '₹${rent?.thisMonthDues ?? 0}', label: '$month Dues', color: AppColors.amber),
    StatOverviewItem(icon: Icons.pending_actions_outlined, value: '₹${rent?.allTimeDues ?? 0}', label: 'All Time Dues', color: AppColors.amber),
    StatOverviewItem(icon: Icons.king_bed_outlined, value: '${vacancy?.vacantUnits ?? 0}', label: 'Vacant Beds', color: AppColors.brand),
    StatOverviewItem(icon: Icons.single_bed_outlined, value: '${vacancy?.occupiedUnits ?? 0}', label: 'Occupied Beds', color: AppColors.brand),
    StatOverviewItem(icon: Icons.report_problem_outlined, value: '${openComplaints ?? 0}', label: 'Active Complaints', color: AppColors.danger, onTap: onOpenComplaints),
  ];
}

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// Opened when an owner taps one of their properties on the list screen —
/// this property's own at-a-glance dashboard.
class PropertyDashboardScreen extends StatefulWidget {
  final MyPropertyListing listing;

  const PropertyDashboardScreen({super.key, required this.listing});

  @override
  State<PropertyDashboardScreen> createState() => _PropertyDashboardScreenState();
}

class _PropertyDashboardScreenState extends State<PropertyDashboardScreen> {
  AuthUser? _user;
  RentSummary? _rentSummary;
  VacancySummary? _vacancy;
  int? _openComplaints;
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await AuthService.syncCurrentUser();
    final rentSummary = await _loadRentSummary();
    final vacancy = await _loadVacancy();
    final openComplaints = await _loadOpenComplaints();
    if (!mounted) return;
    setState(() {
      _user = user;
      _rentSummary = rentSummary;
      _vacancy = vacancy;
      _openComplaints = openComplaints;
    });
  }

  Future<int?> _loadOpenComplaints() async {
    try {
      return await PropertyApi.fetchOpenComplaintsCount(widget.listing.id);
    } catch (_) {
      return null;
    }
  }

  Future<RentSummary?> _loadRentSummary() async {
    try {
      return await PropertyApi.fetchRentSummary(widget.listing.id);
    } catch (_) {
      return null;
    }
  }

  Future<VacancySummary?> _loadVacancy() async {
    try {
      return await PropertyApi.fetchVacancySummary(widget.listing.id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _openAddTenant() async {
    final tenant = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddTenantScreen(propertyId: widget.listing.id, propertyTitle: widget.listing.title)),
    );
    if (tenant == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${tenant.name} added as a tenant')));
    final rentSummary = await _loadRentSummary();
    if (!mounted) return;
    setState(() => _rentSummary = rentSummary);
  }

  Future<void> _openTenants() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TenantsScreen(propertyId: widget.listing.id)),
    );
  }

  Future<void> _openAnnouncements() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PropertyAnnouncementsScreen(propertyId: widget.listing.id)),
    );
  }

  Future<void> _openComplaintsList() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PropertyComplaintsScreen(propertyId: widget.listing.id, propertyTitle: widget.listing.title)),
    );
    final openComplaints = await _loadOpenComplaints();
    if (!mounted) return;
    setState(() => _openComplaints = openComplaints);
  }

  Future<void> _openAddComplaint() async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddPropertyComplaintScreen(propertyId: widget.listing.id, propertyTitle: widget.listing.title)),
    );
    if (submitted != true || !mounted) return;
    final openComplaints = await _loadOpenComplaints();
    if (!mounted) return;
    setState(() => _openComplaints = openComplaints);
  }

  Future<void> _openCollectPayment() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CollectPaymentScreen(propertyId: widget.listing.id)),
    );
    final rentSummary = await _loadRentSummary();
    if (!mounted) return;
    setState(() => _rentSummary = rentSummary);
  }

  Future<void> _openAddRooms() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddRoomsScreen(propertyId: widget.listing.id)));
    final vacancy = await _loadVacancy();
    if (!mounted) return;
    setState(() => _vacancy = vacancy);
  }

  Future<void> _publishVacancy() async {
    setState(() => _publishing = true);
    try {
      await PropertyApi.publishVacancy(widget.listing.id);
      final vacancy = await _loadVacancy();
      if (!mounted) return;
      setState(() {
        _vacancy = vacancy;
        _publishing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vacancy published')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _publishing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not publish vacancy: $e')));
    }
  }

  // Placeholder quick actions — wire the rest up to real flows as each one
  // is built. More actions to come.
  List<QuickAction> get _quickActions => [
        QuickAction(icon: Icons.person_add_alt_outlined, label: 'Add Tenant', onTap: _openAddTenant),
        QuickAction(icon: Icons.groups_outlined, label: 'Tenants', onTap: _openTenants),
        QuickAction(icon: Icons.report_problem_outlined, label: 'Add Complaint', onTap: _openAddComplaint),
        QuickAction(icon: Icons.request_page_outlined, label: 'Collect Payment', onTap: _openCollectPayment),
        QuickAction(icon: Icons.campaign_outlined, label: 'Send Announcement', onTap: _openAnnouncements),
        const QuickAction(icon: Icons.trending_down_outlined, label: 'Add Expense'),
        const QuickAction(icon: Icons.request_quote_outlined, label: 'Add Dues'),
      ];

  @override
  Widget build(BuildContext context) {
    final firstName = (_user?.name ?? '').trim().split(RegExp(r'\s+')).first;
    final hasUnits = (_vacancy?.totalUnits ?? 0) > 0;

    return Scaffold(
      appBar: AppBar(title: Text(widget.listing.title)),
      body: ListView(
        children: [
          if (widget.listing.images.isNotEmpty || widget.listing.videoUrl != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: PropertyPhotoGallery(images: widget.listing.images, videoUrl: widget.listing.videoUrl),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstName.isEmpty ? 'Hello,' : 'Hello, $firstName',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text('Welcome Back!', style: AppFonts.heading(fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          StatOverviewBar(items: _overviewItems(_rentSummary, _vacancy, _openComplaints, _openComplaintsList)),
          QuickActionsSection(actions: _quickActions),
          hasUnits ? _buildOccupancyCard() : _buildEmptyOccupancyCard(),
          if (widget.listing.amenities.isNotEmpty) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AmenitiesCard(amenities: widget.listing.amenities),
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEmptyOccupancyCard() {
    return EmptyStateSectionCard(
      title: 'Occupancy',
      icon: Icons.bed_outlined,
      description: 'How full is your property? Add your rooms to find out.',
      buttonLabel: 'Add Room & Beds',
      onButtonTap: _openAddRooms,
    );
  }

  Widget _buildOccupancyCard() {
    final vacancy = _vacancy!;
    final publishedAt = vacancy.vacancyPublishedAt;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Occupancy', style: AppFonts.heading(fontSize: 15.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              '${vacancy.totalUnits} unit${vacancy.totalUnits > 1 ? 's' : ''} across ${vacancy.totalFloors} floor${vacancy.totalFloors > 1 ? 's' : ''} · ${vacancy.vacantUnits} vacant · ${vacancy.occupiedUnits} occupied',
              style: const TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 4),
            Text(
              publishedAt == null ? 'Vacancy not published yet' : 'Last published ${_formatDate(publishedAt)}',
              style: TextStyle(fontSize: 11.5, color: publishedAt == null ? AppColors.amber : AppColors.success, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => PropertyUnitsScreen(propertyId: widget.listing.id))),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.border)),
                    child: const Text('Manage Rooms', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _publishing ? null : _publishVacancy,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: AppColors.brandOnDark),
                    child: _publishing
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Publish Vacancy', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}
