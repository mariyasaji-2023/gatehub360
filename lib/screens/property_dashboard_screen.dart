import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
import 'maintenance_screen.dart';
import 'property_announcements_screen.dart';
import 'property_complaints_screen.dart';
import 'property_units_screen.dart';
import 'property_visitors_screen.dart';
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
  // True only for the initial load - without it, _vacancy being null (not
  // fetched yet) looks identical to "no rooms added", so the empty-state
  // "Add Room & Beds" card would flash briefly before the real data arrives.
  bool _loadingVacancy = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // These 4 calls are independent of each other, so firing them together
    // and waiting on the slowest one beats waiting on all four back-to-back.
    final results = await Future.wait([
      AuthService.syncCurrentUser(),
      _loadRentSummary(),
      _loadVacancy(),
      _loadOpenComplaints(),
    ]);
    final user = results[0] as AuthUser?;
    final rentSummary = results[1] as RentSummary?;
    final vacancy = results[2] as VacancySummary?;
    final openComplaints = results[3] as int?;
    if (!mounted) return;
    setState(() {
      _user = user;
      _rentSummary = rentSummary;
      _vacancy = vacancy;
      _openComplaints = openComplaints;
      _loadingVacancy = false;
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

  Future<void> _openMaintenance() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MaintenanceScreen(propertyId: widget.listing.id)),
    );
  }

  Future<void> _openAddRooms() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddRoomsScreen(propertyId: widget.listing.id)));
    final vacancy = await _loadVacancy();
    if (!mounted) return;
    setState(() => _vacancy = vacancy);
  }

  // Opens the property's address in Google Maps - just a text search, since
  // the app only stores a free-text address, not coordinates. Prefers the
  // detailed `address` field when the owner filled it in; falls back to the
  // coarser `location` (area/city) for properties that don't have one yet.
  Future<void> _openAddress() async {
    final query = widget.listing.address.isNotEmpty ? widget.listing.address : widget.listing.location;
    final uri = Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': query});
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open Google Maps')));
    }
  }

  // Shows the property's amenities in a bottom sheet - used to be a card
  // permanently taking up space at the bottom of the dashboard; now tucked
  // behind this Quick Action instead.
  void _showAmenities() {
    if (widget.listing.amenities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No amenities added yet — edit the property to add some.')),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
              AmenitiesCard(amenities: widget.listing.amenities),
            ],
          ),
        ),
      ),
    );
  }

  // Placeholder quick actions — wire the rest up to real flows as each one
  // is built. More actions to come.
  List<QuickAction> get _quickActions => [
        QuickAction(icon: Icons.person_add_alt_outlined, label: 'Add Tenant', onTap: _openAddTenant),
        QuickAction(icon: Icons.groups_outlined, label: 'Tenants', onTap: _openTenants),
        QuickAction(icon: Icons.report_problem_outlined, label: 'Add Complaint', onTap: _openAddComplaint),
        QuickAction(icon: Icons.request_page_outlined, label: 'Collect Payment', onTap: _openCollectPayment),
        QuickAction(icon: Icons.home_repair_service_outlined, label: 'Maintenance', onTap: _openMaintenance),
        QuickAction(icon: Icons.campaign_outlined, label: 'Send Announcement', onTap: _openAnnouncements),
        QuickAction(icon: Icons.map_outlined, label: 'Property Address', onTap: _openAddress),
        QuickAction(icon: Icons.check_circle_outline, label: 'Amenities', onTap: _showAmenities),
        QuickAction(
          icon: Icons.badge_outlined,
          label: 'Visitors',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PropertyVisitorsScreen(propertyId: widget.listing.id))),
        ),
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
          _loadingVacancy
              ? _buildVacancyLoadingCard()
              : (hasUnits ? _buildVacancyManagementCard() : _buildEmptyVacancyCard()),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEmptyVacancyCard() {
    return EmptyStateSectionCard(
      title: 'Vacancy Management',
      icon: Icons.bed_outlined,
      description: 'How full is your property? Add your rooms to find out.',
      buttonLabel: 'Add Room & Beds',
      onButtonTap: _openAddRooms,
    );
  }

  Widget _buildVacancyLoadingCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
      ),
    );
  }

  Widget _buildVacancyManagementCard() {
    final vacancy = _vacancy!;
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
            Row(
              children: [
                Expanded(child: Text('Vacancy Management', style: AppFonts.heading(fontSize: 15.5, fontWeight: FontWeight.w700))),
                IconButton(
                  onPressed: _openAddRooms,
                  tooltip: 'Add more rooms',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.brand),
                ),
              ],
            ),
            Text(
              '${vacancy.totalUnits} unit${vacancy.totalUnits == 1 ? '' : 's'} across ${vacancy.totalFloors} floor${vacancy.totalFloors == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _VacancyStat(icon: Icons.apartment_outlined, value: vacancy.totalUnits, label: 'Total Units', color: AppColors.brand)),
                const SizedBox(width: 10),
                Expanded(child: _VacancyStat(icon: Icons.event_busy_outlined, value: vacancy.occupiedUnits, label: 'Occupied', color: AppColors.amber)),
                const SizedBox(width: 10),
                Expanded(child: _VacancyStat(icon: Icons.event_available_outlined, value: vacancy.vacantUnits, label: 'Vacant', color: AppColors.success)),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => PropertyUnitsScreen(propertyId: widget.listing.id)))
                    .then((_) async {
                  final vacancy = await _loadVacancy();
                  if (!mounted) return;
                  setState(() => _vacancy = vacancy);
                }),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: AppColors.brandOnDark),
                child: const Text('Update Vacancy Status', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One of the three at-a-glance figures (Total/Occupied/Vacant) inside the
/// Vacancy Management card.
class _VacancyStat extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const _VacancyStat({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text('$value', style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
