import 'package:flutter/material.dart';
import '../models/property_unit.dart';
import '../services/property_api.dart';
import '../theme/app_theme.dart';
import 'add_floors_sheet.dart';
import 'add_units_screen.dart';
import 'property_units_screen.dart';

/// Opened from the property dashboard's "Add Room & Beds" button. Floors and
/// units are persisted on the backend, so this loads the current state on
/// open rather than starting empty every time.
class AddRoomsScreen extends StatefulWidget {
  final String propertyId;

  const AddRoomsScreen({super.key, required this.propertyId});

  @override
  State<AddRoomsScreen> createState() => _AddRoomsScreenState();
}

class _AddRoomsScreenState extends State<AddRoomsScreen> {
  VacancySummary? _summary;
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
      final summary = await PropertyApi.fetchVacancySummary(widget.propertyId);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load floors. Pull to retry.';
        _loading = false;
      });
    }
  }

  Future<void> _addFloors() async {
    final selected = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddFloorsSheet(),
    );
    if (selected == null || selected.isEmpty) return;
    try {
      await PropertyApi.addFloors(widget.propertyId, selected);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not add floor: $e')));
    }
  }

  Future<void> _addUnits(String floor) async {
    final submission = await Navigator.of(context).push<UnitSubmission>(
      MaterialPageRoute(builder: (_) => AddUnitsScreen(floor: floor)),
    );
    if (submission == null) return;
    try {
      await PropertyApi.addUnits(widget.propertyId, floor: floor, rows: submission.rows);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not add units: $e')));
    }
  }

  void _goToRooms() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PropertyUnitsScreen(propertyId: widget.propertyId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final floors = _summary?.floors ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('Add Multiple Rooms')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : floors.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(onRefresh: _load, child: _buildFloorsOverview(floors)),
      bottomNavigationBar: (!_loading && _error == null && floors.isNotEmpty) ? _buildBottomBar() : null,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: AppColors.surfaceAlt, shape: BoxShape.circle),
              child: const Icon(Icons.apartment_outlined, size: 44, color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            Text('No Floors Added', style: AppFonts.heading(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const Text(
              'Start by adding your first floor to manage units and rooms',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addFloors,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: AppColors.brandOnDark),
                child: const Text('Add Your First Floor'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorsOverview(List<FloorVacancy> floors) {
    final filledFloors = floors.where((f) => f.totalUnits > 0).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.brand, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.apartment, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Property at a Glance',
                      style: AppFonts.heading(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppColors.brand),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Easily add, view, and manage every floor and unit.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _FloorStatTile(value: '${floors.length}', label: 'Total Floors', color: AppColors.brand)),
            const SizedBox(width: 10),
            Expanded(child: _FloorStatTile(value: '$filledFloors', label: 'Floors Set Up', color: AppColors.success)),
            const SizedBox(width: 10),
            Expanded(child: _FloorStatTile(value: '${floors.length - filledFloors}', label: 'Floors Pending', color: AppColors.amber)),
          ],
        ),
        const SizedBox(height: 16),
        ...floors.map((floor) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _FloorCard(
                floorVacancy: floor,
                onAddUnits: () => _addUnits(floor.floor),
              ),
            )),
      ],
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _goToRooms,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('👍 Go to Rooms', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _addFloors,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Add Floor', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloorStatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _FloorStatTile({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(value, style: AppFonts.heading(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _FloorCard extends StatelessWidget {
  final FloorVacancy floorVacancy;
  final VoidCallback onAddUnits;

  const _FloorCard({required this.floorVacancy, required this.onAddUnits});

  @override
  Widget build(BuildContext context) {
    final hasUnits = floorVacancy.totalUnits > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(12)),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.border, width: 2)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(floorVacancy.floor, style: AppFonts.heading(fontSize: 15.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      hasUnits
                          ? '${floorVacancy.totalUnits} unit${floorVacancy.totalUnits > 1 ? 's' : ''} · ${floorVacancy.totalBeds} bed${floorVacancy.totalBeds > 1 ? 's' : ''} · ${floorVacancy.vacantUnits} vacant'
                          : 'No units added',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!hasUnits) ...[
            const SizedBox(height: 20),
            const Icon(Icons.home_work_outlined, size: 44, color: AppColors.muted),
            const SizedBox(height: 14),
          ] else
            const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onAddUnits,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.brand),
              foregroundColor: AppColors.brand,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: Text(hasUnits ? 'Add More Units' : 'Add Units', style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
