import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/property_listing.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_api.dart';
import '../services/property_api.dart';
import '../theme/app_theme.dart';
import 'dark_card.dart';
import 'property_video_player.dart';

const _propertyTypes = ['Apartment', 'Villa', 'Plot', 'Commercial'];
const _propertyModes = ['Buy', 'Rent', 'Sell', 'Commercial'];
const _propertyBhks = ['1 BHK', '2 BHK', '3 BHK', '4 BHK', 'N/A'];

// Keep in sync with Property.AMENITIES in backend/models/Property.js.
const _propertyAmenities = [
  'Parking',
  'Lift',
  'Power Backup',
  '24x7 Security',
  'CCTV',
  'Gym',
  'Swimming Pool',
  'Club House',
  "Children's Play Area",
  'Park/Garden',
  'Water Supply',
  'Gas Pipeline',
  'Intercom',
  'Fire Safety',
  'Furnished',
];

// Keep in sync with MAX_IMAGES in backend/routes/properties.js.
const _maxPropertyImages = 6;

// Keep in sync with MAX_AMENITIES/MAX_AMENITY_LENGTH in backend/routes/properties.js.
const _maxAmenities = 25;
const _maxAmenityLength = 40;

// A walkthrough clip doesn't need to be long, and keeping it short keeps
// the (uncompressed) upload fast - see the comment in _pickVideo below.
const _maxVideoDuration = Duration(seconds: 60);

/// Opens the Add/Edit Property bottom sheet and, if saved, performs the
/// create/update API call (showing a "Saving…" overlay while it's in
/// flight). Returns true if the property was created/updated successfully -
/// callers should refresh their data in that case, false on cancel/failure.
///
/// Used both from the My Properties list (Add/Edit) and the property
/// dashboard's "Property Details" shortcuts, so both entry points share one
/// form and one save path.
Future<bool> openPropertyEditForm(BuildContext context, {MyPropertyListing? existing}) async {
  final result = await showModalBottomSheet<_PropertyFormResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PropertyFormSheet(existing: existing),
  );
  if (result == null || !context.mounted) return false;

  // The form sheet above already closed, so without this the screen would
  // just sit there looking unchanged while the (possibly multi-MB, with
  // photos) save request is in flight - easy to mistake for "my edit
  // didn't save" when it's really just still uploading.
  _showSavingOverlay(context);
  try {
    if (existing == null) {
      await PropertyApi.create(
        type: result.type,
        mode: result.mode,
        title: result.title,
        location: result.location,
        address: result.address,
        price: result.price,
        rentAmount: result.rentAmount,
        deposit: result.deposit,
        bhk: result.bhk,
        sqft: result.sqft,
        about: result.about,
        contact: result.contact,
        active: result.active,
        images: result.images,
        videoUrl: result.videoUrl,
        amenities: result.amenities,
      );
    } else {
      await PropertyApi.update(
        existing.id,
        type: result.type,
        mode: result.mode,
        title: result.title,
        location: result.location,
        address: result.address,
        price: result.price,
        rentAmount: result.rentAmount,
        deposit: result.deposit,
        bhk: result.bhk,
        sqft: result.sqft,
        about: result.about,
        contact: result.contact,
        active: result.active,
        images: result.images,
        videoUrl: result.videoUrl,
        updateVideoUrl: true,
        amenities: result.amenities,
      );
    }
    return true;
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
    return false;
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}

