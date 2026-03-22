import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../api/auth_api.dart';
import '../../api/pet_api.dart';
import '../../api/api_client.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String? _avatarUrl;
  bool _drawerOpen = false;
  late AnimationController _drawerController;
  late Animation<Offset> _drawerSlide;
  late Animation<double> _overlayFade;

  // Drawer menu items
  static const _drawerItems = [
    {'key': 'profile', 'label': 'Hồ sơ cá nhân', 'icon': Icons.person_outline, 'route': '/profile'},
    {'key': 'public', 'label': 'Trang công khai', 'icon': Icons.public, 'route': '/public-profile'},
    {'key': 'ai', 'label': 'AI Thức ăn', 'icon': Icons.auto_awesome, 'route': '/food-analysis'},
    {'key': 'camera', 'label': 'Camera', 'icon': Icons.camera_alt_outlined, 'route': '/camera'},
    {'key': 'clinics', 'label': 'Phòng khám', 'icon': Icons.medical_services_outlined, 'route': '/clinic-list'},
    {'key': 'wallet', 'label': 'Ví Meow-Care', 'icon': Icons.account_balance_wallet_outlined, 'route': '/wallet'},
    {'key': 'sosHistory', 'label': 'Lịch sử SOS', 'icon': Icons.monitor_heart_outlined, 'route': '/sos-history'},
    {'key': 'notif', 'label': 'Thông báo', 'icon': Icons.notifications_outlined, 'route': '/notifications'},
    {'key': 'divider'},
    {'key': 'bookings', 'label': 'Lịch sử đặt lịch', 'icon': Icons.calendar_month_outlined, 'route': '/booking-history'},
  ];

  @override
  void initState() {
    super.initState();
    _drawerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _drawerSlide = Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _drawerController, curve: Curves.easeOutCubic));
    _overlayFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _drawerController, curve: Curves.easeOut));
    _fetchAvatar();
  }

  Future<void> _fetchAvatar() async {
    final res = await AuthApi.getProfile();
    if (!mounted) return;
    if (res.success) {
      final p = (res.data as Map?)?['data'] ?? res.data;
      if (p is Map && p['avatar'] != null) {
        final a = p['avatar'] as String;
        setState(() => _avatarUrl = a.startsWith('http') ? a : '${ApiConfig.baseUrl}$a');
      }
    }
  }

  void _openDrawer() {
    setState(() => _drawerOpen = true);
    _drawerController.forward();
  }

  void _closeDrawer() {
    _drawerController.reverse().then((_) {
      if (mounted) setState(() => _drawerOpen = false);
    });
  }

  void _handleLogout() {
    _closeDrawer();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn muốn đăng xuất?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().onLogout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
            },
            child: const Text('Đăng xuất', style: TextStyle(color: MoewColors.danger)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _drawerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final screenW = MediaQuery.of(context).size.width;
    final drawerW = screenW * 0.75;

    return Scaffold(
      backgroundColor: MoewColors.tintPurple,
      body: Stack(
        children: [
          // ═══ Main Content ═══
          Column(
            children: [
              // Header
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: _openDrawer,
                        child: _avatarUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(23),
                                child: CachedNetworkImage(
                                  imageUrl: _avatarUrl!,
                                  width: 46, height: 46, fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                width: 46, height: 46,
                                decoration: BoxDecoration(
                                  color: MoewColors.accent,
                                  borderRadius: BorderRadius.circular(23),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.person, size: 24, color: Colors.white),
                              ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/notifications'),
                        child: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: MoewColors.tintPurple,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: MoewShadows.card,
                          ),
                          child: const Icon(Icons.notifications_outlined, size: 20, color: MoewColors.textMain),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content area — full white
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        Text('Xin chào, ${user?['displayName'] ?? 'Moew User'}!',
                            style: MoewTextStyles.h2),
                        const SizedBox(height: 8),
                        Text('Hôm nay Boss thế nào?', style: MoewTextStyles.caption),
                        const SizedBox(height: 24),

                        // Quick actions grid
                        _buildQuickActions(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ═══ SOS FAB ═══
          Positioned(
            right: 20, bottom: 100,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/sos'),
              child: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFE53935).withValues(alpha: 0.4), offset: const Offset(0, 4), blurRadius: 8),
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber, size: 24, color: Colors.white),
                    Text('SOS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                  ],
                ),
              ),
            ),
          ),

          // ═══ Drawer Overlay ═══
          if (_drawerOpen) ...[
            FadeTransition(
              opacity: _overlayFade,
              child: GestureDetector(
                onTap: _closeDrawer,
                child: Container(color: Colors.black.withValues(alpha: 0.4)),
              ),
            ),
            SlideTransition(
              position: _drawerSlide,
              child: Container(
                width: drawerW,
                color: Colors.white,
                child: SafeArea(
                  child: Column(
                    children: [
                      // Profile section
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _avatarUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(32),
                                    child: CachedNetworkImage(imageUrl: _avatarUrl!, width: 64, height: 64, fit: BoxFit.cover),
                                  )
                                : Container(
                                    width: 64, height: 64,
                                    decoration: BoxDecoration(
                                      color: MoewColors.accent,
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                    child: const Icon(Icons.person, size: 32, color: Colors.white),
                                  ),
                            const SizedBox(height: 12),
                            Text(user?['displayName'] ?? 'Moew User', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: MoewColors.textMain)),
                            Text(user?['email'] ?? '', style: const TextStyle(fontSize: 13, color: MoewColors.textSub)),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: MoewColors.border),

                      // Menu items
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.only(top: 8),
                          children: _drawerItems.map((item) {
                            if (item['key'] == 'divider') {
                              return const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                                child: Divider(height: 1, color: MoewColors.border),
                              );
                            }
                            return ListTile(
                              leading: Icon(item['icon'] as IconData, size: 20, color: MoewColors.textMain),
                              title: Text(item['label'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              onTap: () {
                                _closeDrawer();
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  if (mounted && item['route'] != null) {
                                    Navigator.pushNamed(context, item['route'] as String);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),

                      // Logout
                      const Divider(height: 1, color: MoewColors.border),
                      ListTile(
                        leading: const Icon(Icons.logout, size: 20, color: MoewColors.danger),
                        title: const Text('Đăng xuất', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: MoewColors.danger)),
                        onTap: _handleLogout,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.pets, 'label': 'Thú cưng', 'color': MoewColors.primary, 'route': '/pet-profile'},
      {'icon': Icons.medical_services_outlined, 'label': 'Y tế', 'color': MoewColors.success, 'route': '/clinic-list'},
      {'icon': Icons.auto_awesome, 'label': 'AI Phân tích', 'color': MoewColors.accent, 'route': '/food-analysis'},
      {'icon': Icons.account_balance_wallet, 'label': 'Ví', 'color': MoewColors.secondary, 'route': '/wallet'},
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12, mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: actions.map((a) => GestureDetector(
        onTap: () => Navigator.pushNamed(context, a['route'] as String),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: (a['color'] as Color).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(MoewRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(a['icon'] as IconData, size: 28, color: a['color'] as Color),
              const SizedBox(height: 8),
              Text(a['label'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: a['color'] as Color)),
            ],
          ),
        ),
      )).toList(),
    );
  }
}
