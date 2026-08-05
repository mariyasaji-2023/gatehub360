import 'package:flutter/material.dart';
import '../models/hostel_listing.dart';
import '../services/auth_service.dart';
import '../services/hostel_api.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import '../widgets/section_hero.dart';
import 'hostel_enquiries_screen.dart';

const _hostelTypes = ['PG', 'Hostel', 'Service Apt', 'Flat'];
const _hostelGenders = ['Men', 'Women', 'Co-ed'];

class MyHostelsScreen extends StatefulWidget {
  const MyHostelsScreen({super.key});

  @override
  State<MyHostelsScreen> createState() => _MyHostelsScreenState();
}

class _MyHostelsScreenState extends State<MyHostelsScreen> {
  List<MyHostelListing> _listings = [];
  int _unreadTotal = 0;
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
      final listings = await HostelApi.fetchMine();
      final unreadTotal = await HostelApi.fetchUnreadEnquiryCount();
      if (!mounted) return;
      setState(() {
        _listings = listings;
        _unreadTotal = unreadTotal;
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

  Future<void> _openEnquiries({String? hostelId, String? hostelTitle}) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => HostelEnquiriesScreen(hostelId: hostelId, hostelTitle: hostelTitle),
    ));
    if (mounted) _load();
  }

  Future<void> _openForm({MyHostelListing? existing}) async {
    final result = await showModalBottomSheet<_HostelFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HostelFormSheet(existing: existing),
    );
    if (result == null) return;

    try {
      if (existing == null) {
        await HostelApi.create(
          type: result.type,
          gender: result.gender,
          title: result.title,
          location: result.location,
          about: result.about,
          contact: result.contact,
          amenities: result.amenities,
          rooms: result.rooms,
          active: result.active,
        );
      } else {
        await HostelApi.update(
          existing.id,
          type: result.type,
          gender: result.gender,
          title: result.title,
          location: result.location,
          about: result.about,
          contact: result.contact,
          amenities: result.amenities,
          rooms: result.rooms,
          active: result.active,
        );
      }
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _confirmDelete(MyHostelListing listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove listing?'),
        content: Text('"${listing.title}" will no longer be visible to tenants.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await HostelApi.delete(listing.id);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My PG & Hostels'),
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  tooltip: 'Enquiries',
                  icon: const Icon(Icons.mail_outline),
                  onPressed: () => _openEnquiries(),
                ),
                if (_unreadTotal > 0)
                  Positioned(top: 8, right: 8, child: _UnreadBadge(count: _unreadTotal)),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add),
          label: const Text('Add Listing'),
          backgroundColor: AppColors.brand,
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              SectionHero(
                titleStart: 'My',
                titleHighlight: 'PG & Hostels',
                accentColor: AppColors.brand,
                child: const Text(
                  'Manage what tenants see when they browse.',
                  style: TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      Padding(
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
                      )
                    else ...[
                      Text('Your Listings (${_listings.length})', style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      if (_listings.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: Text(
                              "You haven't added any listings yet.\nTap \"Add Listing\" to get started.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.6),
                            ),
                          ),
                        ),
                      ..._listings.map((l) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: DarkCard(
                              onTap: () => _openEnquiries(hostelId: l.id, hostelTitle: l.title),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Text(l.emoji, style: const TextStyle(fontSize: 30)),
                                          if (l.unreadEnquiries > 0)
                                            Positioned(top: -4, right: -6, child: _UnreadBadge(count: l.unreadEnquiries)),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(l.title, style: AppFonts.heading(fontSize: 15.5, fontWeight: FontWeight.w700)),
                                            const SizedBox(height: 3),
                                            Text('📍 ${l.location}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                                            const SizedBox(height: 3),
                                            Text(
                                              '₹${l.startingPrice}/mo · ${l.type} · ${l.gender}',
                                              style: const TextStyle(fontSize: 13, color: AppColors.brand, fontWeight: FontWeight.w700),
                                            ),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (v) {
                                          if (v == 'edit') _openForm(existing: l);
                                          if (v == 'delete') _confirmDelete(l);
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(l.about, style: const TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.5)),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(6)),
                                        child: Text('${l.rooms.length} room type(s)', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: (l.active ? AppColors.brand : AppColors.muted).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          l.active ? 'Visible to tenants' : 'Hidden',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: l.active ? AppColors.brand : AppColors.muted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;
  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      constraints: const BoxConstraints(minWidth: 16),
      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(8)),
      child: Text(
        count > 9 ? '9+' : '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _HostelFormResult {
  final String type;
  final String gender;
  final String title;
  final String location;
  final String about;
  final String contact;
  final List<String> amenities;
  final List<HostelRoomOption> rooms;
  final bool active;

  const _HostelFormResult({
    required this.type,
    required this.gender,
    required this.title,
    required this.location,
    required this.about,
    required this.contact,
    required this.amenities,
    required this.rooms,
    required this.active,
  });
}

class _RoomRow {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final availableController = TextEditingController();

  _RoomRow({String name = '', String price = '', String available = ''}) {
    nameController.text = name;
    priceController.text = price;
    availableController.text = available;
  }

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    availableController.dispose();
  }
}

class _HostelFormSheet extends StatefulWidget {
  final MyHostelListing? existing;
  const _HostelFormSheet({this.existing});

  @override
  State<_HostelFormSheet> createState() => _HostelFormSheetState();
}

class _HostelFormSheetState extends State<_HostelFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _type = widget.existing?.type ?? _hostelTypes.first;
  late String _gender = widget.existing?.gender ?? _hostelGenders.first;
  late final _titleController = TextEditingController(text: widget.existing?.title ?? '');
  late final _locationController = TextEditingController(text: widget.existing?.location ?? '');
  late final _aboutController = TextEditingController(text: widget.existing?.about ?? '');
  late final _contactController = TextEditingController(text: widget.existing?.contact ?? '');
  late final _amenitiesController = TextEditingController(text: widget.existing?.amenities.join(', ') ?? '');
  late bool _active = widget.existing?.active ?? true;
  late final List<_RoomRow> _rooms = widget.existing == null
      ? [_RoomRow()]
      : widget.existing!.rooms
          .map((r) => _RoomRow(name: r.name, price: r.price.toString(), available: r.available.toString()))
          .toList();
  String? _roomsError;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _aboutController.dispose();
    _contactController.dispose();
    _amenitiesController.dispose();
    for (final r in _rooms) {
      r.dispose();
    }
    super.dispose();
  }

  void _addRoom() => setState(() => _rooms.add(_RoomRow()));

  void _removeRoom(int index) {
    if (_rooms.length == 1) return;
    setState(() {
      _rooms.removeAt(index).dispose();
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final rooms = <HostelRoomOption>[];
    for (final r in _rooms) {
      final name = r.nameController.text.trim();
      final price = num.tryParse(r.priceController.text.trim());
      final available = int.tryParse(r.availableController.text.trim());
      if (name.isEmpty || price == null || available == null) {
        setState(() => _roomsError = 'Fill in every room field with valid numbers');
        return;
      }
      rooms.add(HostelRoomOption(name: name, price: price, available: available));
    }
    setState(() => _roomsError = null);

    final amenities = _amenitiesController.text.split(',').map((a) => a.trim()).where((a) => a.isNotEmpty).toList();

    Navigator.of(context).pop(_HostelFormResult(
      type: _type,
      gender: _gender,
      title: _titleController.text.trim(),
      location: _locationController.text.trim(),
      about: _aboutController.text.trim(),
      contact: _contactController.text.trim(),
      amenities: amenities,
      rooms: rooms,
      active: _active,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
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
                Text(isEditing ? 'Edit Listing' : 'Add PG/Hostel', style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _type,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: _hostelTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) => setState(() => _type = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: const InputDecoration(labelText: 'For'),
                        items: _hostelGenders.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (v) => setState(() => _gender = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title (e.g. Sri Rama PG for Men)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location (area, city)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _aboutController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'About this place'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _contactController,
                  decoration: const InputDecoration(labelText: 'Contact number'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _amenitiesController,
                  decoration: const InputDecoration(labelText: 'Amenities (comma separated, e.g. WiFi, Food, AC)'),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Room Options', style: AppFonts.heading(fontSize: 14.5, fontWeight: FontWeight.w700)),
                    TextButton.icon(
                      onPressed: _addRoom,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Room'),
                    ),
                  ],
                ),
                if (_roomsError != null) ...[
                  const SizedBox(height: 4),
                  Text(_roomsError!, style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
                ],
                const SizedBox(height: 8),
                for (int i = 0; i < _rooms.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Room ${i + 1}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
                              ),
                              if (_rooms.length > 1)
                                InkWell(
                                  onTap: () => _removeRoom(i),
                                  child: const Icon(Icons.close, size: 18, color: AppColors.muted),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _rooms[i].nameController,
                            decoration: const InputDecoration(labelText: 'Room name (e.g. Single AC)'),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _rooms[i].priceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Price/month'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _rooms[i].availableController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Beds available'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                  activeColor: AppColors.brand,
                  title: const Text('Visible to tenants', style: TextStyle(fontSize: 13.5)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: AppColors.brandOnDark),
                    child: Text(isEditing ? 'Save Changes' : 'Add Listing'),
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