void _showSavingOverlay(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(
        child: DarkCard(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
              SizedBox(width: 16),
              Text('Saving…', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PropertyFormResult {
  final String type;
  final String mode;
  final String title;
  final String location;
  final String address;
  final String price;
  final String rentAmount;
  final String deposit;
  final String bhk;
  final String sqft;
  final String about;
  final String contact;
  final bool active;
  final List<String> images;
  final String? videoUrl;
  final List<String> amenities;

  const _PropertyFormResult({
    required this.type,
    required this.mode,
    required this.title,
    required this.location,
    required this.address,
    required this.price,
    required this.rentAmount,
    required this.deposit,
    required this.bhk,
    required this.sqft,
    required this.about,
    required this.contact,
    required this.active,
    required this.images,
    required this.videoUrl,
    required this.amenities,
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
  late final _addressController = TextEditingController(text: widget.existing?.address ?? '');
  late final _priceController = TextEditingController(text: widget.existing?.price ?? '');
  late final _rentAmountController = TextEditingController(text: widget.existing?.rentAmount ?? '');
  late final _depositController = TextEditingController(text: widget.existing?.deposit ?? '');
  late final _sqftController = TextEditingController(text: widget.existing?.sqft ?? '');
  late final _aboutController = TextEditingController(text: widget.existing?.about ?? '');
  late final _contactController = TextEditingController(text: widget.existing?.contact ?? '');
  late bool _active = widget.existing?.active ?? true;
  late List<String> _images = List<String>.from(widget.existing?.images ?? const []);
  bool _pickingImages = false;
  late String? _videoUrl = widget.existing?.videoUrl;
  // null = not uploading; 0-1 = in-progress upload fraction.
  double? _videoUploadProgress;
  late final Set<String> _amenities = Set<String>.from(widget.existing?.amenities ?? const []);

  void _toggleAmenity(String amenity) {
    setState(() {
      if (!_amenities.remove(amenity)) _amenities.add(amenity);
    });
  }

  // Lets an owner add something not in the preset chip list - matches
  // MAX_AMENITIES/MAX_AMENITY_LENGTH in backend/routes/properties.js.
  Future<void> _addCustomAmenity() async {
    if (_amenities.length >= _maxAmenities) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('You can add up to $_maxAmenities amenities')));
      return;
    }
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add an amenity'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: _maxAmenityLength,
          decoration: const InputDecoration(labelText: 'e.g. Rooftop Terrace'),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(controller.text), child: const Text('Add')),
        ],
      ),
    );
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return;
    setState(() => _amenities.add(trimmed));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _rentAmountController.dispose();
    _depositController.dispose();
    _sqftController.dispose();
    _aboutController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    // Uploads go straight from the phone at full quality - there's no
    // on-device compression - so a longer clip can take a long time
    // (or a lot of mobile data) to send. Capping the length keeps a
    // "walkthrough" clip quick to pick, upload, and load for viewers too.
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery, maxDuration: _maxVideoDuration);
    if (picked == null) return;

    setState(() => _videoUploadProgress = 0);
    try {
      final url = await CloudinaryApi.uploadVideo(
        File(picked.path),
        onProgress: (p) {
          if (mounted) setState(() => _videoUploadProgress = p);
        },
      );
      if (!mounted) return;
      setState(() => _videoUrl = url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not upload video: $e')));
    } finally {
      if (mounted) setState(() => _videoUploadProgress = null);
    }
  }

  void _removeVideo() => setState(() => _videoUrl = null);

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
      address: _addressController.text.trim(),
      price: _priceController.text.trim(),
      rentAmount: _rentAmountController.text.trim(),
      deposit: _depositController.text.trim(),
      bhk: _bhk,
      sqft: _sqftController.text.trim(),
      about: _aboutController.text.trim(),
      contact: _contactController.text.trim(),
      active: _active,
      images: _images,
      videoUrl: _videoUrl,
      amenities: _amenities.toList(),
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
                Text('Video (optional)', style: AppFonts.heading(fontSize: 13.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _VideoPicker(
                  videoUrl: _videoUrl,
                  uploadProgress: _videoUploadProgress,
                  onAdd: _pickVideo,
                  onRemove: _removeVideo,
                ),
                const SizedBox(height: 14),
                Text('Amenities', style: AppFonts.heading(fontSize: 13.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final amenity in _propertyAmenities)
                      FilterChip(
                        label: Text(amenity),
                        selected: _amenities.contains(amenity),
                        onSelected: (_) => _toggleAmenity(amenity),
                        labelStyle: TextStyle(fontSize: 12.5, color: _amenities.contains(amenity) ? AppColors.brandOnDark : AppColors.muted),
                        selectedColor: AppColors.brand,
                        backgroundColor: AppColors.surfaceAlt,
                        side: BorderSide(color: _amenities.contains(amenity) ? AppColors.brand : AppColors.border),
                        showCheckmark: false,
                      ),
                    // Custom amenities the owner typed in, not part of the preset list above.
                    for (final amenity in _amenities.where((a) => !_propertyAmenities.contains(a)))
                      InputChip(
                        label: Text(amenity),
                        onDeleted: () => _toggleAmenity(amenity),
                        labelStyle: const TextStyle(fontSize: 12.5, color: AppColors.brandOnDark),
                        backgroundColor: AppColors.brand,
                        deleteIconColor: AppColors.brandOnDark,
                        side: BorderSide.none,
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16, color: AppColors.muted),
                      label: const Text('Other'),
                      onPressed: _addCustomAmenity,
                      labelStyle: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                      backgroundColor: AppColors.surfaceAlt,
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location (area, city)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Full Address (optional — used for maps)'),
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
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _rentAmountController,
                        decoration: const InputDecoration(labelText: 'Rent Amount (optional)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _depositController,
                        decoration: const InputDecoration(labelText: 'Deposit (optional)'),
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

/// Add/preview/remove the property's single walkthrough video, used inside
/// the Add/Edit Property form. Upload itself (picking -> Cloudinary) is
/// driven by the parent; this just reflects whatever state it's given.
class _VideoPicker extends StatelessWidget {
  final String? videoUrl;
  // null = not uploading; 0-1 = in-progress upload fraction.
  final double? uploadProgress;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _VideoPicker({
    required this.videoUrl,
    required this.uploadProgress,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final progress = uploadProgress;
    if (progress != null) {
      return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          color: AppColors.surfaceAlt,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, value: progress > 0 ? progress : null),
            ),
            const SizedBox(width: 12),
            Text('Uploading video… ${(progress * 100).round()}%', style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          ],
        ),
      );
    }

    final url = videoUrl;
    if (url == null) {
      return OutlinedButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.videocam_outlined, size: 18),
        label: Text('Add a walkthrough video (up to ${_maxVideoDuration.inSeconds}s)'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PropertyVideoPlayer(videoUrl: url, size: 110),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Replace'),
            ),
            TextButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
              label: const Text('Remove', style: TextStyle(color: AppColors.danger)),
            ),
          ],
        ),
      ],
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
