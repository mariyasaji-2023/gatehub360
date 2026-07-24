import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'hostel_list_screen.dart';
import 'my_services_screen.dart';
import 'profile_screen.dart';
import 'property_list_screen.dart';
import 'provider_bookings_screen.dart';
import 'services_list_screen.dart';
import 'society_screen.dart';

class _Tab {
  final Widget page;
  final BottomNavigationBarItem item;

  const _Tab({required this.page, required this.item});
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  AuthUser? _user;
  bool _loading = true;

  void _goTo(int index) => setState(() => _index = index);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = await AuthService.syncCurrentUser();
      if (!mounted) return;
      setState(() {
        _user = user;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<_Tab> _tabsForRole(UserRole? role) {
    if (role == UserRole.serviceProvider) {
      return const [
        _Tab(
          page: MyServicesScreen(),
          item: BottomNavigationBarItem(
            icon: Icon(Icons.handyman_outlined),
            activeIcon: Icon(Icons.handyman),
            label: 'My Services',
          ),
        ),
        _Tab(
          page: ProviderBookingsScreen(),
          item: BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Bookings',
          ),
        ),
        _Tab(
          page: ProfileScreen(),
          item: BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ),
      ];
    }

    final society = const _Tab(
      page: SocietyScreen(),
      item: BottomNavigationBarItem(
        icon: Icon(Icons.apartment_outlined),
        activeIcon: Icon(Icons.apartment),
        label: 'Society',
      ),
    );
    final services = const _Tab(
      page: ServicesListScreen(),
      item: BottomNavigationBarItem(
        icon: Icon(Icons.handyman_outlined),
        activeIcon: Icon(Icons.handyman),
        label: 'Services',
      ),
    );
    final profile = const _Tab(
      page: ProfileScreen(),
      item: BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
    );

    if (role == UserRole.apartmentAssociation) {
      return [society, services, profile];
    }

    return [
      society,
      services,
      _Tab(
        page: HostelListScreen(),
        item: BottomNavigationBarItem(
          icon: Icon(Icons.hotel_outlined),
          activeIcon: Icon(Icons.hotel),
          label: 'PG & Hostels',
        ),
      ),
      _Tab(
        page: PropertyListScreen(),
        item: BottomNavigationBarItem(
          icon: Icon(Icons.villa_outlined),
          activeIcon: Icon(Icons.villa),
          label: 'Property',
        ),
      ),
      profile,
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tabs = _tabsForRole(_user?.role);
    final index = _index.clamp(0, tabs.length - 1);

    return Scaffold(
      body: IndexedStack(index: index, children: [for (final tab in tabs) tab.page]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: _goTo,
        type: BottomNavigationBarType.fixed,
        items: [for (final tab in tabs) tab.item],
      ),
    );
  }
}
