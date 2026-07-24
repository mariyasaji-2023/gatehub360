import 'package:flutter/material.dart';

import '../models/society_join_request.dart';
import '../services/auth_service.dart';
import '../services/society_api.dart';
import '../theme/app_theme.dart';
import '../widgets/dark_card.dart';

class SocietyJoinRequestsScreen extends StatefulWidget {
  const SocietyJoinRequestsScreen({super.key});

  @override
  State<SocietyJoinRequestsScreen> createState() => _SocietyJoinRequestsScreenState();
}

class _SocietyJoinRequestsScreenState extends State<SocietyJoinRequestsScreen> {
  List<SocietyJoinRequest> _requests = [];
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
      final requests = await SocietyApi.fetchJoinRequests();
      if (!mounted) return;
      setState(() {
        _requests = requests;
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

  Future<void> _respond(SocietyJoinRequest request, bool approve) async {
    try {
      await SocietyApi.respondToJoinRequest(request.id, approve: approve);
      await _load();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Requests')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? ListView(
                      children: [
                        const SizedBox(height: 40),
                        Center(
                          child: Column(
                            children: [
                              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, color: AppColors.muted)),
                              const SizedBox(height: 12),
                              OutlinedButton(onPressed: _load, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      children: [
                        if (_requests.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text('No pending requests.', style: TextStyle(fontSize: 13.5, color: AppColors.muted)),
                            ),
                          ),
                        ..._requests.map((r) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: DarkCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.requesterName ?? 'Unknown',
                                      style: AppFonts.heading(fontSize: 15, fontWeight: FontWeight.w700),
                                    ),
                                    if (r.requesterPhone?.isNotEmpty == true) ...[
                                      const SizedBox(height: 6),
                                      Text(r.requesterPhone!, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                                    ],
                                    const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () => _respond(r, false),
                                            style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger), foregroundColor: AppColors.danger),
                                            child: const Text('Reject'),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => _respond(r, true),
                                            child: const Text('Approve'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            )),
                      ],
                    ),
        ),
      ),
    );
  }
}
