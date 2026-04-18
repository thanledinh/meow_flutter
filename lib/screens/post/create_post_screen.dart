import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../api/post_api.dart';
import '../../api/pet_api.dart';
import '../../api/api_client.dart';
import '../../widgets/toast.dart';
import '../../providers/auth_provider.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});
  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  final List<XFile> _selectedImages = [];
  List<dynamic> _myPets = [];
  final Set<int> _selectedPetIds = {};
  
  bool _loadingPets = true;
  bool _submitting = false;
  String _visibility = 'public';

  @override
  void initState() {
    super.initState();
    _fetchPets();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _fetchPets() async {
    final res = await PetApi.getAll();
    if (!mounted) return;
    if (res.success) {
      final pList = (res.data as Map?)?['data'] as List<dynamic>? ?? [];
      setState(() {
        _myPets = pList;
        _loadingPets = false;
      });
    } else {
      setState(() => _loadingPets = false);
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> picked = await _picker.pickMultiImage(imageQuality: 70);
      if (picked.isNotEmpty) {
        setState(() {
          for (var img in picked) {
            // Check if image is already in the list to prevent duplicates
            if (!_selectedImages.any((existing) => existing.name == img.name && existing.path == img.path)) {
              _selectedImages.add(img);
            }
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      MoewToast.show(context, message: 'Lỗi chọn ảnh: ${e.toString()}', type: ToastType.error);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (photo != null) {
        setState(() {
          if (!_selectedImages.any((existing) => existing.name == photo.name && existing.path == photo.path)) {
            _selectedImages.add(photo);
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      MoewToast.show(context, message: 'Lỗi mở máy ảnh: ${e.toString()}', type: ToastType.error);
    }
  }



  Future<void> _submit() async {
    if (_captionController.text.trim().isEmpty && _selectedImages.isEmpty) {
      MoewToast.show(context, message: 'Hãy nhập nội dung hoặc chọn ảnh', type: ToastType.info);
      return;
    }

    setState(() => _submitting = true);
    
    try {
      List<String> base64Images = [];
      for (var f in _selectedImages) {
        final bytes = await f.readAsBytes();
        final b64 = base64Encode(bytes);
        base64Images.add('data:image/jpeg;base64,$b64');
      }

      final res = await PostApi.createPost(
        caption: _captionController.text.trim(),
        images: base64Images,
        petIds: _selectedPetIds.toList(),
        // Note: Adding parameter through dynamic/map if not available in createPost or we need to update post_api as well. 
      );

      if (!mounted) return;
      
      if (res.success) {
        MoewToast.show(context, message: 'Đã đăng bài viết! 🎉', type: ToastType.success);
        Navigator.pop(context, true);
      } else {
        MoewToast.show(context, message: res.error ?? 'Đăng bài thất bại', type: ToastType.error);
        setState(() => _submitting = false);
      }
    } catch (e) {
      if (!mounted) return;
      MoewToast.show(context, message: 'Lỗi tải ảnh. Vui lòng thử lại.', type: ToastType.error);
      setState(() => _submitting = false);
    }
  }

  void _showPetSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text('Gắn thẻ thú cưng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: MoewColors.textMain)),
                  ),
                  if (_loadingPets)
                    Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: MoewColors.primary)))
                  else if (_myPets.isEmpty)
                    Padding(padding: EdgeInsets.all(20), child: Text('Bạn chưa có thú cưng nào', style: TextStyle(color: MoewColors.textSub)))
                  else
                    ..._myPets.map((p) {
                      final petId = p['id'] as int;
                      final isSelected = _selectedPetIds.contains(petId);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: MoewColors.background,
                          child: Icon(Icons.pets, color: isSelected ? MoewColors.primary : MoewColors.textSub, size: 20),
                        ),
                        title: Text(p['name']?.toString() ?? 'Pet', style: TextStyle(fontWeight: FontWeight.w600)),
                        trailing: isSelected ? Icon(Icons.check_circle, color: MoewColors.primary) : Icon(Icons.circle_outlined, color: MoewColors.border),
                        onTap: () {
                          setModalState(() {
                            if (isSelected) _selectedPetIds.remove(petId);
                            else _selectedPetIds.add(petId);
                          });
                          setState(() {}); // Update main screen too
                        },
                      );
                    }).toList(),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildEmptyMediaPlaceholders() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          _buildActionItem(Icons.photo_library_outlined, 'Thư viện', _pickImages),
          SizedBox(width: 8),
          _buildActionItem(Icons.photo_camera_outlined, 'Máy ảnh', _takePhoto),
          SizedBox(width: 8),
          _buildActionItem(Icons.pets, 'Thú cưng', _showPetSelector),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 95,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: Offset(0, 2),
            )
          ]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: Colors.black87),
            SizedBox(height: 4),
            Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87)),
          ],
        ),
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

  Widget _buildMediaGrid() {
    return Stack(
      children: [
        _buildFacebookGrid(),
        Positioned(
          top: 8, left: 8,
          child: Row(
            children: [
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(6)),
                  child: Row(
                    children: [
                      Icon(Icons.add_photo_alternate, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text('Thêm file phương tiện', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 8, right: 8,
          child: GestureDetector(
            onTap: () => setState(() => _selectedImages.clear()),
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
              child: Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildFacebookGrid() {
    final count = _selectedImages.length;
    final spacing = 2.0;

    if (count == 1) {
      return Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: 500),
        child: _buildImage(0)
      );
    }
    if (count == 2) {
      return AspectRatio(
        aspectRatio: 1,
        child: Row(
          children: [
            Expanded(child: _buildImage(0)),
            SizedBox(width: spacing),
            Expanded(child: _buildImage(1)),
          ],
        ),
      );
    }
    // 3 or more
    return AspectRatio(
      aspectRatio: 1,
      child: Row(
        children: [
          Expanded(child: _buildImage(0)),
          SizedBox(width: spacing),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildImage(1)),
                SizedBox(height: spacing),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImage(2),
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

  void _openImageGallery(int initialIndex) {
    int currentIndex = initialIndex;
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => StatefulBuilder(
        builder: (context, setGalleryState) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: IconThemeData(color: Colors.white),
              title: Text('${currentIndex + 1} / ${_selectedImages.length}', style: TextStyle(color: Colors.white, fontSize: 16)),
              centerTitle: true,
            ),
            body: PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: _selectedImages.length,
              onPageChanged: (idx) {
                setGalleryState(() => currentIndex = idx);
              },
              itemBuilder: (context, index) {
                return Center(
                  child: InteractiveViewer(
                    child: Image.file(File(_selectedImages[index].path), fit: BoxFit.contain),
                  ),
                );
              },
            ),
          );
        }
      ),
    ));
  }

  Widget _buildImage(int index) {
    return GestureDetector(
      onTap: () => _openImageGallery(index),
      child: Image.file(
        File(_selectedImages[index].path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get user info from Provider
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final userName = user?['displayName']?.toString() ?? 'Người dùng';
    final rawAvatar = user?['avatar']?.toString() ?? '';
    final avatarUrl = ApiConfig.parseImageUrl(rawAvatar);

    final hasContent = _captionController.text.trim().isNotEmpty || _selectedImages.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close, color: MoewColors.textMain),
          onPressed: () => context.pop(),
        ),
        title: Text('Tạo bài viết mới', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: MoewColors.textMain)),
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
                                  SizedBox(width: 8),
                                  _buildHeaderChip(Icons.pets, 'Gắn thẻ thú cưng', _showPetSelector),
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
                        onChanged: (_) => setState(() {}),
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

                    // Active Pet Tags
                    if (_selectedPetIds.isNotEmpty) ...[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          spacing: 8, runSpacing: 8,
                          children: _myPets.where((p) => _selectedPetIds.contains(p['id'])).map((p) {
                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: MoewColors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: MoewColors.accent.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.pets, size: 14, color: MoewColors.accent),
                                  SizedBox(width: 6),
                                  Text(p['name']?.toString() ?? 'Pet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: MoewColors.accent)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],

                    // Phần 3: Media Grid (If has images)
                    if (_selectedImages.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: _buildMediaGrid(),
                      )
                  ],
                ),
              ),
            ),
            
            // Fixed placeholders at the bottom (If empty)
            if (_selectedImages.isEmpty)
              Padding(
                padding: EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: _buildEmptyMediaPlaceholders(),
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
                  GestureDetector(
                    onTap: _takePhoto,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 16, color: Colors.black87),
                          SizedBox(width: 6),
                          Text('Chụp ảnh', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
                        ],
                      ),
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
                        : Text('Đăng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
        context.pop();
      },
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
