import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/property_listing.dart';
import '../services/auth_service.dart';
import '../services/property_api.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import 'property_dashboard_screen.dart';

const _propertyTypes = ['Apartment', 'Villa', 'Plot', 'Commercial'];
const _propertyModes = ['Buy', 'Rent', 'Sell', 'Commercial'];
const _propertyBhks = ['1 BHK', '2 BHK', '3 BHK', '4 BHK', 'N/A'];

// Keep in sync with MAX_IMAGES in backend/routes/properties.js.
const _maxPropertyImages = 6;

class MyPropertiesScreen extends StatefulWidget {
  const MyPropertiesScreen({super.key});

  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen> {
  List<MyPropertyListing> _listings = [];
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
      final listings = await PropertyApi.fetchMine();
      if (!mounted) return;
      setState(() {
        _listings = listings;
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

  Future<void> _openProperty(MyPropertyListing listing) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PropertyDashboardScreen(listing: listing),
    ));
  }

  Future<void> _openForm({MyPropertyListing? existing}) async {
    final result = await showModalBottomSheet<_PropertyFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PropertyFormSheet(existing: existing),
    );
    if (result == null) return;

    try {
      if (existing == null) {
        await PropertyApi.create(
          type: result.type,
          mode: result.mode,
          title: result.title,
          location: result.location,
          price: result.price,
          bhk: result.bhk,
          sqft: result.sqft,
          about: result.about,
          contact: result.contact,
          active: result.active,
          images: result.images,
        );
      } else {
        await PropertyApi.update(
          existing.id,
          type: result.type,
          mode: result.mode,
          title: result.title,
          location: result.location,
          price: result.price,
          bhk: result.bhk,
          sqft: result.sqft,
          about: result.about,
          contact: result.contact,
          active: result.active,
          images: result.images,
        );
      }
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _confirmDelete(MyPropertyListing listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove property?'),
        content: Text('"${listing.title}" will no longer be visible to buyers/tenants.'),
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
      await PropertyApi.delete(listing.id);
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
        appBar: AppBar(title: const Text('My Properties')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add),
          label: const Text('Add Property'),
          backgroundColor: AppColors.brand,
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
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
                        "You haven't added any properties yet.\nTap \"Add Property\" to get started.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.6),
                      ),
                    ),
                  ),
                ..._listings.map((l) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: DarkCard(
                        onTap: () => _openProperty(l),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _PropertyThumb(listing: l),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(l.title, style: AppFonts.heading(fontSize: 15.5, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 3),
                                      Text('📍 ${l.location}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                                      const SizedBox(height: 3),
                                      Text('₹${l.price} · ${l.type} · ${l.mode}', style: const TextStyle(fontSize: 13, color: AppColors.brand, fontWeight: FontWeight.w700)),
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
                                if (l.bhk != 'N/A')
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(6)),
                                    child: Text(l.bhk, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(6)),
                                  child: Text('${l.sqft} sqft', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (l.active ? AppColors.brand : AppColors.muted).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    l.active ? 'Visible to buyers/tenants' : 'Hidden',
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
      ),
    );
  }
}

/// Small preview tile used on the "My Properties" list — the first added
/// photo if there is one, otherwise the type emoji as before.
class _PropertyThumb extends StatelessWidget {
  final MyPropertyListing listing;
  const _PropertyThumb({required this.listing});

