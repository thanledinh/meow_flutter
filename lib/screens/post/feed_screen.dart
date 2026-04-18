import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../api/feed_api.dart';
import '../../api/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/toast.dart';
import '../../widgets/comment_sheet.dart';
import '../../services/mqtt_service.dart';
import '../../models/post_model.dart';

// ─────────────────────────────────────────────────────────────
// FEED SCREEN
// ─────────────────────────────────────────────────────────────
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final List<Map<String, dynamic>> _posts = [];
  bool _loading = true;
  bool _loadingMore = false;
  dynamic _nextCursor;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _mqttSub;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Weather State
  String _temperature = '--°C';
  IconData _weatherIcon = Icons.wb_sunny_rounded;
  Color _weatherColor = Colors.orange;

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

  void _handleLogout() {
    Navigator.pop(context);
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
              context.pushReplacement('/login');
            },
            child: Text('Đăng xuất', style: TextStyle(color: MoewColors.danger)),
          ),
        ],
      ),
    );
  }

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

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _fetch();
    _scrollController.addListener(_onScroll);
    _listenMqtt();
  }

  @override
  void dispose() {
    _mqttSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  // ── MQTT: nhận post_liked / post_commented ─────────────────
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
          if (postId != null) {
            final newCount = data['newCommentCount'] as int?;
            if (newCount != null) {
              setState(() {
                final idx = _posts.indexWhere((p) => p['id'] == postId);
                if (idx != -1) {
                  _posts[idx] = {
                    ..._posts[idx],
                    'commentCount': newCount,
                  };
                }
              });
            } else {
              _refreshPost(postId);
            }
          }
          break;
      }
    });
  }

  // Reload 1 post cụ thể (sau khi nhận MQTT) mà không reload toàn feed
  Future<void> _refreshPost(dynamic postId) async {
    final res = await FeedApi.getById(postId);
    if (!mounted || !res.success) return;
    final updated = (res.data as Map?)
        ?['data'] as Map<String, dynamic>?;
    if (updated == null) return;
    setState(() {
      final idx = _posts.indexWhere((p) => p['id'] == postId);
      if (idx != -1) _posts[idx] = updated;
    });
  }

  // ── Fetch / Pagination ─────────────────────────────────────
  Future<void> _fetch({bool refresh = false}) async {
    if (refresh) {
      _nextCursor = null;
      _hasMore = true;
    }
    setState(() => _loading = !refresh);

    final res = await FeedApi.getAll(cursor: _nextCursor, limit: 10);
    if (!mounted) return;

    if (res.success) {
      final data = (res.data as Map?)?['data'] as Map<String, dynamic>?;
      final newPosts = (data?['posts'] as List? ?? []).cast<Map<String, dynamic>>();
      final pagination = data?['pagination'] as Map?;
      
      _nextCursor = pagination?['nextCursor'];
      _hasMore = pagination?['hasMore'] == true;

      setState(() {
        if (refresh || _nextCursor == null) {
          _posts
            ..clear()
            ..addAll(newPosts);
        } else {
          _posts.addAll(newPosts);
        }
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      if (mounted) {
        MoewToast.show(context, message: res.error ?? 'Lỗi tải trang', type: ToastType.error);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    
    final res = await FeedApi.getAll(cursor: _nextCursor, limit: 10);
    if (!mounted) return;
    
    if (res.success) {
      final data = (res.data as Map?)?['data'] as Map<String, dynamic>?;
      final newPosts = (data?['posts'] as List? ?? []).cast<Map<String, dynamic>>();
      final pagination = data?['pagination'] as Map?;
      
      _nextCursor = pagination?['nextCursor'];
      _hasMore = pagination?['hasMore'] == true;

      setState(() {
        _posts.addAll(newPosts);
        _loadingMore = false;
      });
    } else {
      setState(() => _loadingMore = false);
    }
  }

  // ── Like (Optimistic Update) ───────────────────────────────
  Future<void> _toggleLike(int postIndex) async {
    final post = _posts[postIndex];
    final wasLiked = post['isLiked'] as bool? ?? false;
    final prevCount = post['likeCount'] as int? ?? 0;

    // 1. Update UI ngay lập tức
    setState(() {
      _posts[postIndex] = {
        ...post,
        'isLiked': !wasLiked,
        'likeCount': wasLiked ? prevCount - 1 : prevCount + 1,
      };
    });

    // 2. Gọi API ngầm
    try {
      final res = await FeedApi.like(post['id']);
      if (!mounted) return;
      if (res.success) {
        final data = (res.data as Map?)
            ?['data'] as Map<String, dynamic>?;
        if (data != null) {
          setState(() {
            _posts[postIndex] = {
              ..._posts[postIndex],
              'isLiked': data['liked'] as bool? ?? !wasLiked,
              'likeCount': data['likeCount'] as int? ?? prevCount,
            };
          });
        }
      } else {
        // 3. Rollback nếu lỗi
        setState(() {
          _posts[postIndex] = {
            ..._posts[postIndex],
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
          ..._posts[postIndex],
          'isLiked': wasLiked,
          'likeCount': prevCount,
        };
      });
      MoewToast.show(context, message: 'Có lỗi, thử lại!', type: ToastType.error);
    }
  }

  // ── Open Comment Sheet ─────────────────────────────────────
  void _openComments(Map<String, dynamic> post, int postIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentSheet(
        post: post,
        onCommentAdded: () {
          // Tăng commentCount locally
          setState(() {
            final prev = _posts[postIndex]['commentCount'] as int? ?? 0;
            _posts[postIndex] = {
              ..._posts[postIndex],
              'commentCount': prev + 1,
            };
          });
        },
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────
  String _timeAgo(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 7) {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
      if (diff.inDays > 0) return '${diff.inDays} ngày trước';
      if (diff.inHours > 0) return '${diff.inHours} giờ trước';
      if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
      return 'Vừa xong';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final avatarUrl = user?['avatar'] as String?;
    final avatarImage = avatarUrl != null && avatarUrl.isNotEmpty ? ApiConfig.parseImageUrl(avatarUrl) : null;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: MoewColors.background, // Nền custom riêng của user
      endDrawer: _buildSidebar(user, avatarImage),
      body: Stack(
        children: [
          Column(
            children: [
              // Header cũ (SafeArea Map + Weather + Avatar)
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => context.push('/guardian-map'),
                            child: Container(
                              width: 76, height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Color(0xFFE6F0F6),
                                image: const DecorationImage(
                                  image: AssetImage('assets/images/map_bg.png'),
                                  fit: BoxFit.cover,
                                ),
                                boxShadow: MoewShadows.card,
                              ),
                              child: Align(
                                alignment: const Alignment(0.5, 0),
                                child: Container(
                                  width: 16, height: 16,
                                  decoration: BoxDecoration(
                                    color: Color(0xFF10B981),
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
                      GestureDetector(
                        onTap: () {
                          _scaffoldKey.currentState?.openEndDrawer();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(color: MoewColors.primary.withValues(alpha: 0.15), blurRadius: 8, spreadRadius: 2)
                            ],
                          ),
                          child: avatarImage != null
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: avatarImage,
                                    width: 40, height: 40, fit: BoxFit.cover,
                                  ),
                                )
                              : Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(color: MoewColors.accent, shape: BoxShape.circle),
                                  child: Icon(Icons.person, size: 20, color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content Area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent, // lộ nền background của hệ thống mới
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                    child: _loading && _posts.isEmpty
                        ? Center(child: CircularProgressIndicator(color: MoewColors.primary))
                        : RefreshIndicator(
                            color: MoewColors.primary,
                            onRefresh: () => _fetch(refresh: true),
                            child: ListView.separated(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(0, 0, 0, 16),
                              itemCount: _posts.isEmpty ? 2 : _posts.length + (_loadingMore ? 2 : 1),
                              separatorBuilder: (context, index) => index == 0 ? SizedBox() : SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                // 1. Khung tạo bài mới luôn ở trên cùng
                                if (index == 0) return _buildCreatePostBox();

                                // 2. Nếu rỗng
                                if (_posts.isEmpty && index == 1) {
                                  return Padding(
                                    padding: EdgeInsets.only(top: 80),
                                    child: Center(child: Text('Chưa có bài đăng nào', style: TextStyle(color: MoewColors.textSub))),
                                  );
                                }

                                // 3. Nếu là Loading More spinner ở cuối cùng
                                if (index == _posts.length + 1) {
                                  return Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(child: CircularProgressIndicator(color: MoewColors.primary)),
                                  );
                                }

                                // 4. Render PostCard
                                final realIndex = index - 1;
                                final postModel = PostModel.fromJson(_posts[realIndex]);
                                final postUser = postModel.author;
                                final isMyPost = postUser != null && postUser.id == context.read<AuthProvider>().user?['id'];
                                return _PostCard(
                                  post: postModel,
                                  isMyPost: isMyPost,
                                  onLike: () => _toggleLike(realIndex),
                                  onComment: () => _openComments(_posts[realIndex], realIndex),
                                  onAvatarTap: (userId) => context.push('/public-profile', extra: userId),
                                  onEdit: () async {
                                    final res = await context.push('/edit-post', extra: _posts[realIndex]);
                                    if (res == true) _fetch(refresh: true);
                                  },
                                  timeAgo: _timeAgo,
                                );
                              },
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreatePostBox() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: MoewColors.primary.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () async {
              final res = await context.push('/create-post');
              if (res == true) _fetch(refresh: true);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: MoewColors.surface, // Dùng theme custom của user
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: MoewColors.primary, size: 20),
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
          Row(
            children: [
              Expanded(
                child: _buildCreateActionBtn(Icons.edit_note, 'Bài viết', onTap: () async {
                  final res = await context.push('/create-post');
                  if (res == true) _fetch(refresh: true);
                }),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildCreateActionBtn(Icons.document_scanner_outlined, 'Soi Hạt', onTap: () {
                  context.push('/food-analysis'); // Map tới AI 
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
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: MoewColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: MoewColors.textMain),
            SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MoewColors.textMain)),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(Map<String, dynamic>? user, String? avatarImage) {
    return Drawer(
      backgroundColor: MoewColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(32)),
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
                    child: avatarImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: CachedNetworkImage(imageUrl: avatarImage, width: 52, height: 52, fit: BoxFit.cover),
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
                          user?['displayName'] ?? user?['username'] ?? 'Cat Lover', 
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
                            Navigator.pop(context);
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (mounted && context.mounted && item['route'] != null) {
                                context.push(item['route'] as String);
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
                        Navigator.pop(context);
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted && context.mounted) context.push('/settings');
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Icon(Icons.settings_outlined, size: 20, color: MoewColors.primary),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text('Cài đặt', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MoewColors.primary)),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────
// POST CARD — stateless, nhận callbacks từ FeedScreen
// ─────────────────────────────────────────────────────────────
class _PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final void Function(dynamic) onAvatarTap;
  final VoidCallback onEdit;
  final bool isMyPost;
  final String Function(String) timeAgo;

  const _PostCard({
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onAvatarTap,
    required this.onEdit,
    required this.isMyPost,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
    final userAvatar = post.author?.avatarUrl ?? '';
    final userName = post.author?.displayName ?? post.author?.username ?? 'Moew User';
    final caption = post.content ?? '';
    final images = post.mediaUrls;
    final petTags = post.petTags ?? [];
    final isLiked = post.isLiked;
    final likeCount = post.likeCount;
    final commentCount = post.commentCount;
    final avatarUrl = ApiConfig.parseImageUrl(userAvatar);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: MoewColors.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(children: [
              GestureDetector(
                onTap: () {
                  if (post.author?.id != null) onAvatarTap(post.author!.id);
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: MoewColors.accent,
                  backgroundImage: userAvatar.isNotEmpty
                      ? CachedNetworkImageProvider(avatarUrl) : null,
                  child: userAvatar.isEmpty
                      ? Icon(Icons.person, color: Colors.white, size: 20) : null,
                ),
              ),
              SizedBox(width: 12),
              Expanded(child: GestureDetector(
                onTap: () {
                  if (post.author?.id != null) onAvatarTap(post.author!.id);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15, color: MoewColors.textMain)),
                    if (post.createdAt != null)
                      Text(timeAgo(post.createdAt!.toIso8601String()),
                          style: TextStyle(fontSize: 12, color: MoewColors.textSub)),
                  ],
                ),
              )),
              if (isMyPost)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, color: MoewColors.textSub),
                  onSelected: (val) {
                    if (val == 'edit') {
                      onEdit();
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
                ),
            ]),
          ),

          // ── Caption ───────────────────────────────────────
          if (caption.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 12),
              child: Text(caption, style: TextStyle(
                  fontSize: 15, color: MoewColors.textMain, height: 1.4)),
            ),

          // ── Pet Tags ──────────────────────────────────────
          if (petTags.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 12),
              child: Wrap(spacing: 8, runSpacing: 8, children: petTags.map<Widget>((tag) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: MoewColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: MoewColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.pets, size: 12, color: MoewColors.primary),
                    SizedBox(width: 4),
                    Text(tag['name']?.toString() ?? 'Pet', style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: MoewColors.primary)),
                  ]),
                );
              }).toList()),
            ),

          // ── Images ────────────────────────────────────────
          if (images.isNotEmpty)
            SizedBox(
              height: 300,
              child: PageView.builder(
                itemCount: images.length,
                itemBuilder: (context, idx) {
                  final imgUrl = ApiConfig.parseImageUrl(images[idx]);
                  return CachedNetworkImage(
                    imageUrl: imgUrl,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) => Container(
                        color: MoewColors.background,
                        child: Center(child: CircularProgressIndicator(color: MoewColors.primary))),
                    errorWidget: (ctx, url, error) => Container(
                        color: MoewColors.background,
                        child: Icon(Icons.image_not_supported, color: MoewColors.textSub)),
                  );
                },
              ),
            ),

          // ── Action Bar ────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(children: [
              // Like
              InkWell(
                onTap: onLike,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(children: [
                    AnimatedSwitcher(
                      duration: Duration(milliseconds: 200),
                      child: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey(isLiked),
                        color: isLiked ? Colors.red : MoewColors.textSub,
                        size: 22,
                      ),
                    ),
                    if (likeCount > 0) ...[
                      SizedBox(width: 4),
                      Text('$likeCount', style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isLiked ? Colors.red : MoewColors.textSub)),
                    ],
                  ]),
                ),
              ),
              // Comment
              InkWell(
                onTap: onComment,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(children: [
                    Icon(Icons.chat_bubble_outline,
                        color: MoewColors.textSub, size: 22),
                    if (commentCount > 0) ...[
                      SizedBox(width: 4),
                      Text('$commentCount', style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: MoewColors.textSub)),
                    ],
                  ]),
                ),
              ),
            ]),
          ),
        ],
      ),
      ),
    );
  }
}

// CommentSheet content removed and extracted to lib/widgets/comment_sheet.dart
