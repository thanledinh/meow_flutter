import 'dart:async';
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

  @override
  void initState() {
    super.initState();
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
          // Nếu đang ở feed, reload post đó để cập nhật commentCount
          final postId = data['postId'];
          if (postId != null) _refreshPost(postId);
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
    return Scaffold(
      backgroundColor: Color(0xFFF8F8FC),
      appBar: AppBar(
        title: Text('Cộng đồng',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle, color: MoewColors.primary, size: 28),
            onPressed: () async {
              final res = await Navigator.pushNamed(context, '/create-post');
              if (res == true) _fetch(refresh: true);
            },
          ),
          SizedBox(width: 8),
        ],
      ),
      body: _loading && _posts.isEmpty
          ? Center(child: CircularProgressIndicator(color: MoewColors.primary))
          : RefreshIndicator(
              color: MoewColors.primary,
              onRefresh: () => _fetch(refresh: true),
              child: _posts.isEmpty
                  ? ListView(
                      physics: AlwaysScrollableScrollPhysics(),
                      children: [
                      SizedBox(height: 100),
                      Center(child: Text('Chưa có bài đăng nào',
                          style: TextStyle(color: MoewColors.textSub))),
                    ])
                  : ListView.separated(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      itemCount: _posts.length + (_loadingMore ? 1 : 0),
                      separatorBuilder: (context, index) => SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        if (index == _posts.length) {
                          return Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator(color: MoewColors.primary)),
                          );
                        }
                        final postModel = PostModel.fromJson(_posts[index]);
                        final postUser = postModel.author;
                        final isMyPost = postUser != null && postUser.id == context.read<AuthProvider>().user?['id'];
                        return _PostCard(
                          post: postModel,
                          isMyPost: isMyPost,
                          onLike: () => _toggleLike(index),
                          onComment: () => _openComments(_posts[index], index),
                          onAvatarTap: (userId) => Navigator.pushNamed(context, '/public-profile', arguments: userId),
                          onEdit: () async {
                            final res = await Navigator.pushNamed(context, '/edit-post', arguments: _posts[index]);
                            if (res == true) _fetch(refresh: true);
                          },
                          timeAgo: _timeAgo,
                        );
                      },
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
      color: Colors.white,
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
          Divider(height: 1, thickness: 1, color: MoewColors.border),
        ],
      ),
    );
  }
}

// CommentSheet content removed and extracted to lib/widgets/comment_sheet.dart
