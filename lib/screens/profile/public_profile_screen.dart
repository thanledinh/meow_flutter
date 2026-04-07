import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../api/auth_api.dart';
import '../../api/api_client.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/toast.dart';

class PublicProfileScreen extends StatefulWidget {
  final dynamic userId;
  const PublicProfileScreen({super.key, required this.userId});
  
  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _isFollowing = false;
  bool _toggleLoading = false;

  @override
  void initState() { 
    super.initState(); 
    _fetch(); 
  }

  Future<void> _fetch() async {
    final res = await AuthApi.getPublicProfile(widget.userId);
    if (!mounted) return;
    setState(() {
      final data = (res.data as Map?)?['data'] ?? res.data as Map<String, dynamic>?;
      _profile = data;
      _isFollowing = data?['isFollowing'] == true; // Assuming API returns 'isFollowing'
      _loading = false;
    });
  }

  Future<void> _toggleFollow() async {
    setState(() => _toggleLoading = true);
    final res = await AuthApi.toggleFollow(widget.userId);
    
    if (!mounted) return;
    setState(() => _toggleLoading = false);
    
    if (res.success) {
      final isNowFollowing = (res.data as Map?)?['data']?['isFollowing'] ?? !_isFollowing;
      setState(() {
        _isFollowing = isNowFollowing;
        // Optimistic count update
        if (_profile != null) {
          int count = _profile!['followerCount'] ?? 0;
          _profile!['followerCount'] = _isFollowing ? count + 1 : (count > 0 ? count - 1 : 0);
        }
      });
      MoewToast.show(context, message: _isFollowing ? 'Đang theo dõi!' : 'Đã huỷ theo dõi!', type: ToastType.success);
    } else {
      MoewToast.show(context, message: res.error ?? 'Lỗi', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: AppHeader(title: 'Trang cá nhân'),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: MoewColors.primary))
          : _profile == null
              ? EmptyState(icon: Icons.person_off, color: MoewColors.textSub, message: 'Người dùng không tồn tại')
              : RefreshIndicator(
                  onRefresh: _fetch,
                  color: MoewColors.primary,
                  child: ListView(padding: EdgeInsets.all(MoewSpacing.lg), children: [
                    Center(child: Column(children: [
                      _profile!['avatar'] != null && _profile!['avatar'].toString().isNotEmpty
                          ? ClipRRect(borderRadius: BorderRadius.circular(50), child: CachedNetworkImage(imageUrl: _profile!['avatar'].toString().startsWith('http') ? _profile!['avatar'] : '${ApiConfig.baseUrl}${_profile!['avatar']}', width: 100, height: 100, fit: BoxFit.cover))
                          : Container(width: 100, height: 100, decoration: BoxDecoration(color: MoewColors.primary, borderRadius: BorderRadius.circular(50)), child: Icon(Icons.person, size: 48, color: Colors.white)),
                      SizedBox(height: 12),
                      Text(_profile!['displayName'] ?? 'Người dùng', style: MoewTextStyles.h2),
                      
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _statBox('${_profile!['followingCount'] ?? 0}', 'Đang theo dõi'),
                          Container(width: 1, height: 30, color: MoewColors.border, margin: EdgeInsets.symmetric(horizontal: 20)),
                          _statBox('${_profile!['followerCount'] ?? 0}', 'Người theo dõi'),
                        ],
                      ),
                      
                      SizedBox(height: 16),
                      // Follow Button
                      SizedBox(
                        width: 160,
                        child: ElevatedButton(
                          onPressed: _toggleLoading ? null : _toggleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFollowing ? MoewColors.surface : MoewColors.primary,
                            foregroundColor: _isFollowing ? MoewColors.textMain : Colors.white,
                            side: _isFollowing ? BorderSide(color: MoewColors.border) : BorderSide.none,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: _isFollowing ? 0 : 2,
                          ),
                          child: _toggleLoading 
                            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _isFollowing ? MoewColors.textMain : Colors.white))
                            : Text(_isFollowing ? 'Đang theo dõi' : 'Theo dõi', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      
                      if (_profile!['bio'] != null && _profile!['bio'].toString().isNotEmpty) 
                        Padding(padding: EdgeInsets.only(top: 20), child: Text(_profile!['bio'], style: MoewTextStyles.body, textAlign: TextAlign.center)),
                    ])),
                    SizedBox(height: MoewSpacing.xl),
                    _infoCard('Email', _profile!['email'] ?? 'Đang cập nhật', Icons.mail_outline),
                    _infoCard('Điện thoại', _profile!['phone'] ?? 'Chưa cập nhật', Icons.phone_outlined),
                    _infoCard('Địa chỉ', _profile!['address'] ?? 'Chưa cập nhật', Icons.location_on_outlined),
                  ]),
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

  Widget _infoCard(String label, String value, IconData icon) {
    if (value.isEmpty || value == 'Chưa cập nhật') return SizedBox.shrink();
    return Container(
      margin: EdgeInsets.only(bottom: MoewSpacing.sm),
      padding: EdgeInsets.all(MoewSpacing.md),
      decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.card),
      child: Row(children: [
        Icon(icon, size: 20, color: MoewColors.primary),
        SizedBox(width: MoewSpacing.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: MoewTextStyles.label),
          SizedBox(height: 4),
          Text(value, style: MoewTextStyles.body),
        ])),
      ]),
    );
  }
}
