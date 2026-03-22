import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../api/auth_api.dart';
import '../../api/api_client.dart';
import '../../widgets/common_widgets.dart';

class PublicProfileScreen extends StatefulWidget {
  const PublicProfileScreen({super.key});
  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    final res = await AuthApi.getProfile();
    if (!mounted) return;
    setState(() {
      _profile = (res.data as Map?)?['data'] ?? res.data as Map<String, dynamic>?;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: const AppHeader(title: 'Trang công khai'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MoewColors.primary))
          : _profile == null
              ? const EmptyState(icon: Icons.person_off, color: MoewColors.textSub, message: 'Không thể tải')
              : ListView(padding: const EdgeInsets.all(MoewSpacing.lg), children: [
                  Center(child: Column(children: [
                    _profile!['avatar'] != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(50), child: CachedNetworkImage(imageUrl: _profile!['avatar'].toString().startsWith('http') ? _profile!['avatar'] : '${ApiConfig.baseUrl}${_profile!['avatar']}', width: 100, height: 100, fit: BoxFit.cover))
                        : Container(width: 100, height: 100, decoration: BoxDecoration(color: MoewColors.primary, borderRadius: BorderRadius.circular(50)), child: const Icon(Icons.person, size: 48, color: Colors.white)),
                    const SizedBox(height: 12),
                    Text(_profile!['displayName'] ?? '', style: MoewTextStyles.h2),
                    if (_profile!['bio'] != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_profile!['bio'], style: MoewTextStyles.body, textAlign: TextAlign.center)),
                  ])),
                  const SizedBox(height: MoewSpacing.xl),
                  _infoCard('Email', _profile!['email'] ?? '', Icons.mail_outline),
                  _infoCard('Điện thoại', _profile!['phone'] ?? 'Chưa cập nhật', Icons.phone_outlined),
                  _infoCard('Địa chỉ', _profile!['address'] ?? 'Chưa cập nhật', Icons.location_on_outlined),
                ]),
    );
  }

  Widget _infoCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: MoewSpacing.sm),
      padding: const EdgeInsets.all(MoewSpacing.md),
      decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.card),
      child: Row(children: [
        Icon(icon, size: 20, color: MoewColors.primary),
        const SizedBox(width: MoewSpacing.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: MoewTextStyles.label),
          const SizedBox(height: 4),
          Text(value, style: MoewTextStyles.body),
        ])),
      ]),
    );
  }
}
