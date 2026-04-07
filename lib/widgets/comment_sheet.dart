import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../api/api_client.dart';
import '../api/feed_api.dart';
import '../widgets/toast.dart';

class CommentSheet extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback? onCommentAdded;

  const CommentSheet({super.key, required this.post, this.onCommentAdded});

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  bool _sending = false;
  final TextEditingController _ctrl = TextEditingController();
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _fetchComments({bool refresh = false}) async {
    if (refresh) _page = 1;
    setState(() => _loading = true);
    final res = await FeedApi.getComments(widget.post['id'], page: _page);
    if (!mounted) return;
    if (res.success) {
      final data = (res.data as Map?)
          ?['data'] as Map<String, dynamic>?;
      final list = (data?['comments'] as List? ?? [])
          .cast<Map<String, dynamic>>();

      setState(() {
        if (refresh || _page == 1) {
          _comments..clear()..addAll(list);
        } else {
          _comments.addAll(list);
        }
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);

    final res = await FeedApi.addComment(
        widget.post['id'], {'content': text});
    if (!mounted) return;

    if (res.success) {
      _ctrl.clear();
      final newComment = (res.data as Map?)
          ?['data'] as Map<String, dynamic>?;
      if (newComment != null) {
        setState(() => _comments.insert(0, newComment));
      }
      widget.onCommentAdded?.call();
    } else {
      final errCode = res.error ?? '';
      final errMsg = {
        'EMPTY_CONTENT': 'Bình luận không được để trống',
        'TOO_LONG': 'Bình luận tối đa 1000 ký tự',
        'POST_NOT_FOUND': 'Bài đăng không còn tồn tại',
      }[errCode] ?? 'Gửi bình luận thất bại';
      MoewToast.show(context, message: errMsg, type: ToastType.error);
    }
    setState(() => _sending = false);
  }

  Future<void> _deleteComment(Map<String, dynamic> comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xóa bình luận?'),
        content: Text('Bình luận sẽ bị xóa vĩnh viễn.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Hủy')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Xóa',
                  style: TextStyle(color: MoewColors.danger))),
        ],
      ),
    );
    if (confirmed != true) return;

    final res = await FeedApi.deleteComment(
        widget.post['id'], comment['id']);
    if (!mounted) return;
    if (res.success) {
      setState(() => _comments.remove(comment));
    } else {
      final errCode = res.error ?? '';
      final errMsg = {
        'COMMENT_NOT_FOUND': 'Bình luận không tồn tại',
        'FORBIDDEN': 'Bạn không có quyền xóa bình luận này',
      }[errCode] ?? 'Xóa thất bại';
      MoewToast.show(context, message: errMsg, type: ToastType.error);
    }
  }

  String _timeAgo(String dateStr) {
    try {
      final diff = DateTime.now().difference(DateTime.parse(dateStr).toLocal());
      if (diff.inDays > 0) return '${diff.inDays}n';
      if (diff.inHours > 0) return '${diff.inHours}h';
      if (diff.inMinutes > 0) return '${diff.inMinutes}p';
      return 'Vừa';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: MoewColors.border,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Text('Bình luận',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                      color: MoewColors.textMain)),
              Spacer(),
              Text('${widget.post['commentCount'] ?? _comments.length} bình luận',
                  style: TextStyle(fontSize: 13, color: MoewColors.textSub)),
            ]),
          ),
          SizedBox(height: 8),
          Divider(height: 1, color: MoewColors.border),

          // ── Comment List ──────────────────────────────────
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: MoewColors.primary))
                : _comments.isEmpty
                    ? Center(
                        child: Text('Chưa có bình luận nào.\nHãy là người đầu tiên! 🐾',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: MoewColors.textSub, fontSize: 14)))
                    : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _comments.length,
                        itemBuilder: (ctx, i) => _buildCommentItem(_comments[i]),
                      ),
          ),

          // ── Input Box ────────────────────────────────────
          Divider(height: 1, color: MoewColors.border),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _ctrl,
              enabled: !_sending,
              minLines: 1,
              maxLines: 4,
              maxLength: 1000,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendComment(),
              buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
              decoration: InputDecoration(
                hintText: 'Viết bình luận...',
                hintStyle: TextStyle(color: MoewColors.textSub, fontSize: 14),
                filled: true,
                fillColor: MoewColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: MoewColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: MoewColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: MoewColors.primary),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final user = comment['user'] as Map<String, dynamic>? ?? {};
    final avatar = user['avatar']?.toString() ?? '';
    final avatarUrl = ApiConfig.parseImageUrl(avatar);
    final isOwner = comment['isOwner'] as bool? ?? false;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: MoewColors.accent,
          backgroundImage: avatar.isNotEmpty
              ? CachedNetworkImageProvider(avatarUrl) : null,
          child: avatar.isEmpty
              ? Icon(Icons.person, size: 16, color: Colors.white) : null,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: MoewColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user['displayName']?.toString() ?? 'Moew User',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                        color: MoewColors.textMain)),
                SizedBox(height: 2),
                Text(comment['content']?.toString() ?? '',
                    style: TextStyle(fontSize: 14, color: MoewColors.textMain)),
              ]),
            ),
            Padding(
              padding: EdgeInsets.only(left: 8, top: 2),
              child: Row(children: [
                Text(_timeAgo(comment['createdAt']?.toString() ?? ''),
                    style: TextStyle(fontSize: 11, color: MoewColors.textSub)),
                if (isOwner) ...[
                  SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _deleteComment(comment),
                    child: Text('Xóa',
                        style: TextStyle(fontSize: 11, color: MoewColors.danger,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}
