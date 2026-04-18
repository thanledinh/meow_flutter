import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../api/auth_api.dart';
import '../../api/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/toast.dart';
import '../../widgets/common_widgets.dart';
import '../map/location_picker_screen.dart';

// ---------------------------------------------------------------------------
// Helper: đọc follower count an toàn từ Map
//   Ưu tiên: followerCount → followersCount → 0
//   Chấp nhận: int, num, String, null. Clamp âm về 0.
// ---------------------------------------------------------------------------
int _safeFollowerCount(Map<String, dynamic>? data) {
  if (data == null) return 0;
  final raw = data['followerCount'] ?? data['followersCount'];
  if (raw == null) return 0;
  if (raw is int) return raw < 0 ? 0 : raw;
  if (raw is num) return raw.toInt() < 0 ? 0 : raw.toInt();
  if (raw is String) {
    final parsed = int.tryParse(raw) ?? (double.tryParse(raw)?.toInt() ?? 0);
    return parsed < 0 ? 0 : parsed;
  }
  return 0;
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _wardCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _emergencyContactCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _zaloCtrl = TextEditingController();
  String? _gender;
  String? _dateOfBirth;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _loading = true);
    final res = await AuthApi.getProfile();
    if (!mounted) return;
    if (res.success) {
      final p = (res.data as Map?)?['data'] ?? res.data;
      if (p is Map<String, dynamic>) {
        setState(() {
          _profile = p;
          _nameCtrl.text = p['displayName'] ?? '';
          _bioCtrl.text = p['bio'] ?? '';
          _phoneCtrl.text = p['phone'] ?? '';
          _addressCtrl.text = p['address'] ?? '';
          _wardCtrl.text = p['ward'] ?? '';
          _districtCtrl.text = p['district'] ?? '';
          _cityCtrl.text = p['city'] ?? '';
          _emergencyContactCtrl.text = p['emergencyContact'] ?? '';
          _emergencyNameCtrl.text = p['emergencyName'] ?? '';
          _facebookCtrl.text = p['facebook'] ?? '';
          _zaloCtrl.text = p['zalo'] ?? '';
          _gender = p['gender'];
          _dateOfBirth = p['dateOfBirth']?.toString().substring(0, 10);
          _latitude = double.tryParse(p['latitude']?.toString() ?? '');
          _longitude = double.tryParse(p['longitude']?.toString() ?? '');
        });
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    final data = <String, dynamic>{
      'displayName': _nameCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'ward': _wardCtrl.text.trim(),
      'district': _districtCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'emergencyContact': _emergencyContactCtrl.text.trim(),
      'emergencyName': _emergencyNameCtrl.text.trim(),
      'facebook': _facebookCtrl.text.trim(),
      'zalo': _zaloCtrl.text.trim(),
    };
    if (_gender != null) data['gender'] = _gender;
    if (_dateOfBirth != null) data['dateOfBirth'] = _dateOfBirth;
    if (_latitude != null) data['latitude'] = _latitude;
    if (_longitude != null) data['longitude'] = _longitude;
    final res = await AuthApi.updateProfile(data);
    if (!mounted) return;
    if (res.success) {
      MoewToast.show(context, message: 'Đã cập nhật profile!', type: ToastType.success);
      _fetchProfile();
    } else {
      MoewToast.show(context, message: res.error ?? 'Lỗi cập nhật', type: ToastType.error);
    }
  }

  String _fullAvatar(String? avatar) {
    if (avatar == null) return '';
    return avatar.startsWith('http') ? avatar : '${ApiConfig.baseUrl}$avatar';
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Cập nhật ảnh đại diện', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle), child: Icon(Icons.photo_library, color: Colors.black87)),
              title: Text('Chọn từ thư viện'),
              onTap: () {
                context.pop();
                _pickAvatar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle), child: Icon(Icons.camera_alt, color: Colors.black87)),
              title: Text('Chụp ảnh mới'),
              onTap: () {
                context.pop();
                _pickAvatar(ImageSource.camera);
              },
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAvatar(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source, imageQuality: 70);
      
      if (image != null) {
        if (!mounted) return;
        // Hiển thị dialog xác nhận ảnh
        bool? confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Xác nhận ảnh đại diện', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Image.file(
                    File(image.path), 
                    width: 150, 
                    height: 150, 
                    fit: BoxFit.cover
                  ),
                ),
                SizedBox(height: 16),
                Text('Bạn muốn dùng ảnh này làm avatar?', textAlign: TextAlign.center),
              ],
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Hủy', style: TextStyle(color: Colors.red, fontSize: 16)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MoewColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                ),
                child: Text('Đồng ý', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );

        if (confirm != true) return; // Người dùng hủy

        setState(() => _loading = true);
        final bytes = await image.readAsBytes();
        final base64String = 'data:image/jpeg;base64,' + base64Encode(bytes);
        
        final res = await AuthApi.uploadAvatar(base64String);
        if (!mounted) return;
        
        if (res.success) {
          MoewToast.show(context, message: 'Đã cập nhật ảnh đại diện!', type: ToastType.success);
          await _fetchProfile();
          if (_profile != null) {
            Provider.of<AuthProvider>(context, listen: false).updateUser(_profile!);
          }
        } else {
          MoewToast.show(context, message: res.error ?? 'Lỗi tải ảnh', type: ToastType.error);
        }
        setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      MoewToast.show(context, message: 'Thao tác bị hủy hoặc lỗi: $e', type: ToastType.error);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _bioCtrl.dispose(); _phoneCtrl.dispose();
    _addressCtrl.dispose(); _wardCtrl.dispose(); _districtCtrl.dispose(); _cityCtrl.dispose();
    _emergencyContactCtrl.dispose(); _emergencyNameCtrl.dispose();
    _facebookCtrl.dispose(); _zaloCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: AppHeader(title: 'Hồ sơ cá nhân'),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: MoewColors.primary))
          : _profile == null
              ? EmptyState(icon: Icons.person_off, color: MoewColors.textSub, message: 'Không thể tải profile')
              : RefreshIndicator(
                  onRefresh: _fetchProfile,
                  color: MoewColors.primary,
                  child: ListView(
                    padding: EdgeInsets.all(MoewSpacing.lg),
                    children: [
                      // Avatar
                      Center(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _showAvatarPicker,
                              child: Stack(
                                children: [
                                  _profile!['avatar'] != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(50),
                                          child: CachedNetworkImage(
                                            imageUrl: _fullAvatar(_profile!['avatar']),
                                            width: 100, height: 100, fit: BoxFit.cover,
                                          ),
                                        )
                                      : Container(
                                          width: 100, height: 100,
                                          decoration: BoxDecoration(
                                            color: MoewColors.primary,
                                            borderRadius: BorderRadius.circular(50),
                                          ),
                                          child: Icon(Icons.person, size: 48, color: Colors.white),
                                        ),
                                  Positioned(
                                    bottom: 0,
                                    right: 4,
                                    child: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.grey.shade300, width: 1.5),
                                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                                      ),
                                      child: Icon(Icons.camera_alt, size: 16, color: MoewColors.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(_profile!['displayName'] ?? '', style: MoewTextStyles.h2),
                            Text(_profile!['email'] ?? '', style: MoewTextStyles.caption),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _statBox('${_profile!['followingCount'] ?? 0}', 'Đang theo dõi'),
                                Container(width: 1, height: 30, color: MoewColors.border, margin: EdgeInsets.symmetric(horizontal: 20)),
                                // Dùng helper để đọc follower count an toàn
                                _statBox('${_safeFollowerCount(_profile)}', 'Người theo dõi'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: MoewSpacing.xl),

                      // THÔNG TIN CƠ BẢN
                      _sectionTitle('THÔNG TIN CƠ BẢN'),
                      _formCard([
                        _field('Tên hiển thị', _nameCtrl, Icons.person_outline),
                        _field('Tiểu sử', _bioCtrl, Icons.info_outline),
                        _field('Số điện thoại', _phoneCtrl, Icons.phone_outlined, keyboardType: TextInputType.phone),
                        // Gender selector
                        Padding(
                          padding: EdgeInsets.only(bottom: MoewSpacing.md),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Giới tính', style: MoewTextStyles.label),
                            SizedBox(height: MoewSpacing.sm),
                            Wrap(spacing: 8, children: [
                              _genderChip('Nam', 'male'),
                              _genderChip('Nữ', 'female'),
                              _genderChip('Khác', 'other'),
                            ]),
                          ]),
                        ),
                        // Date of birth
                        Padding(
                          padding: EdgeInsets.only(bottom: MoewSpacing.md),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Ngày sinh', style: MoewTextStyles.label),
                            SizedBox(height: MoewSpacing.sm),
                            GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _dateOfBirth != null ? DateTime.tryParse(_dateOfBirth!) ?? DateTime(2000) : DateTime(2000),
                                  firstDate: DateTime(1950),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) setState(() => _dateOfBirth = date.toIso8601String().substring(0, 10));
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(color: MoewColors.surface, borderRadius: BorderRadius.circular(MoewRadius.md)),
                                child: Row(children: [
                                  Icon(Icons.cake_outlined, size: 20, color: MoewColors.textSub),
                                  SizedBox(width: 12),
                                  Text(_dateOfBirth ?? 'Chưa chọn', style: TextStyle(fontSize: 15, color: _dateOfBirth != null ? MoewColors.textMain : MoewColors.textSub)),
                                ]),
                              ),
                            ),
                          ]),
                        ),
                      ]),

                      // ĐỊA CHỈ
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _sectionTitle('ĐỊA CHỈ'),
                          TextButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push(context, MaterialPageRoute(
                                builder: (_) => LocationPickerScreen(
                                  initialLat: _latitude,
                                  initialLng: _longitude,
                                )
                              ));
                              if (result != null && result is Map<String, dynamic>) {
                                setState(() {
                                  _addressCtrl.text = result['address'] ?? '';
                                  _wardCtrl.text = result['ward'] ?? '';
                                  _districtCtrl.text = result['district'] ?? '';
                                  _cityCtrl.text = result['city'] ?? '';
                                  _latitude = result['latitude'];
                                  _longitude = result['longitude'];
                                });
                              }
                            },
                            icon: Icon(Icons.map, size: 18, color: MoewColors.primary),
                            label: Text('Mở bản đồ', style: TextStyle(color: MoewColors.primary, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                      _formCard([
                        _field('Địa chỉ', _addressCtrl, Icons.location_on_outlined),
                        _field('Phường/Xã', _wardCtrl, Icons.map_outlined),
                        _field('Quận/Huyện', _districtCtrl, Icons.location_city_outlined),
                        _field('Thành phố', _cityCtrl, Icons.apartment_outlined),
                      ]),

                      // LIÊN HỆ KHẨN CẤP
                      _sectionTitle('LIÊN HỆ KHẨN CẤP'),
                      _formCard([
                        _field('Tên người liên hệ', _emergencyNameCtrl, Icons.person_pin_outlined),
                        _field('SĐT khẩn cấp', _emergencyContactCtrl, Icons.phone_callback_outlined, keyboardType: TextInputType.phone),
                      ]),

                      // MẠNG XÃ HỘI
                      _sectionTitle('MẠNG XÃ HỘI'),
                      _formCard([
                        _field('Facebook', _facebookCtrl, Icons.facebook_outlined),
                        _field('Zalo', _zaloCtrl, Icons.chat_outlined, keyboardType: TextInputType.phone),
                      ]),

                      SizedBox(height: MoewSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(backgroundColor: MoewColors.primary, padding: EdgeInsets.symmetric(vertical: 16)),
                          child: Text('Lưu thay đổi', style: MoewTextStyles.button),
                        ),
                      ),
                      SizedBox(height: MoewSpacing.lg),

                      // eKYC & Delete
                      _actionTile('Xác minh danh tính (eKYC)', Icons.verified_outlined, MoewColors.success, () => context.push('/ekyc')),
                      SizedBox(height: MoewSpacing.sm),
                      _actionTile('Xóa tài khoản', Icons.delete_outline, MoewColors.danger, _confirmDelete),
                    ],
                  ),
                ),
    );
  }

  Widget _statBox(String value, String label) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: MoewColors.textMain)),
        SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: MoewColors.textSub, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: EdgeInsets.only(bottom: MoewSpacing.sm, top: MoewSpacing.sm),
    child: Text(title, style: MoewTextStyles.label),
  );

  Widget _formCard(List<Widget> children) => Container(
    padding: EdgeInsets.all(MoewSpacing.md),
    decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.card),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _genderChip(String label, String value) {
    final active = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? MoewColors.primary : MoewColors.surface,
          borderRadius: BorderRadius.circular(MoewRadius.md),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : MoewColors.textMain)),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, {TextInputType? keyboardType}) {
    return Padding(
      padding: EdgeInsets.only(bottom: MoewSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: MoewTextStyles.label),
          SizedBox(height: MoewSpacing.sm),
          TextField(
            controller: ctrl,
            keyboardType: keyboardType,
            decoration: InputDecoration(prefixIcon: Icon(icon, size: 20, color: MoewColors.textSub)),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(MoewSpacing.md),
        decoration: BoxDecoration(
          color: MoewColors.white,
          borderRadius: BorderRadius.circular(MoewRadius.lg),
          boxShadow: MoewShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(MoewRadius.sm),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            SizedBox(width: MoewSpacing.md),
            Expanded(child: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color))),
            Icon(Icons.chevron_right, size: 20, color: color),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xóa tài khoản'),
        content: Text('Hành động này không thể hoàn tác. Bạn chắc chắn?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Hủy')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await AuthApi.deleteAccount();
              if (!mounted) return;
              if (res.success) {
                context.read<AuthProvider>().onLogout();
                context.go('/login');
              } else {
                MoewToast.show(context, message: res.error ?? 'Lỗi', type: ToastType.error);
              }
            },
            child: Text('Xóa', style: TextStyle(color: MoewColors.danger)),
          ),
        ],
      ),
    );
  }
}
