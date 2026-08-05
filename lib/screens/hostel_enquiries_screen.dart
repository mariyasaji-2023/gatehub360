import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/hostel_listing.dart';
import '../services/auth_service.dart';
import '../services/hostel_api.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';
import '../widgets/section_hero.dart';

String _formatDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  final period = d.hour < 12 ? 'AM' : 'PM';
  return '${d.day} ${months[d.month - 1]} · $hour12:$minute $period';
}

class HostelEnquiriesScreen extends StatefulWidget {
  /// When set, only enquiries for this listing are shown.
  final String? hostelId;
  final String? hostelTitle;

  const HostelEnquiriesScreen({super.key, this.hostelId, this.hostelTitle});

  @override
  State<HostelEnquiriesScreen> createState() => _HostelEnquiriesScreenState();
}

class _HostelEnquiriesScreenState extends State<HostelEnquiriesScreen> {
  List<HostelEnquiry> _enquiries = [];
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
      final hostelId = widget.hostelId;
      final enquiries =
          hostelId == null ? await HostelApi.fetchEnquiries() : await HostelApi.fetchEnquiriesForHostel(hostelId);
      if (!mounted) return;
      setState(() {
        _enquiries = enquiries;
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

  void _showPhone(HostelEnquiry enquiry) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(enquiry.hostelTitle),
        content: Text(enquiry.clientPhone, style: AppFonts.heading(fontSize: 20, fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: enquiry.clientPhone));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone number copied')));
            },
            child: const Text('Copy'),
          ),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scoped = widget.hostelId != null;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Enquiries')),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              SectionHero(
                titleStart: scoped ? widget.hostelTitle! : 'PG & Hostel',
                titleHighlight: 'Enquiries',
                accentColor: AppColors.brand,
                child: Text(
                  scoped
                      ? 'People who asked to be contacted about this listing.'
                      : 'People who asked to be contacted about one of your listings.',
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
                    else if (_enquiries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'No enquiries yet.',
                            style: const TextStyle(fontSize: 13.5, color: AppColors.muted),
                          ),
                        ),
                      )
                    else
                      ..._enquiries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: DarkCard(
                              onTap: () => _showPhone(e),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.brand.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.person_outline, color: AppColors.brand),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(e.hostelTitle, style: AppFonts.heading(fontSize: 14.5, fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 3),
                                        Text(e.clientPhone, style: const TextStyle(fontSize: 13, color: AppColors.brand, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 3),
                                        Text(_formatDate(e.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: AppColors.muted),
                                ],
                              ),
                            ),
                          )),
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
