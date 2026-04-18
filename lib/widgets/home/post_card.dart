import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../api/api_client.dart';
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/feed_repository.dart';
import '../comment_sheet.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final int index;

  const PostCard({super.key, required this.post, required this.index});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _formatPostTime(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  void _openComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentSheet(
        post: widget.post.toJson(),
        onCommentAdded: () {
          context.read<FeedRepository>().incrementComment(widget.post.id);
        },
      ),
    );
  }

  Widget _actionButton(IconData icon, Color color, String count, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            if (count != '0') ...[
              const SizedBox(width: 4),
              Text(count, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Selector<FeedRepository, PostModel>(
      selector: (_, repo) => repo.posts.firstWhere((p) => p.id == widget.post.id, orElse: () => widget.post),
      builder: (context, currentPost, _) {
        final author = currentPost.author;
        final userAvatarStr = author?.avatarUrl ?? '';
        final userName = author?.displayName ?? 'Moew User';
        final isMyPost = author?.id == context.read<AuthProvider>().user?['id'];
        
        final avatarUrl = ApiConfig.parseImageUrl(userAvatarStr);
        final images = currentPost.mediaUrls;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 10)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (author?.id != null) context.push('/public-profile', extra: author!.id);
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: MoewColors.accent.withOpacity(0.2),
                          backgroundImage: userAvatarStr.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
                          child: userAvatarStr.isEmpty ? Icon(Icons.person, color: MoewColors.primary, size: 20) : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (author?.id != null) context.push('/public-profile', extra: author!.id);
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(child: Text(userName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: MoewColors.textMain), overflow: TextOverflow.ellipsis)),
                                  if (currentPost.createdAt != null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatPostTime(currentPost.createdAt),
                                      style: TextStyle(fontSize: 13, color: MoewColors.textSub),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                (currentPost.petTags?.isNotEmpty ?? false)
                                    ? currentPost.petTags!.map((t) => t['name']?.toString() ?? 'Pet').join(', ')
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
                              final res = await context.push('/edit-post', extra: currentPost.toJson());
                              if (res == true) context.read<FeedRepository>().fetchFeed(refresh: true);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(children: [
                                Icon(Icons.edit, size: 20, color: MoewColors.textMain),
                                const SizedBox(width: 10),
                                const Text('Sửa bài viết'),
                              ]),
                            ),
                          ],
                        )
                      else
                        Icon(Icons.more_horiz, color: MoewColors.textMain, size: 22),
                    ],
                  ),
                ),
                  
                // Images
                if (images.isNotEmpty)
                  Builder(
                    builder: (ctx) {
                      final pageNotifier = ValueNotifier<int>(0);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: SizedBox(
                            height: 280,
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
                                      memCacheWidth: 600, // Cứu rỗi RAM máy yếu
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
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.85),
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 4))
                                          ],
                                        ),
                                        child: Text(
                                          '${page + 1}/${images.length}',
                                          style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w800),
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
                  
                // Actions bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      _actionButton(
                        currentPost.isLiked ? Icons.favorite : Icons.favorite_border,
                        currentPost.isLiked ? Colors.red : MoewColors.textSub,
                        '${currentPost.likeCount}',
                        onTap: () => context.read<FeedRepository>().toggleLike(currentPost.id),
                      ),
                      const SizedBox(width: 24),
                      _actionButton(
                        Icons.chat_bubble_outline,
                        MoewColors.textSub,
                        '${currentPost.commentCount}',
                        onTap: () => _openComments(context),
                      ),
                      const Spacer(),
                      Icon(Icons.bookmark_border, size: 22, color: MoewColors.textSub),
                    ],
                  ),
                ),

                // Caption
                if (currentPost.content?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16),
                    child: Text(currentPost.content!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: MoewColors.textSub, height: 1.4)),
                  ),
              ],
            ),
          ),
        );
      }
    );
  }
}
