import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../api/auth_api.dart';
import '../../api/post_api.dart';
import '../../api/feed_api.dart';
import '../../api/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/toast.dart';
import '../../widgets/comment_sheet.dart';
import '../../services/mqtt_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String? _avatarUrl;
  bool _drawerOpen = false;
  late AnimationController _drawerController;
  late Animation<Offset> _drawerSlide;
  late Animation<double> _overlayFade;

  // Feed State
  final List<dynamic> _posts = [];
  bool _loading = true;
  bool _loadingMore = false;
  dynamic _nextCursor;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  // Weather State
  String _temperature = '--°C';
  IconData _weatherIcon = Icons.wb_sunny_rounded;
  Color _weatherColor = Colors.orange;

  StreamSubscription? _mqttSub;

  Future<void> _fetchWeather() async {
    try {
      final url = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=10.7626&longitude=106.6601&current_weather=true');
      final res = await http.get(url, headers: {'Accept': 'application/json'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final current = data['current_weather'];
        final temp = current['temperature'].round();
        final isDay = current['is_day'] == 1;
        final code = current['weathercode'] as int;
        
        IconData icon = isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
        Color color = isDay ? Colors.orange : Colors.indigoAccent;
        
        if (code >= 51 && code <= 67) {
          icon = Icons.water_drop; 
          color = Colors.blue;
        } else if (code >= 1 && code <= 3) {
          icon = Icons.wb_cloudy_rounded; 
          color = Colors.lightBlue;
        } else if (code >= 95) {
          icon = Icons.thunderstorm; 
          color = Colors.deepPurple;
        }

        if (mounted) {
          setState(() {
            _temperature = '$temp°C';
            _weatherIcon = icon;
            _weatherColor = color;
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải thời tiết: $e');
    }
  }

  // Drawer menu items — Thêm cụm Home Features vào đầu
  static const _drawerItems = [
    {'key': 'pet', 'label': 'Thú cưng', 'icon': Icons.pets_outlined, 'route': '/pet-profile'},
    {'key': 'medical', 'label': 'Y tế', 'icon': Icons.medical_services_outlined, 'route': '/clinic-list'},
    {'key': 'ai', 'label': 'AI Phân tích', 'icon': Icons.auto_awesome, 'route': '/food-analysis'},
    {'key': 'feeding', 'label': 'Cho ăn', 'icon': Icons.restaurant_outlined, 'route': '/feeding-today'},
    {'key': 'divider'},
    {'key': 'profile', 'label': 'Hồ sơ cá nhân', 'icon': Icons.person_outline, 'route': '/profile'},
    {'key': 'notif', 'label': 'Thông báo', 'icon': Icons.notifications_outlined, 'route': '/notifications'},
    {'key': 'wallet', 'label': 'Ví Meow-Care', 'icon': Icons.account_balance_wallet_outlined, 'route': '/wallet'},
    {'key': 'divider'},
    {'key': 'bookings', 'label': 'Lịch sử đặt lịch', 'icon': Icons.calendar_month_outlined, 'route': '/booking-history'},
  ];

  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _drawerController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _drawerSlide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _drawerController, curve: Curves.easeOutCubic));
    _overlayFade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _drawerController, curve: Curves.easeOut));
    
    _fetchAvatar();
    _fetchFeed();
    _scrollController.addListener(_onScroll);
    _listenMqtt();
  }

  void _listenMqtt() {
    _mqttSub = MqttService().messageStream.listen((data) {
      if (!mounted) return;
      final type = data['type'] as String?;
      switch (type) {
        case 'post_liked':
          MoewToast.show(context,
              message: data['title']?.toString() ?? 'Ai đó đã thích bài của bạn!',
              type: ToastType.info);
          break;
        case 'post_commented':
          MoewToast.show(context,
              message: data['title']?.toString() ?? 'Ai đó đã bình luận bài của bạn!',
              type: ToastType.info);
          final postId = data['postId'];
          if (postId != null) _refreshPost(postId);
          break;
      }
    });
  }

  Future<void> _refreshPost(dynamic postId) async {
    final res = await PostApi.getPostDetail(postId);
    if (!mounted || !res.success) return;
    final updated = (res.data as Map?)?['data'] as Map<String, dynamic>?;
    if (updated == null) return;
    setState(() {
      final idx = _posts.indexWhere((p) => p['id'] == postId);
      if (idx != -1) _posts[idx] = updated;
    });
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreFeed();
    }
  }

  Future<void> _fetchAvatar() async {
    final res = await AuthApi.getProfile();
    if (!mounted) return;
    if (res.success) {
      final p = (res.data as Map?)?['data'] ?? res.data;
      if (p is Map && p['avatar'] != null) {
        final avatarStr = p['avatar'] as String;
        setState(() => _avatarUrl = ApiConfig.parseImageUrl(avatarStr));
      }
    }
  }

  Future<void> _fetchFeed({bool refresh = false}) async {
    if (refresh) {
      _nextCursor = null;
      _hasMore = true;
    }
    
    // Facebook-style BigPipe Initial Cache Load
    if (!refresh && _posts.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('moew_home_feed_cache');
      if (cachedJson != null && mounted) {
        try {
          final cachedList = jsonDecode(cachedJson) as List;
          setState(() {
            _posts.addAll(cachedList);
            _loading = false;
          });
        } catch (_) {}
      } else {
        setState(() => _loading = true);
      }
    } else if (!refresh) {
      setState(() => _loading = true);
    }
    
    final res = await PostApi.getFeed(cursor: _nextCursor, limit: 10);
    if (!mounted) return;
    
    if (res.success) {
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
      if (data != null) {
        final newPosts = data['posts'] as List<dynamic>? ?? [];
        final pagination = data['pagination'] as Map<String, dynamic>?;
        
        _nextCursor = pagination?['nextCursor'];
        _hasMore = pagination?['hasMore'] == true;
        
        setState(() {
          if (refresh || _nextCursor == null) _posts.clear();
          _posts.addAll(newPosts);
          _loading = false;
        });

        // Save first page offline
        if (_nextCursor == null || refresh) {
          final prefs = await SharedPreferences.getInstance();
          prefs.setString('moew_home_feed_cache', jsonEncode(newPosts.take(20).toList()));
        }
      } else {
        setState(() => _loading = false);
      }
    } else {
      if (_posts.isEmpty) setState(() => _loading = false);
      MoewToast.show(context, message: res.error ?? 'Lỗi tải Feed', type: ToastType.error);
    }
  }

  Future<void> _loadMoreFeed() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    
    final res = await PostApi.getFeed(cursor: _nextCursor, limit: 10);
    if (!mounted) return;
    
    if (res.success) {
      final data = (res.data as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
      if (data != null) {
        final newPosts = data['posts'] as List<dynamic>? ?? [];
        final pagination = data['pagination'] as Map<String, dynamic>?;
        _nextCursor = pagination?['nextCursor'];
        _hasMore = pagination?['hasMore'] == true;
        setState(() {
          _posts.addAll(newPosts);
          _loadingMore = false;
        });
      } else {
        setState(() => _loadingMore = false);
      }
    } else {
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _toggleLike(int postIndex) async {
    final post = _posts[postIndex] as Map<String, dynamic>;
    final wasLiked = post['isLiked'] as bool? ?? false;
    final prevCount = post['likeCount'] as int? ?? 0;

    setState(() {
      _posts[postIndex] = {
        ...post,
        'isLiked': !wasLiked,
        'likeCount': wasLiked ? prevCount - 1 : prevCount + 1,
      };
    });

    try {
      final res = await FeedApi.like(post['id']);
      if (!mounted) return;
      if (res.success) {
        final data = (res.data as Map?)?['data'] as Map<String, dynamic>?;
        if (data != null) {
          setState(() {
            _posts[postIndex] = {
              ...(_posts[postIndex] as Map<String, dynamic>),
              'isLiked': data['liked'] as bool? ?? !wasLiked,
              'likeCount': data['likeCount'] as int? ?? prevCount,
            };
          });
        }
      } else {
        setState(() {
          _posts[postIndex] = {
            ...(_posts[postIndex] as Map<String, dynamic>),
            'isLiked': wasLiked,
            'likeCount': prevCount,
          };
        });
        MoewToast.show(context, message: 'Có lỗi, thử lại!', type: ToastType.error);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _posts[postIndex] = {
          ...(_posts[postIndex] as Map<String, dynamic>),
          'isLiked': wasLiked,
          'likeCount': prevCount,
        };
      });
      MoewToast.show(context, message: 'Có lỗi, thử lại!', type: ToastType.error);
    }
  }

  void _openComments(Map<String, dynamic> post, int postIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentSheet(
        post: post,
        onCommentAdded: () {
          setState(() {
            final prev = _posts[postIndex]['commentCount'] as int? ?? 0;
            _posts[postIndex] = {
              ...(_posts[postIndex] as Map<String, dynamic>),
              'commentCount': prev + 1,
            };
          });
        },
      ),
    );
  }

  String _formatPostTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final h = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final m = date.minute.toString().padLeft(2, '0');
      final ampm = date.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    } catch (_) {
      return '';
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
        title: Text('Đăng xuất'),
        content: Text('Bạn muốn đăng xuất?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Hủy')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthProvider>().onLogout();
              Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
            },
            child: Text('Đăng xuất', style: TextStyle(color: MoewColors.danger)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mqttSub?.cancel();
    _drawerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final screenW = MediaQuery.of(context).size.width;
    final drawerW = screenW * 0.75;

    return Scaffold(
      backgroundColor: MoewColors.tintPurple, // Trả lại config gốc của anh em
      body: Stack(
        children: [
          // ═══ Main Content ═══
          Column(
            children: [
              // Header giữ y như cũ
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Bản đồ và thời tiết sát nhau ở bên trái
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/guardian-map'),
                            child: Container(
                              width: 76, height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Color(0xFFE6F0F6), // Fallback map color
                                image: const DecorationImage(
                                  image: AssetImage('assets/images/map_bg.png'), // Mẫu hình bản đồ của user
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: MoewShadows.card,
                              ),
                              child: Align(
                                alignment: const Alignment(0.5, 0), // Lệch sang phải 25%
                                child: Container(
                                  width: 16, height: 16,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF10B981), // Xanh ngọc phỉ thúy
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(color: Color(0xFF10B981).withValues(alpha: 0.6), blurRadius: 8, spreadRadius: 2)
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          // Thời tiết mini
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: _weatherColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_weatherIcon, size: 16, color: _weatherColor),
                                SizedBox(width: 6),
                                Text(_temperature, style: TextStyle(color: _weatherColor, fontWeight: FontWeight.w800, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      // Avatar chuyển sang phải
                      GestureDetector(
                        onTap: _openDrawer,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, spreadRadius: 1)
                            ],
                          ),
                          child: _avatarUrl != null
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: _avatarUrl!,
                                    width: 40, height: 40, fit: BoxFit.cover,
                                  ),
                                )
                              : Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: MoewColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.person, size: 20, color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content area — full white với góc bo tròn y như cũ
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent, // Để lộ nền premium phía sau
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    child: RefreshIndicator(
                      color: MoewColors.primary,
                      onRefresh: () => _fetchFeed(refresh: true),
                      child: _loading && _posts.isEmpty
                          ? ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: 4,
                              itemBuilder: (context, index) {
                                if (index == 0) return _buildCreatePostBox();
                                return _buildSkeletonPost();
                              },
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: _posts.length + 2, // 1 for Create Post, 1 for Loader
                              itemBuilder: (context, index) {
                                if (index == 0) return _buildCreatePostBox();
                                
                                if (index == _posts.length + 1) {
                                  if (_loadingMore) return _buildSkeletonPost();
                                  return SizedBox(height: 110);
                                }

                                final post = _posts[index - 1] as Map<String, dynamic>;
                                return _buildPostCard(post, index - 1);
                              },
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),


          // ═══ Drawer Overlay — GIỮ Y NHƯ CŨ ═══
          if (_drawerOpen) ...[
            FadeTransition(
              opacity: _overlayFade,
              child: GestureDetector(
                onTap: _closeDrawer,
                child: Container(color: Colors.black.withValues(alpha: 0.4)),
              ),
            ),
            // Drawer Overlay (Menu bây giờ bám vào cạnh PHẢI)
            Align(
              alignment: Alignment.centerRight,
              child: SlideTransition(
                position: _drawerSlide,
                child: Container(
                  width: drawerW,
                  decoration: BoxDecoration(
                    color: MoewColors.background,
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: Offset(-4, 0),
                      )
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Profile section
                        Container(
                          padding: EdgeInsets.fromLTRB(20, 32, 20, 24),
                          decoration: BoxDecoration(
                            color: MoewColors.white,
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(32), bottomLeft: Radius.circular(24)),
                            boxShadow: MoewShadows.soft,
                          ),
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: MoewColors.primary.withValues(alpha: 0.15), width: 3),
                                ),
                                child: _avatarUrl != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(32),
                                        child: CachedNetworkImage(imageUrl: _avatarUrl!, width: 52, height: 52, fit: BoxFit.cover),
                                      )
                                    : Container(
                                        width: 52, height: 52,
                                        decoration: BoxDecoration(
                                          color: MoewColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.person, size: 26, color: Colors.white),
                                      ),
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?['displayName'] ?? 'Cat Lover', 
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: MoewColors.textMain, letterSpacing: -0.3),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      user?['email'] ?? 'Welcome to Moew', 
                                      style: TextStyle(fontSize: 12, color: MoewColors.textSub),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12),

                        // Menu items
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            children: [
                              ..._drawerItems.map((item) {
                                if (item['key'] == 'divider') {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Divider(height: 1, color: MoewColors.border.withValues(alpha: 0.5)),
                                  );
                                }
                                return Container(
                                  margin: EdgeInsets.only(bottom: 6),
                                  decoration: BoxDecoration(
                                    color: MoewColors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
                                        _closeDrawer();
                                        Future.delayed(const Duration(milliseconds: 300), () {
                                          if (mounted && context.mounted && item['route'] != null) {
                                            Navigator.pushNamed(context, item['route'] as String);
                                          }
                                        });
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        child: Row(
                                          children: [
                                            Icon(item['icon'] as IconData, size: 20, color: MoewColors.primary),
                                            SizedBox(width: 14),
                                            Expanded(
                                              child: Text(item['label'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: MoewColors.textMain)),
                                            ),
                                            Icon(Icons.chevron_right_rounded, size: 16, color: MoewColors.border),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              
                              SizedBox(height: 16),
                              
                              Container(
                                margin: EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: MoewColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    _closeDrawer();
                                    Future.delayed(const Duration(milliseconds: 300), () {
                                      if (mounted && context.mounted) Navigator.pushNamed(context, '/settings');
                                    });
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    child: Row(
                                      children: [
                                        Icon(Icons.settings_outlined, size: 20, color: MoewColors.primary),
                                        SizedBox(width: 14),
                                        Expanded(
                                          child: Text('Cài đặt & Giao diện', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MoewColors.primary)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              Container(
                                margin: EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: MoewColors.danger.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: _handleLogout,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    child: Row(
                                      children: [
                                        Icon(Icons.logout_rounded, size: 20, color: MoewColors.danger),
                                        SizedBox(width: 14),
                                        Expanded(
                                          child: Text('Đăng xuất', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MoewColors.danger)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Khung đăng bài được bao bọc trong một khối chung
  Widget _buildCreatePostBox() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: EdgeInsets.all(20), // Airy padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          // Input Pill
          GestureDetector(
            onTap: () async {
              final res = await Navigator.pushNamed(context, '/create-post');
              if (res == true) _fetchFeed(refresh: true);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: MoewColors.background, // Tách lót nền khỏi thẻ trắng
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Hôm nay thú cưng của bạn thế nào?', 
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: MoewColors.textSub),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          // Buttons Row
          Row(
            children: [
              Expanded(
                child: _buildCreateActionBtn(Icons.edit_note, 'Bài viết', onTap: () async {
                  final res = await Navigator.pushNamed(context, '/create-post');
                  if (res == true) _fetchFeed(refresh: true);
                }),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildCreateActionBtn(Icons.document_scanner_outlined, 'Soi Hạt', onTap: () {
                  Navigator.pushNamed(context, '/ai-scan');
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreateActionBtn(IconData icon, String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: MoewColors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: MoewColors.textMain),
            SizedBox(width: 8),
            Text(label, style: TextStyle(color: MoewColors.textMain, fontWeight: FontWeight.w700, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post, int index) {
    final user = post['user'] as Map<String, dynamic>? ?? {};
    final userAvatar = user['avatar']?.toString() ?? '';
    final userName = user['displayName']?.toString() ?? 'Moew User';
    
    final caption = post['caption']?.toString() ?? '';
    final images = (post['images'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final petTags = post['petTags'] as List<dynamic>? ?? [];
    
    final avatarUrl = ApiConfig.parseImageUrl(userAvatar);
    final isMyPost = user['id'] == context.read<AuthProvider>().user?['id'];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (user['id'] != null) Navigator.pushNamed(context, '/public-profile', arguments: user['id']);
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: MoewColors.accent.withValues(alpha: 0.2),
                      backgroundImage: userAvatar.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
                      child: userAvatar.isEmpty ? Icon(Icons.person, color: MoewColors.primary, size: 20) : null,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (user['id'] != null) Navigator.pushNamed(context, '/public-profile', arguments: user['id']);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(child: Text(userName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: MoewColors.textMain), overflow: TextOverflow.ellipsis)),
                              if (post['createdAt'] != null) ...[
                                SizedBox(width: 8),
                                Text(
                                  _formatPostTime(post['createdAt'].toString()),
                                  style: TextStyle(fontSize: 13, color: MoewColors.textSub),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 2),
                          Text(
                            petTags.isNotEmpty
                                ? petTags.map((t) => (t as Map<String, dynamic>)['name']?.toString() ?? 'Pet').join(', ')
                                : 'mèo lạ',
                            style: TextStyle(fontSize: 13, color: MoewColors.textSub),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isMyPost)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz, color: MoewColors.textMain, size: 22),
                      onSelected: (val) async {
                        if (val == 'edit') {
                          final res = await Navigator.pushNamed(context, '/edit-post', arguments: post);
                          if (res == true) _fetchFeed(refresh: true);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit, size: 20, color: MoewColors.textMain),
                            SizedBox(width: 10),
                            Text('Sửa bài viết'),
                          ]),
                        ),
                      ],
                    )
                  else
                    Icon(Icons.more_horiz, color: MoewColors.textMain, size: 22),
                ],
              ),
            ),
              
            // Images — Bo viền tròn + counter badge
            if (images.isNotEmpty)
              Builder(
                builder: (ctx) {
                  final pageNotifier = ValueNotifier<int>(0);
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: SizedBox(
                        height: 280, // Tăng chiều cao để xem ảnh đẹp hơn
                        width: double.infinity,
                        child: Stack(
                          children: [
                            PageView.builder(
                              itemCount: images.length,
                              onPageChanged: (i) => pageNotifier.value = i,
                              itemBuilder: (context, idx) {
                                final imgUrl = ApiConfig.parseImageUrl(images[idx]);
                                return CachedNetworkImage(
                                  imageUrl: imgUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (ctx, url) => Shimmer.fromColors(
                                    baseColor: Colors.grey[200]!,
                                    highlightColor: Colors.white,
                                    child: Container(color: Colors.white),
                                  ),
                                  errorWidget: (ctx, url, error) => Container(color: MoewColors.background, child: Icon(Icons.image_not_supported, color: MoewColors.textSub)),
                                );
                              },
                            ),
                            if (images.length > 1)
                              Positioned(
                                top: 12, right: 12,
                                child: ValueListenableBuilder<int>(
                                  valueListenable: pageNotifier,
                                  builder: (_, page, _) => Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: Offset(0, 4))
                                      ],
                                    ),
                                    child: Text(
                                      '${page + 1}/${images.length}',
                                      style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
            // Modern Actions bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  _actionButton(
                    post['isLiked'] == true ? Icons.favorite : Icons.favorite_border,
                    post['isLiked'] == true ? Colors.red : MoewColors.textSub,
                    '${post['likeCount'] ?? 0}',
                    onTap: () => _toggleLike(index),
                  ),
                  SizedBox(width: 24),
                  _actionButton(
                    Icons.chat_bubble_outline,
                    MoewColors.textSub,
                    '${post['commentCount'] ?? 0}',
                    onTap: () => _openComments(post, index),
                  ),
                  Spacer(),
                  Icon(Icons.bookmark_border, size: 22, color: MoewColors.textSub),
                ],
              ),
            ),

            // Caption — dưới cùng, màu xám mờ
            if (caption.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16),
                child: Text(caption, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: MoewColors.textSub, height: 1.4)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, Color color, String count, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            if (count != '0') ...[
              SizedBox(width: 4),
              Text(count, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonPost() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16, offset: Offset(0, 8)),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[50]!,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 120, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                      SizedBox(height: 6),
                      Container(width: 80, height: 10, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 16),
              Container(width: double.infinity, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
              SizedBox(height: 6),
              Container(width: 250, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
              SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}