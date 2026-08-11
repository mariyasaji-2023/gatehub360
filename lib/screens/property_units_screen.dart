import 'package:flutter/material.dart';
import '../models/property_unit.dart';
import '../services/property_api.dart';
import '../theme/app_theme.dart';
import '../widgets/pill_badge.dart';

/// Every individually trackable unit for a property, grouped by floor, with
/// a tap-to-flip vacant/occupied toggle - the "Update Vacancy Status" and
/// "View Total/Occupied/Vacant Units" part of vacancy management.
class PropertyUnitsScreen extends StatefulWidget {
  final String propertyId;

  const PropertyUnitsScreen({super.key, required this.propertyId});

  @override
  State<PropertyUnitsScreen> createState() => _PropertyUnitsScreenState();
}

class _PropertyUnitsScreenState extends State<PropertyUnitsScreen> {
  List<PropertyUnit>? _units;
  bool _loading = true;
  String? _error;
  final Set<String> _updating = {};

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
      final units = await PropertyApi.fetchUnits(widget.propertyId);
      if (!mounted) return;
      setState(() {
        _units = units;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load rooms. Pull to retry.';
        _loading = false;
      });
    }
  }

  Future<void> _toggleStatus(PropertyUnit unit) async {
    final nextStatus = unit.isOccupied ? 'vacant' : 'occupied';
    setState(() => _updating.add(unit.id));
    try {
      final updated = await PropertyApi.updateUnitStatus(widget.propertyId, unit.id, nextStatus);
      if (!mounted) return;
      setState(() {
        _units = _units!.map((u) => u.id == updated.id ? updated : u).toList();
        _updating.remove(unit.id);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _updating.remove(unit.id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update status: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rooms & Beds')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : (_units?.isEmpty ?? true)
                  ? _buildEmpty()
                  : RefreshIndicator(onRefresh: _load, child: _buildList(_units!)),
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

  Widget _buildEmpty() {
    return const Center(
      child: Text('No rooms added yet', style: TextStyle(color: AppColors.muted)),
    );
  }

  Widget _buildList(List<PropertyUnit> units) {
    final byFloor = <String, List<PropertyUnit>>{};
    for (final unit in units) {
      byFloor.putIfAbsent(unit.floor, () => []).add(unit);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        for (final floor in byFloor.keys) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 4),
            child: Text(floor, style: AppFonts.heading(fontSize: 15.5, fontWeight: FontWeight.w700)),
          ),
          for (final unit in byFloor[floor]!) _UnitTile(unit: unit, updating: _updating.contains(unit.id), onTap: () => _toggleStatus(unit)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _UnitTile extends StatelessWidget {
  final PropertyUnit unit;
  final bool updating;
  final VoidCallback onTap;

  const _UnitTile({required this.unit, required this.updating, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = unit.isOccupied ? AppColors.danger : AppColors.success;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(unit.label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${unit.beds} bed${unit.beds > 1 ? 's' : ''}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          PillBadge(label: unit.isOccupied ? 'Occupied' : 'Vacant', color: color),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            height: 36,
            child: updating
                ? const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    onPressed: onTap,
                    tooltip: unit.isOccupied ? 'Mark vacant' : 'Mark occupied',
                    icon: Icon(unit.isOccupied ? Icons.person_remove_outlined : Icons.person_add_outlined, color: AppColors.brand),
                  ),
          ),
        ],
      ),
    );
  }
}
