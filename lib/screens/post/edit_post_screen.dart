import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../api/post_api.dart';
import '../../api/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/toast.dart';

class EditPostScreen extends StatefulWidget {
  final Map<String, dynamic> post;
  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final TextEditingController _captionController = TextEditingController();
  String _visibility = 'public';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _captionController.text = widget.post['caption']?.toString() ?? '';
    _visibility = widget.post['visibility']?.toString() ?? 'public';
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final res = await PostApi.updatePost(
        widget.post['id'],
        caption: _captionController.text.trim(),
        visibility: _visibility,
      );

      if (!mounted) return;
      if (res.success) {
        MoewToast.show(context, message: 'Cập nhật thành công! 🎉', type: ToastType.success);
        Navigator.pop(context, true);
      } else {
        MoewToast.show(context, message: res.error ?? 'Cập nhật thất bại', type: ToastType.error);
        setState(() => _submitting = false);
      }
    } catch (e) {
      if (!mounted) return;
      MoewToast.show(context, message: 'Có lỗi xảy ra. Thử lại sau.', type: ToastType.error);
      setState(() => _submitting = false);
    }
  }

  Widget _buildFacebookGrid(List<String> images) {
    if (images.isEmpty) return SizedBox.shrink();
    
    final count = images.length;
    final spacing = 2.0;

    if (count == 1) {
      return Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: 500),
        child: _buildImage(0, images)
      );
    }
    if (count == 2) {
      return AspectRatio(
        aspectRatio: 1,
        child: Row(
          children: [
            Expanded(child: _buildImage(0, images)),
            SizedBox(width: spacing),
            Expanded(child: _buildImage(1, images)),
          ],
        ),
      );
    }
    // 3 or more
    return AspectRatio(
      aspectRatio: 1,
      child: Row(
        children: [
          Expanded(child: _buildImage(0, images)),
          SizedBox(width: spacing),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildImage(1, images)),
                SizedBox(height: spacing),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImage(2, images),
                      if (count > 3)
                        Container(
                          color: Colors.black54,
                          alignment: Alignment.center,
                          child: Text('+${count - 3}', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openImageGallery(int initialIndex, List<String> images) {
    int currentIndex = initialIndex;
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => StatefulBuilder(
        builder: (context, setGalleryState) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: IconThemeData(color: Colors.white),
              title: Text('${currentIndex + 1} / ${images.length}', style: TextStyle(color: Colors.white, fontSize: 16)),
              centerTitle: true,
            ),
            body: PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: images.length,
              onPageChanged: (idx) {
                setGalleryState(() => currentIndex = idx);
              },
              itemBuilder: (context, index) {
                return Center(
                  child: InteractiveViewer(
                    child: CachedNetworkImage(
                      imageUrl: ApiConfig.parseImageUrl(images[index]),
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Center(child: CircularProgressIndicator(color: Colors.white)),
                      errorWidget: (context, url, err) => Icon(Icons.error_outline, color: Colors.white, size: 40),
                    ),
                  ),
                );
              },
            ),
          );
        }
      ),
    ));
  }

  Widget _buildImage(int index, List<String> images) {
    return GestureDetector(
      onTap: () => _openImageGallery(index, images),
      child: CachedNetworkImage(
        imageUrl: ApiConfig.parseImageUrl(images[index]),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => Container(color: MoewColors.background),
        errorWidget: (context, url, err) => Container(color: MoewColors.background, child: Icon(Icons.error_outline)),
      ),
    );
  }

  Widget _buildHeaderChip(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.black87),
            SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final userName = user?['displayName']?.toString() ?? 'Người dùng';
    final rawAvatar = user?['avatar']?.toString() ?? '';
    final avatarUrl = ApiConfig.parseImageUrl(rawAvatar);

    final hasContent = _captionController.text.trim().isNotEmpty;
    final List<String> images = (widget.post['images'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close, color: MoewColors.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Sửa bài viết', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: MoewColors.textMain)),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {},
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phần 1: User Header Row
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: MoewColors.background,
                            backgroundImage: rawAvatar.isNotEmpty ? CachedNetworkImageProvider(avatarUrl) : null,
                            child: rawAvatar.isEmpty ? Icon(Icons.person, color: MoewColors.textSub) : null,
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black)),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  _buildHeaderChip(Icons.group, _getVisibilityLabel(), _showVisibilitySettings),
                                ],
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Phần 2: Caption Input
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _captionController,
                        maxLines: null,
                        minLines: 4,
                        textInputAction: TextInputAction.newline,
                        onChanged: (val) => setState(() {}),
                        style: TextStyle(fontSize: 17, color: Colors.black, height: 1.5, fontWeight: FontWeight.w400),
                        decoration: InputDecoration(
                          hintText: 'Bạn đang nghĩ gì?',
                          hintStyle: TextStyle(color: Colors.black54, fontSize: 17, fontWeight: FontWeight.w400),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    
                    // Phần 3: Media Grid (Disabled for Edit)
                    if (images.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Opacity(
                          opacity: 0.8,
                          child: _buildFacebookGrid(images),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: MoewColors.textSub),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('Không thể thay đổi hình ảnh để bảo vệ tính toàn vẹn của bài đăng.', 
                                  style: TextStyle(color: MoewColors.textSub, fontSize: 13)),
                            )
                          ]
                        ),
                      )
                    ]
                  ],
                ),
              ),
            ),
            
            // Phần 4: Bottom Action Bar - Visibility
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _showVisibilitySettings,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          Icon(_getVisibilityIcon(), size: 16, color: Colors.black87),
                          SizedBox(width: 6),
                          Text(_getVisibilityLabel(), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 16, color: Colors.black87),
                        SizedBox(width: 6),
                        Text('Tắt', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                      ],
                    ),
                  ),
                  Spacer(),
                  ElevatedButton(
                    onPressed: (!hasContent || _submitting) ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Lưu', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getVisibilityLabel() {
    switch (_visibility) {
      case 'followers': return 'Bạn bè';
      case 'private': return 'Chỉ mình tôi';
      default: return 'Cộng đồng';
    }
  }

  IconData _getVisibilityIcon() {
    switch (_visibility) {
      case 'followers': return Icons.group;
      case 'private': return Icons.lock;
      default: return Icons.public;
    }
  }

  void _showVisibilitySettings() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text('Ai có thể xem bài viết này?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: MoewColors.textMain)),
            ),
            _visibilityTile('public', 'Cộng đồng', 'Bất kỳ ai trên Moew', Icons.public),
            _visibilityTile('followers', 'Bạn bè', 'Chỉ những người theo dõi bạn', Icons.group),
            _visibilityTile('private', 'Chỉ mình tôi', 'Không hiển thị với ai khác', Icons.lock),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _visibilityTile(String value, String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(color: MoewColors.background, shape: BoxShape.circle),
        child: Icon(icon, color: MoewColors.textMain, size: 20),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: MoewColors.textMain)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: MoewColors.textSub)),
      trailing: _visibility == value ? Icon(Icons.check_circle, color: MoewColors.primary) : null,
      onTap: () {
        setState(() => _visibility = value);
        Navigator.pop(context);
      },
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
