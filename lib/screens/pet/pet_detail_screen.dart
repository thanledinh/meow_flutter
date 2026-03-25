import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../api/pet_api.dart';
import '../../api/api_client.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/toast.dart';

class PetDetailScreen extends StatefulWidget {
  final dynamic petId;
  const PetDetailScreen({super.key, required this.petId});
  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  Map<String, dynamic>? _pet;
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    final res = await PetApi.getById(widget.petId);
    if (!mounted) return;
    setState(() { _pet = (res.data as Map?)?['data'] ?? res.data as Map<String, dynamic>?; _loading = false; });
  }

  String _img(String? url) => url == null ? '' : (url.startsWith('http') ? url : '${ApiConfig.baseUrl}$url');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: const AppHeader(title: 'Chi tiết thú cưng'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MoewColors.primary))
          : _pet == null
              ? const EmptyState(icon: Icons.pets, color: MoewColors.textSub, message: 'Không tìm thấy')
              : ListView(padding: const EdgeInsets.all(MoewSpacing.lg), children: [
                  Center(child: Column(children: [
                    _pet!['avatar'] != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(50), child: CachedNetworkImage(imageUrl: _img(_pet!['avatar']), width: 100, height: 100, fit: BoxFit.cover))
                        : Container(width: 100, height: 100, decoration: BoxDecoration(color: MoewColors.secondary, borderRadius: BorderRadius.circular(50)), child: const Icon(Icons.pets, size: 48, color: Colors.white)),
                    const SizedBox(height: 12),
                    Text(_pet!['name'] ?? '', style: MoewTextStyles.h2),
                    StatusBadge(label: _pet!['species'] == 'cat' ? 'Mèo' : (_pet!['species'] == 'dog' ? 'Chó' : _pet!['species'] ?? ''), color: _pet!['species'] == 'cat' ? MoewColors.secondary : MoewColors.primary, icon: Icons.pets),
                  ])),
                  const SizedBox(height: MoewSpacing.xl),
                  _card([
                    _row('Giống', _pet!['breed'] ?? 'Chưa rõ'),
                    _row('Giới tính', _pet!['gender'] == 'male' ? 'Đực' : (_pet!['gender'] == 'female' ? 'Cái' : _pet!['gender'] ?? 'Chưa rõ')),
                    _row('Màu lông', _pet!['color'] ?? 'Chưa rõ'),
                    if (_pet!['birthDate'] != null) _row('Ngày sinh', _pet!['birthDate'].toString().length >= 10 ? _pet!['birthDate'].toString().substring(0, 10) : _pet!['birthDate'].toString()),
                    if (_pet!['features'] != null) _row('Đặc điểm', _pet!['features'].toString()),
                  ]),
                  const SizedBox(height: MoewSpacing.md),

                  // Weight section
                  Container(
                    padding: const EdgeInsets.all(MoewSpacing.md),
                    decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.card),
                    child: Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: MoewColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(MoewRadius.sm)),
                        child: const Icon(Icons.monitor_weight, size: 22, color: MoewColors.accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Cân nặng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: MoewColors.textMain)),
                        Text(_pet!['weight'] != null ? '${_pet!['weight']} kg' : 'Chưa cập nhật', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _pet!['weight'] != null ? MoewColors.accent : MoewColors.textSub)),
                      ])),
                      ElevatedButton.icon(
                        onPressed: _showAddWeight,
                        icon: const Icon(Icons.add, size: 16, color: Colors.white),
                        label: const Text('Cân mới', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: MoewColors.accent, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      ),
                    ]),
                  ),

                  // Notes
                  if (_pet!['notes'] != null && _pet!['notes'].toString().isNotEmpty) ...[
                    const SizedBox(height: MoewSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(MoewSpacing.md),
                      decoration: BoxDecoration(color: MoewColors.tintYellow, borderRadius: BorderRadius.circular(MoewRadius.lg)),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.note_outlined, size: 20, color: MoewColors.secondary),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('GHI CHÚ', style: MoewTextStyles.label),
                          const SizedBox(height: 4),
                          Text(_pet!['notes'].toString(), style: MoewTextStyles.body),
                        ])),
                      ]),
                    ),
                  ],
                  const SizedBox(height: MoewSpacing.md),
                  // Quick links
                  _actionRow('Theo dõi cân nặng', Icons.monitor_weight_outlined, MoewColors.accent, () => Navigator.pushNamed(context, '/pet-weight', arguments: widget.petId)),
                  _actionRow('Lịch tiêm chủng', Icons.vaccines_outlined, MoewColors.success, () => Navigator.pushNamed(context, '/pet-vaccines', arguments: widget.petId)),
                  _actionRow('Hồ sơ y tế', Icons.medical_services_outlined, MoewColors.primary, () => Navigator.pushNamed(context, '/medical', arguments: widget.petId)),
                  _actionRow('Lịch sử ăn', Icons.restaurant_outlined, MoewColors.secondary, () => Navigator.pushNamed(context, '/food-history', arguments: widget.petId)),
                ]),
    );
  }

  Future<void> _showAddWeight() async {
    final ctrl = TextEditingController();
    bool saving = false;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setBS) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Cân mới', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Cân nặng (kg)', prefixIcon: Icon(Icons.monitor_weight, size: 18), suffixText: 'kg'),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: saving ? null : () async {
              if (ctrl.text.trim().isEmpty) { MoewToast.show(ctx, message: 'Nhập cân nặng', type: ToastType.warning); return; }
              setBS(() => saving = true);
              final weight = double.tryParse(ctrl.text.trim()) ?? 0;
              final res = await PetApi.addWeight(widget.petId, {'weight': weight});
              if (!mounted) return;
              setBS(() => saving = false);
              if (res.success) {
                Navigator.pop(ctx);
                MoewToast.show(context, message: 'Đã ghi nhận!', type: ToastType.success);
                _fetch();
              } else {
                MoewToast.show(ctx, message: res.error ?? 'Lỗi', type: ToastType.error);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: MoewColors.accent, padding: const EdgeInsets.symmetric(vertical: 14)),
            child: saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Lưu', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          )),
        ]),
      )),
    );
  }

  Widget _card(List<Widget> children) => Container(
    padding: const EdgeInsets.all(MoewSpacing.md),
    decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.card),
    child: Column(children: children),
  );

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: MoewTextStyles.caption),
      Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: MoewColors.textMain)),
    ]),
  );

  Widget _actionRow(String label, IconData icon, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: MoewSpacing.sm),
      padding: const EdgeInsets.all(MoewSpacing.md),
      decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.card),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(MoewRadius.sm)), child: Icon(icon, size: 20, color: color)),
        const SizedBox(width: MoewSpacing.md),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: MoewColors.textMain))),
        const Icon(Icons.chevron_right, size: 20, color: MoewColors.textSub),
      ]),
    ),
  );
}
