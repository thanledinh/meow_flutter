import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/preferences_provider.dart';
import '../screens/home/home_screen.dart';
import '../screens/pet/pet_profile_screen.dart';
import '../screens/post/feed_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/notification/notification_screen.dart';

class MainShell extends StatefulWidget {
  final int initialTab;
  const MainShell({super.key, this.initialTab = 0});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentTab;
  final Set<int> _loadedTabs = {0};
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    _loadedTabs.add(widget.initialTab);
  }

  void _switchTab(int index) {
    // Cuộn lên đầu nếu tap lại trang chủ
    if (index == 0 && _currentTab == 0) {
      return;
    }
    setState(() {
      _currentTab = index;
      _loadedTabs.add(index);
    });
  }

  Widget _buildTab(int index) {
    if (!_loadedTabs.contains(index)) {
      return SizedBox.shrink();
    }
    switch (index) {
      case 0: return HomeScreen(key: _homeKey);
      case 1: return const FeedScreen();       // Mạng xã hội
      case 2: return const PetProfileScreen(); // Trung tâm (nút nổi bật)
      case 3: return const NotificationScreen();
      case 4: return const SettingsScreen(); // Cài đặt
      default: return SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider to rebuild the shell/tabbar instantly when Theme changes.
    context.watch<PreferencesProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentTab != 0) {
          _switchTab(0);
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: MoewColors.background,
        body: IndexedStack(
          index: _currentTab,
          children: List.generate(5, (i) => _buildTab(i)),
        ),
        bottomNavigationBar: _currentTab == 4 ? null : _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                offset: const Offset(0, 4),
                blurRadius: 24,
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                offset: const Offset(0, 1),
                blurRadius: 6,
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: _navBtn(Icons.home_rounded, 'Trang chủ', 0)),
              Expanded(child: _navBtn(Icons.people_outline_rounded, 'Cộng đồng', 1)),
              Expanded(child: _navCenterBtn(Icons.pets_rounded, 'Thú cưng', 2)),
              Expanded(child: _navBtn(Icons.notifications_outlined, 'Thông báo', 3)),
              Expanded(child: _navBtn(Icons.settings_outlined, 'Cài đặt', 4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navBtn(IconData icon, String label, int index) {
    final active = _currentTab == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _switchTab(index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: active ? MoewColors.accent.withValues(alpha: 0.13) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedScale(
                scale: active ? 1.1 : 1.0,
                duration: Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Icon(icon, size: 20,
                  color: active ? MoewColors.accent : MoewColors.textSub),
              ),
            ),
            SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: Duration(milliseconds: 220),
              style: TextStyle(
                fontSize: 9,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? MoewColors.accent : MoewColors.textSub,
              ),
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
                child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Nút giữa — Thú cưng LUÔN nổi bật dù active hay không
  Widget _navCenterBtn(IconData icon, String label, int index) {
    final active = _currentTab == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _switchTab(index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                // Luôn filled gradient theo theme hiện tại
                gradient: LinearGradient(
                  colors: [MoewColors.primary, MoewColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: MoewColors.primary.withValues(alpha: active ? 0.5 : 0.25),
                    blurRadius: active ? 16 : 8,
                    offset: const Offset(0, 4),
                    spreadRadius: active ? 1 : 0,
                  ),
                ],
              ),
              child: AnimatedScale(
                scale: active ? 1.12 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Icon(icon, size: 22, color: Colors.white),
              ),
            ),
            SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: MoewColors.primary,
              ),
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
                child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
