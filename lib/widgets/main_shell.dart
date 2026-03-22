import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../screens/home/home_screen.dart';
import '../screens/pet/pet_profile_screen.dart';
import '../screens/clinic/clinic_list_screen.dart';

class MainShell extends StatefulWidget {
  final int initialTab;
  const MainShell({super.key, this.initialTab = 0});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentTab;
  final Set<int> _loadedTabs = {0};

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    _loadedTabs.add(widget.initialTab);
  }

  void _switchTab(int index) {
    // Tab 1 (Map) — open as separate route, not embedded
    if (index == 1) {
      Navigator.pushNamed(context, '/guardian-map');
      return;
    }
    setState(() {
      _currentTab = index;
      _loadedTabs.add(index);
    });
  }

  Widget _buildTab(int index) {
    if (!_loadedTabs.contains(index)) {
      return const SizedBox.shrink();
    }
    switch (index) {
      case 0: return const HomeScreen();
      case 1: return const SizedBox.shrink(); // Map opens as separate route
      case 2: return const PetProfileScreen();
      case 3: return const ClinicListScreen();
      default: return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentTab != 0) {
          _switchTab(0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentTab,
          children: List.generate(4, (i) => _buildTab(i)),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), offset: const Offset(0, -2), blurRadius: 12)],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navBtn(Icons.home_rounded, 'Trang chủ', 0),
              _navBtn(Icons.location_on_outlined, 'Bản đồ', 1),
              _navBtn(Icons.pets_outlined, 'Thú cưng', 2),
              _navBtn(Icons.medical_services_outlined, 'Phòng khám', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navBtn(IconData icon, String label, int index) {
    final active = _currentTab == index;
    return GestureDetector(
      onTap: () => _switchTab(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? MoewColors.accent.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(MoewRadius.full),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 22, color: active ? MoewColors.accent : MoewColors.textSub),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? MoewColors.accent : MoewColors.textSub)),
        ]),
      ),
    );
  }
}