  @override
  Widget build(BuildContext context) {
    const size = 44.0;
    if (listing.images.isEmpty) {
      return Text(listing.emoji, style: const TextStyle(fontSize: 30));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.memory(
        base64Decode(listing.images.first),
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _PropertyFormResult {
  final String type;
  final String mode;
  final String title;
  final String location;
  final String price;
  final String bhk;
  final String sqft;
  final String about;
  final String contact;
  final bool active;
  final List<String> images;

  const _PropertyFormResult({
    required this.type,
    required this.mode,
    required this.title,
    required this.location,
    required this.price,
    required this.bhk,
    required this.sqft,
    required this.about,
    required this.contact,
    required this.active,
    required this.images,
  });
}

class _PropertyFormSheet extends StatefulWidget {
  final MyPropertyListing? existing;
  const _PropertyFormSheet({this.existing});

  @override
  State<_PropertyFormSheet> createState() => _PropertyFormSheetState();
}

class _PropertyFormSheetState extends State<_PropertyFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _type = widget.existing?.type ?? _propertyTypes.first;
  late String _mode = widget.existing?.mode ?? _propertyModes.first;
  late String _bhk = widget.existing?.bhk ?? _propertyBhks.first;
  late final _titleController = TextEditingController(text: widget.existing?.title ?? '');
  late final _locationController = TextEditingController(text: widget.existing?.location ?? '');
  late final _priceController = TextEditingController(text: widget.existing?.price ?? '');
  late final _sqftController = TextEditingController(text: widget.existing?.sqft ?? '');
  late final _aboutController = TextEditingController(text: widget.existing?.about ?? '');
  late final _contactController = TextEditingController(text: widget.existing?.contact ?? '');
  late bool _active = widget.existing?.active ?? true;
  late List<String> _images = List<String>.from(widget.existing?.images ?? const []);
  bool _pickingImages = false;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _sqftController.dispose();
    _aboutController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    final remaining = _maxPropertyImages - _images.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You can add up to $_maxPropertyImages photos')));
      return;
    }
    setState(() => _pickingImages = true);
    try {
      final picked = await ImagePicker().pickMultiImage(imageQuality: 70, maxWidth: 1280);
      if (picked.isEmpty) return;
      final encoded = <String>[];
      for (final file in picked.take(remaining)) {
        final bytes = await file.readAsBytes();
        encoded.add(base64Encode(bytes));
      }
      if (!mounted) return;
      setState(() => _images = [..._images, ...encoded]);
      if (picked.length > remaining) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Only added $remaining — max $_maxPropertyImages photos per property')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not add photos: $e')));
    } finally {
      if (mounted) setState(() => _pickingImages = false);
    }
  }

  void _removePhoto(int index) {
    setState(() => _images = [..._images]..removeAt(index));
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_PropertyFormResult(
      type: _type,
      mode: _mode,
      title: _titleController.text.trim(),
      location: _locationController.text.trim(),
      price: _priceController.text.trim(),
      bhk: _bhk,
      sqft: _sqftController.text.trim(),
      about: _aboutController.text.trim(),
      contact: _contactController.text.trim(),
      active: _active,
      images: _images,
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
                Text(isEditing ? 'Edit Property' : 'Add Property', style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _type,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: _propertyTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) => setState(() => _type = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _mode,
                        decoration: const InputDecoration(labelText: 'Mode'),
                        items: _propertyModes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (v) => setState(() => _mode = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title (e.g. Prestige Lakeside Habitat)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                Text('Photos', style: AppFonts.heading(fontSize: 13.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _PhotoPicker(
                  images: _images,
                  loading: _pickingImages,
                  maxImages: _maxPropertyImages,
                  onAdd: _addPhotos,
                  onRemove: _removePhoto,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location (area, city)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'Price (e.g. 85L, 45K/mo)'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _sqftController,
                        decoration: const InputDecoration(labelText: 'Sqft'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _bhk,
                  decoration: const InputDecoration(labelText: 'BHK'),
                  items: _propertyBhks.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                  onChanged: (v) => setState(() => _bhk = v!),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _aboutController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'About this property'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _contactController,
                  decoration: const InputDecoration(labelText: 'Contact number'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                  activeColor: AppColors.brand,
                  title: const Text('Visible to buyers/tenants', style: TextStyle(fontSize: 13.5)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: AppColors.brandOnDark),
                    child: Text(isEditing ? 'Save Changes' : 'Add Property'),
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

/// Row of added-photo thumbnails (each removable) plus an "Add" tile,
/// used inside the Add/Edit Property form.
class _PhotoPicker extends StatelessWidget {
  final List<String> images;
  final bool loading;
  final int maxImages;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  const _PhotoPicker({
    required this.images,
    required this.loading,
    required this.maxImages,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    const tileSize = 76.0;
    return SizedBox(
      height: tileSize,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < images.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(images[i]),
                      width: tileSize,
                      height: tileSize,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: () => onRemove(i),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (images.length < maxImages)
            InkWell(
              onTap: loading ? null : onAdd,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: tileSize,
                height: tileSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  color: AppColors.surfaceAlt,
                ),
                child: loading
                    ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                    : const Icon(Icons.add_a_photo_outlined, color: AppColors.muted),
              ),
            ),
        ],
      ),
    );
  }
}
