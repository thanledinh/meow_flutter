import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../api/pet_api.dart';
import '../../api/api_client.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/toast.dart';
import 'widgets/edit_pet_bottom_sheet.dart';
import 'widgets/add_weight_bottom_sheet.dart';

class PetDetailScreen extends StatefulWidget {
  final dynamic petId;
  const PetDetailScreen({super.key, required this.petId});
  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  Map<String, dynamic>? _pet;
  bool _loading = true;
  bool _uploadingAvatar = false;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    final res = await PetApi.getById(widget.petId);
    if (!mounted) return;
    setState(() { _pet = (res.data as Map?)?['data'] ?? res.data as Map<String, dynamic>?; _loading = false; });
  }

  String _img(String? url) => url == null ? '' : ((url.startsWith('http') ? url : '${ApiConfig.baseUrl}$url') + '?v=${DateTime.now().millisecondsSinceEpoch}');

  // ═══ Avatar Upload ═══
  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Chọn ảnh đại diện', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.camera_alt, color: MoewColors.primary),
            title: Text('Chụp ảnh', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: Icon(Icons.photo_library, color: MoewColors.secondary),
            title: Text('Chọn từ thư viện', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ]),
      )),
    );

    if (source == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 800, imageQuality: 80);
    if (picked == null) return;

    setState(() => _uploadingAvatar = true);
    final bytes = await File(picked.path).readAsBytes();
    final b64 = base64Encode(bytes);

    final res = await PetApi.uploadAvatar(widget.petId, b64);
    if (!mounted) return;
    setState(() => _uploadingAvatar = false);
    if (res.success) {
      MoewToast.show(context, message: 'Đã cập nhật ảnh!', type: ToastType.success);
      _fetch();
    } else {
      MoewToast.show(context, message: res.error ?? 'Lỗi upload', type: ToastType.error);
    }
  }

  // ═══ Edit Pet Info ═══
  Future<void> _showEditPet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => EditPetBottomSheet(
        petId: widget.petId,
        petData: _pet!,
        onSaved: _fetch,
      ),
    );
  }

  // ═══ Add Weight ═══
  Future<void> _showAddWeight() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => AddWeightBottomSheet(
        petId: widget.petId,
        onSaved: _fetch,
      ),
    );
  }
  // ═══ Delete Pet ═══
  Future<void> _deletePet() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xóa thú cưng?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Bạn chắc chắn muốn xóa ${_pet!['name']}? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Xóa', style: TextStyle(color: MoewColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final res = await PetApi.delete(widget.petId);
    if (!mounted) return;
    if (res.success) {
      MoewToast.show(context, message: 'Đã xóa!', type: ToastType.success);
      Navigator.pop(context, true); // pop back to pet list
    } else {
      MoewToast.show(context, message: res.error ?? 'Lỗi', type: ToastType.error);
    }
  }

  // ═══ BUILD ═══
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: AppHeader(
        title: 'Chi tiết thú cưng',
        actions: _pet != null
            ? [
                IconButton(onPressed: _showEditPet, icon: Icon(Icons.edit_outlined, size: 20, color: MoewColors.primary)),
                IconButton(onPressed: _deletePet, icon: Icon(Icons.delete_outline, size: 20, color: MoewColors.danger)),
              ]
            : null,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: MoewColors.primary))
          : _pet == null
              ? EmptyState(icon: Icons.pets, color: MoewColors.textSub, message: 'Không tìm thấy')
              : ListView(padding: EdgeInsets.all(MoewSpacing.lg), children: [
                  // ═══ Avatar ═══
                  Center(child: Column(children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(children: [
                        _pet!['avatar'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(55),
                                child: CachedNetworkImage(imageUrl: _img(_pet!['avatar']), width: 110, height: 110, fit: BoxFit.cover),
                              )
                            : Container(
                                width: 110, height: 110,
                                decoration: BoxDecoration(color: MoewColors.secondary, borderRadius: BorderRadius.circular(55)),
                                child: Icon(Icons.pets, size: 48, color: Colors.white),
                              ),
                        Positioned(
                          right: 0, bottom: 0,
                          child: Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              color: MoewColors.primary, borderRadius: BorderRadius.circular(17),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: _uploadingAvatar
                                ? Padding(padding: EdgeInsets.all(6), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ),
                      ]),
                    ),
                    SizedBox(height: 12),
                    Text(_pet!['name'] ?? '', style: MoewTextStyles.h2),
                    StatusBadge(
                      label: _pet!['species'] == 'cat' ? 'Mèo' : (_pet!['species'] == 'dog' ? 'Chó' : _pet!['species'] ?? ''),
                      color: _pet!['species'] == 'cat' ? MoewColors.secondary : MoewColors.primary,
                      icon: Icons.pets,
                    ),
                  ])),
                  SizedBox(height: MoewSpacing.xl),

                  // ═══ Info Card ═══
                  _card([
                    _row('Giống', _pet!['breed'] ?? 'Chưa rõ'),
                    _row('Giới tính', _pet!['gender'] == 'male' ? 'Đực' : (_pet!['gender'] == 'female' ? 'Cái' : _pet!['gender'] ?? 'Chưa rõ')),
                    _row('Màu lông', _pet!['color'] ?? 'Chưa rõ'),
                    if (_pet!['birthDate'] != null) _row('Ngày sinh', () {
      try {
        final str = _pet!['birthDate'].toString();
        if (RegExp(r'^\d{2}[-/]\d{2}[-/]\d{4}').hasMatch(str)) return str.replaceAll('-', '/');
        final d = DateTime.parse(str);
        return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      } catch (_) {
        return _pet!['birthDate'].toString().length >= 10 ? _pet!['birthDate'].toString().substring(0, 10) : _pet!['birthDate'].toString();
      }
    }()),
                    if (_pet!['features'] != null && _pet!['features'].toString().isNotEmpty) _row('Đặc điểm', _pet!['features'].toString()),
                  ]),
                  SizedBox(height: MoewSpacing.md),

                  // ═══ Weight Section ═══
                  Container(
                    padding: EdgeInsets.all(MoewSpacing.md),
                    decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.card),
                    child: Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: MoewColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(MoewRadius.sm)),
                        child: Icon(Icons.monitor_weight, size: 22, color: MoewColors.accent),
                      ),
                      SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Cân nặng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: MoewColors.textMain)),
                        Text(_pet!['weight'] != null ? '${_pet!['weight']} kg' : 'Chưa cập nhật', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _pet!['weight'] != null ? MoewColors.accent : MoewColors.textSub)),
                      ])),
                      ElevatedButton.icon(
                        onPressed: _showAddWeight,
                        icon: Icon(Icons.add, size: 16, color: Colors.white),
                        label: Text('Cân mới', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: MoewColors.accent, padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      ),
                    ]),
                  ),

                  // ═══ Notes ═══
                  if (_pet!['notes'] != null && _pet!['notes'].toString().isNotEmpty) ...[
                    SizedBox(height: MoewSpacing.md),
                    Container(
                      padding: EdgeInsets.all(MoewSpacing.md),
                      decoration: BoxDecoration(color: MoewColors.tintYellow, borderRadius: BorderRadius.circular(MoewRadius.lg)),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.note_outlined, size: 20, color: MoewColors.secondary),
                        SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('GHI CHÚ', style: MoewTextStyles.label),
                          SizedBox(height: 4),
                          Text(_pet!['notes'].toString(), style: MoewTextStyles.body),
                        ])),
                      ]),
                    ),
                  ],
                  SizedBox(height: MoewSpacing.md),

                  // ═══ Quick Links ═══
                  _actionRow('Theo dõi cân nặng', Icons.monitor_weight_outlined, MoewColors.accent, () => Navigator.pushNamed(context, '/pet-weight', arguments: widget.petId)),
                  _actionRow('Lịch tiêm chủng', Icons.vaccines_outlined, MoewColors.success, () => Navigator.pushNamed(context, '/pet-vaccines', arguments: widget.petId)),
                  _actionRow('Hồ sơ y tế', Icons.medical_services_outlined, MoewColors.primary, () => Navigator.pushNamed(context, '/medical', arguments: widget.petId)),
                  _actionRow('Lịch sử ăn', Icons.restaurant_outlined, MoewColors.secondary, () => Navigator.pushNamed(context, '/food-history', arguments: widget.petId)),
                ]),
    );
  }

  // ═══ Helpers ═══
  Widget _card(List<Widget> children) => Container(
    padding: EdgeInsets.all(MoewSpacing.md),
    decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.card),
    child: Column(children: children),
  );

  Widget _row(String label, String value) => Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: MoewTextStyles.caption),
      Flexible(child: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: MoewColors.textMain), textAlign: TextAlign.end)),
    ]),
  );

  Widget _actionRow(String label, IconData icon, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: EdgeInsets.only(bottom: MoewSpacing.sm),
      padding: EdgeInsets.all(MoewSpacing.md),
      decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.card),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(MoewRadius.sm)), child: Icon(icon, size: 20, color: color)),
        SizedBox(width: MoewSpacing.md),
        Expanded(child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: MoewColors.textMain))),
        Icon(Icons.chevron_right, size: 20, color: MoewColors.textSub),
      ]),
    ),
  );
}
