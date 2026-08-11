import 'package:flutter/material.dart';
import '../data/listings_data.dart';
import '../models/service_offering.dart';
import '../services/auth_service.dart';
import '../services/services_api.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import '../widgets/home_greeting_header.dart';
import '../widgets/section_hero.dart';
import 'profile_screen.dart';

class MyServicesScreen extends StatefulWidget {
  const MyServicesScreen({super.key});

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> {
  List<MyServiceListing> _listings = [];
  AuthUser? _user;
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
      final listings = await ServicesApi.fetchMine();
      if (!mounted) return;
      setState(() {
        _user = user;
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

  Future<void> _openForm({MyServiceListing? existing}) async {
    final takenSlugs = _listings.where((l) => l.id != existing?.id).map((l) => l.categorySlug).toSet();
    final result = await showModalBottomSheet<({String categorySlug, String price, String desc, bool active})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServiceFormSheet(existing: existing, takenSlugs: takenSlugs),
    );
    if (result == null) return;

    try {
      if (existing == null) {
        await ServicesApi.create(categorySlug: result.categorySlug, price: result.price, desc: result.desc, active: result.active);
      } else {
        await ServicesApi.update(existing.id, price: result.price, desc: result.desc, active: result.active);
      }
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _confirmDelete(MyServiceListing listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove service?'),
        content: Text('"${listing.name}" will no longer be visible to customers.'),
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
      await ServicesApi.delete(listing.id);
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
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add),
          label: const Text('Add Service'),
          backgroundColor: AppColors.brand,
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              HomeGreetingHeader(
                name: _user?.name,
                photoUrl: _user?.photoURL,
                onBellTap: null,
                onAvatarTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
              ),
              SectionHero(
                titleStart: 'My',
                titleHighlight: 'Services',
                accentColor: AppColors.brand,
                child: Text(
                  'Manage what customers see when they search nearby.',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
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
                              "You haven't added any services yet.\nTap \"Add Service\" to get started.",
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.6),
                            ),
                          ),
                        ),
                      ..._listings.map((l) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: DarkCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(l.emoji, style: const TextStyle(fontSize: 30)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(l.name, style: AppFonts.heading(fontSize: 15.5, fontWeight: FontWeight.w700)),
                                            const SizedBox(height: 3),
                                            Text(l.price, style: const TextStyle(fontSize: 13, color: AppColors.brand, fontWeight: FontWeight.w700)),
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
                                  Text(l.desc, style: const TextStyle(fontSize: 12.5, color: AppColors.muted, height: 1.5)),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (l.active ? AppColors.brand : AppColors.muted).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      l.active ? 'Visible to customers' : 'Hidden',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: l.active ? AppColors.brand : AppColors.muted,
                                      ),
                                    ),
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

class _ServiceFormSheet extends StatefulWidget {
  final MyServiceListing? existing;
  final Set<String> takenSlugs;
  const _ServiceFormSheet({this.existing, required this.takenSlugs});

  @override
  State<_ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends State<_ServiceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late String? _selectedSlug = widget.existing?.categorySlug;
  late final _priceController = TextEditingController(text: widget.existing?.price ?? '');
  late final _descController = TextEditingController(text: widget.existing?.desc ?? '');
  late bool _active = widget.existing?.active ?? true;
  String? _categoryError;

  @override
  void dispose() {
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _pickCategory(ServiceOffering category) {
    setState(() {
      _selectedSlug = category.slug;
      _categoryError = null;
      _priceController.text = category.price;
      _descController.text = category.desc;
    });
  }

  void _save() {
    final slug = _selectedSlug;
    if (slug == null) {
      setState(() => _categoryError = 'Choose a category');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      categorySlug: slug,
      price: _priceController.text.trim(),
      desc: _descController.text.trim(),
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
                Text(isEditing ? 'Edit Service' : 'Add Service', style: AppFonts.heading(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  isEditing ? 'Category can\'t be changed once added.' : 'Choose the category you offer.',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.muted),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: serviceOfferings.map((c) {
                    final selected = c.slug == _selectedSlug;
                    final taken = widget.takenSlugs.contains(c.slug);
                    final disabled = isEditing || taken;
                    return Opacity(
                      opacity: disabled && !selected ? 0.4 : 1,
                      child: ChoiceChip(
                        avatar: Text(c.emoji, style: const TextStyle(fontSize: 14)),
                        label: Text(c.name),
                        selected: selected,
                        onSelected: disabled ? null : (_) => _pickCategory(c),
                        selectedColor: AppColors.brand,
                        backgroundColor: AppColors.surfaceAlt,
                        labelStyle: TextStyle(color: selected ? Colors.white : AppColors.text, fontSize: 12.5),
                        side: BorderSide(color: selected ? AppColors.brand : AppColors.border),
                      ),
                    );
                  }).toList(),
                ),
                if (_categoryError != null) ...[
                  const SizedBox(height: 6),
                  Text(_categoryError!, style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
                ],
                const SizedBox(height: 18),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Starting price (e.g. ₹199)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'What does this include?'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                  activeColor: AppColors.brand,
                  title: const Text('Visible to customers', style: TextStyle(fontSize: 13.5)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: AppColors.brandOnDark),
                    child: Text(isEditing ? 'Save Changes' : 'Add Service'),
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
