import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../api/feeding_api.dart';
import '../../widgets/toast.dart';
import '../../widgets/common_widgets.dart';

class FoodProductsScreen extends StatefulWidget {
  const FoodProductsScreen({super.key});
  @override
  State<FoodProductsScreen> createState() => _FoodProductsScreenState();
}

class _FoodProductsScreenState extends State<FoodProductsScreen> {
  List<dynamic> _products = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    final res = await FeedingApi.getProducts();
    if (!mounted) return;
    final raw = res.data;
    setState(() {
      final data = (raw is Map) ? raw['data'] : raw;
      _products = data is List ? data : [];
      _loading = false;
    });
  }

  Future<void> _showAddProduct() async {
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    String? imageB64;
    bool adding = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setBS) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Thêm sản phẩm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: MoewColors.textMain)),
            SizedBox(height: 4),
            Text('AI sẽ tự phân tích dinh dưỡng', style: TextStyle(fontSize: 12, color: MoewColors.textSub)),
            SizedBox(height: 16),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên sản phẩm *', prefixIcon: Icon(Icons.fastfood, size: 18))),
            SizedBox(height: 10),
            TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Thương hiệu', prefixIcon: Icon(Icons.business, size: 18))),
            SizedBox(height: 10),
            TextField(controller: weightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Trọng lượng (gram) *', prefixIcon: Icon(Icons.scale, size: 18))),
            SizedBox(height: 12),
            // Camera button
            GestureDetector(
              onTap: () async {
                final picker = ImagePicker();
                final img = await picker.pickImage(source: ImageSource.camera, maxWidth: 1024, imageQuality: 80);
                if (img == null) return;
                final bytes = await File(img.path).readAsBytes();
                setBS(() => imageB64 = 'data:image/jpeg;base64,${base64Encode(bytes)}');
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: MoewColors.surface, borderRadius: BorderRadius.circular(MoewRadius.sm), border: Border.all(color: MoewColors.border)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(imageB64 != null ? Icons.check_circle : Icons.camera_alt, size: 18, color: imageB64 != null ? MoewColors.success : MoewColors.primary),
                  SizedBox(width: 8),
                  Text(imageB64 != null ? 'Đã chụp ảnh bao bì' : 'Chụp ảnh bao bì (tùy chọn)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: imageB64 != null ? MoewColors.success : MoewColors.primary)),
                ]),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: adding ? null : () async {
                  if (nameCtrl.text.trim().isEmpty || weightCtrl.text.trim().isEmpty) {
                    MoewToast.show(ctx, message: 'Nhập tên và trọng lượng', type: ToastType.warning);
                    return;
                  }
                  setBS(() => adding = true);
                  final body = <String, dynamic>{
                    'name': nameCtrl.text.trim(),
                    'weightGrams': int.tryParse(weightCtrl.text.trim()) ?? 0,
                    if (brandCtrl.text.trim().isNotEmpty) 'brand': brandCtrl.text.trim(),
                    'image': ?imageB64,
                  };
                  final res = await FeedingApi.addProduct(body);
                  if (!mounted || !ctx.mounted) return;
                  setBS(() => adding = false);
                  if (res.success) {
                    Navigator.pop(ctx);
                    MoewToast.show(context, message: 'Đã thêm sản phẩm!', type: ToastType.success);
                    _fetch();
                  } else {
                    MoewToast.show(ctx, message: res.error ?? 'Lỗi', type: ToastType.error);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: MoewColors.success, padding: EdgeInsets.symmetric(vertical: 14)),
                child: adding
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Thêm & AI phân tích', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ]),
        );
      }),
    );
  }

  Future<void> _restock(Map<String, dynamic> p) async {
    final ctrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Thêm ${p['name']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Còn ${p['remainingGrams'] ?? 0}g / ${p['weightGrams'] ?? 0}g', style: TextStyle(fontSize: 12, color: MoewColors.textSub)),
          SizedBox(height: 10),
          TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số gram thêm', suffixText: 'g')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: MoewColors.primary), child: Text('Thêm', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirmed != true || ctrl.text.trim().isEmpty) return;

    final grams = int.tryParse(ctrl.text.trim()) ?? 0;
    final res = await FeedingApi.restockProduct(p['id'], grams);
    if (!mounted) return;

    if (res.success) {
      MoewToast.show(context, message: res.data?['message'] ?? 'Đã thêm!', type: ToastType.success);
      // Show warning if present (force-added)
      if (res.data?['warning'] != null) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          MoewToast.show(context, message: res.data['warning'].toString(), type: ToastType.warning);
        });
      }
      _fetch();
    } else if (res.data?['code'] == 'EXCEEDS_BAG_WEIGHT') {
      // Exceeds bag — show confirm dialog with info
      final d = res.data['data'] as Map<String, dynamic>? ?? {};
      final forceOk = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoewRadius.lg)),
          title: Row(children: [
            Icon(Icons.warning_amber, color: MoewColors.warning, size: 22),
            SizedBox(width: 8),
            Text('Vượt bao!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(res.data?['message'] ?? '', style: TextStyle(fontSize: 13)),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(color: MoewColors.surface, borderRadius: BorderRadius.circular(MoewRadius.sm)),
              child: Column(children: [
                _infoRow('Bao gốc', '${d['bagWeight'] ?? 0}g'),
                _infoRow('Đang có', '${d['currentGrams'] ?? 0}g'),
                _infoRow('Tối đa thêm', '${d['maxCanAdd'] ?? 0}g'),
              ]),
            ),
            SizedBox(height: 8),
            Text('Bấm "Thêm vượt bao" nếu bạn mua bao mới.', style: TextStyle(fontSize: 11, color: MoewColors.textSub)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Hủy')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: MoewColors.warning),
              child: Text('Thêm vượt bao', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      if (forceOk != true || !mounted) return;
      // Force restock
      final forceRes = await FeedingApi.restockProduct(p['id'], grams, force: true);
      if (!mounted) return;
      if (forceRes.success) {
        MoewToast.show(context, message: forceRes.data?['message'] ?? 'Đã thêm!', type: ToastType.success);
        if (forceRes.data?['warning'] != null) {
          Future.delayed(const Duration(milliseconds: 600), () {
            if (!mounted) return;
            MoewToast.show(context, message: forceRes.data['warning'].toString(), type: ToastType.warning);
          });
        }
        _fetch();
      } else {
        MoewToast.show(context, message: forceRes.error ?? 'Lỗi', type: ToastType.error);
      }
    } else {
      MoewToast.show(context, message: res.error ?? 'Lỗi', type: ToastType.error);
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: 12, color: MoewColors.textSub)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Future<void> _delete(Map<String, dynamic> p) async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text('Xóa sản phẩm?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      content: Text('Xóa "${p['name']}" khỏi kho?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Hủy')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Xóa', style: TextStyle(color: MoewColors.danger))),
      ],
    ));
    if (confirmed != true) return;
    final res = await FeedingApi.deleteProduct(p['id']);
    if (!mounted) return;
    if (res.success) { MoewToast.show(context, message: 'Đã xóa', type: ToastType.success); _fetch(); }
    else { MoewToast.show(context, message: res.error ?? 'Lỗi', type: ToastType.error); }
  }

  Future<void> _editProduct(Map<String, dynamic> p) async {
    final nameCtrl = TextEditingController(text: p['name']?.toString() ?? '');
    final brandCtrl = TextEditingController(text: p['brand']?.toString() ?? '');
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setBS) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Chỉnh sửa sản phẩm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          SizedBox(height: 14),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên sản phẩm', prefixIcon: Icon(Icons.fastfood, size: 18))),
          SizedBox(height: 10),
          TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Thương hiệu', prefixIcon: Icon(Icons.business, size: 18))),
          SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: saving ? null : () async {
              setBS(() => saving = true);
              final body = <String, dynamic>{};
              if (nameCtrl.text.trim().isNotEmpty) body['name'] = nameCtrl.text.trim();
              if (brandCtrl.text.trim().isNotEmpty) body['brand'] = brandCtrl.text.trim();
              final res = await FeedingApi.updateProduct(p['id'], body);
              if (!mounted || !ctx.mounted) return;
              setBS(() => saving = false);
              if (res.success) { Navigator.pop(ctx); MoewToast.show(context, message: 'Đã cập nhật!', type: ToastType.success); _fetch(); }
              else { MoewToast.show(ctx, message: res.error ?? 'Lỗi', type: ToastType.error); }
            },
            style: ElevatedButton.styleFrom(backgroundColor: MoewColors.primary, padding: EdgeInsets.symmetric(vertical: 14)),
            child: saving ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Lưu', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          )),
        ]),
      )),
    );
  }

  Future<void> _disposeProduct(Map<String, dynamic> p) async {
    final gramsCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setBS) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Hủy / giảm gram', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: MoewColors.danger)),
          SizedBox(height: 4),
          Text('${p['name']} — Còn ${p['remainingGrams'] ?? 0}g', style: TextStyle(fontSize: 12, color: MoewColors.textSub)),
          SizedBox(height: 14),
          TextField(controller: gramsCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Số gram còn lại *', suffixText: 'g', prefixIcon: Icon(Icons.scale, size: 18))),
          SizedBox(height: 10),
          TextField(controller: reasonCtrl, decoration: InputDecoration(labelText: 'Lý do (ẩm mốc, hết hạn...)', prefixIcon: Icon(Icons.edit_note, size: 18))),
          SizedBox(height: 4),
          Text('Đặt 0g để hủy toàn bộ', style: TextStyle(fontSize: 11, color: MoewColors.textSub)),
          SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: saving ? null : () async {
              if (gramsCtrl.text.trim().isEmpty) { MoewToast.show(ctx, message: 'Nhập số gram', type: ToastType.warning); return; }
              setBS(() => saving = true);
              final body = <String, dynamic>{ 'remainingGrams': int.tryParse(gramsCtrl.text.trim()) ?? 0 };
              if (reasonCtrl.text.trim().isNotEmpty) body['reason'] = reasonCtrl.text.trim();
              final res = await FeedingApi.updateProduct(p['id'], body);
              if (!mounted || !ctx.mounted) return;
              setBS(() => saving = false);
              if (res.success) {
                Navigator.pop(ctx);
                // Parse — check both levels for funMessage/adjustNote
                final raw = res.data;
                final inner = (raw is Map && raw['data'] is Map) ? raw['data'] : null;
                final funMsg = inner?['funMessage'] ?? (raw is Map ? raw['funMessage'] : null);
                final adjNote = inner?['adjustNote'] ?? (raw is Map ? raw['adjustNote'] : null);
                debugPrint('🐱 Dispose response: funMessage=$funMsg, adjustNote=$adjNote');

                MoewToast.show(context, message: raw?['message'] ?? 'Đã cập nhật!', type: ToastType.success);
                // Fun message toast (vui vui)
                if (funMsg != null && funMsg.toString().isNotEmpty) {
                  Future.delayed(const Duration(milliseconds: 800), () {
                    if (!mounted) return;
                    MoewToast.show(context, message: funMsg.toString(), type: ToastType.info);
                  });
                }
                // Adjust note toast (nghiêm túc)
                if (adjNote != null && adjNote.toString().isNotEmpty) {
                  Future.delayed(Duration(milliseconds: funMsg != null ? 2500 : 800), () {
                    if (!mounted) return;
                    MoewToast.show(context, message: adjNote.toString(), type: ToastType.warning);
                  });
                }
                _fetch();
              }
              else { MoewToast.show(ctx, message: res.error ?? 'Lỗi', type: ToastType.error); }
            },
            style: ElevatedButton.styleFrom(backgroundColor: MoewColors.danger, padding: EdgeInsets.symmetric(vertical: 14)),
            child: saving ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Xác nhận', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          )),
        ]),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: AppHeader(title: 'Kho thức ăn'),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProduct,
        backgroundColor: MoewColors.success,
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: MoewColors.primary))
          : _products.isEmpty
              ? EmptyState(icon: Icons.inventory_2, color: MoewColors.primary, message: 'Chưa có sản phẩm nào\nBấm + để thêm')
              : ListView.builder(
                  padding: EdgeInsets.all(MoewSpacing.md),
                  itemCount: _products.length,
                  itemBuilder: (_, i) => _buildProductCard(_products[i] as Map<String, dynamic>),
                ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> p) {
    final remaining = (p['remainingGrams'] ?? 0) as num;
    final total = (p['weightGrams'] ?? 1) as num;
    final progress = total > 0 ? (remaining / total).clamp(0.0, 1.0) : 0.0;
    final isLow = remaining < total * 0.2;
    final plans = p['feedingPlans'] as List? ?? [];

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.soft),
      child: Padding(
        padding: EdgeInsets.all(MoewSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: MoewColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(MoewRadius.md)),
              child: Icon(Icons.fastfood, color: MoewColors.primary, size: 22),
            ),
            SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['name']?.toString() ?? '', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: MoewColors.textMain)),
              if (p['brand'] != null) Text(p['brand'].toString(), style: TextStyle(fontSize: 12, color: MoewColors.textSub)),
            ])),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'restock') {
                  _restock(p);
                } else if (v == 'edit') {
                  _editProduct(p);
                } else if (v == 'dispose') {
                  _disposeProduct(p);
                } else if (v == 'delete') {
                  _delete(p);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18, color: MoewColors.primary), SizedBox(width: 8), Text('Chỉnh sửa')])),
                PopupMenuItem(value: 'restock', child: Row(children: [Icon(Icons.add_circle, size: 18, color: MoewColors.success), SizedBox(width: 8), Text('Thêm gram')])),
                PopupMenuItem(value: 'dispose', child: Row(children: [Icon(Icons.remove_circle, size: 18, color: MoewColors.warning), SizedBox(width: 8), Text('Hủy / giảm gram')])),
                PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: MoewColors.danger), SizedBox(width: 8), Text('Xóa')])),
              ],
            ),
          ]),
          SizedBox(height: 12),

          // Remaining gauge
          Row(children: [
            Text('Còn lại: ${remaining.toInt()}g / ${total.toInt()}g', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isLow ? MoewColors.danger : MoewColors.textSub)),
            if (isLow) ...[SizedBox(width: 6), Icon(Icons.warning_amber, size: 14, color: MoewColors.danger)],
          ]),
          SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: progress.toDouble(), minHeight: 6, backgroundColor: MoewColors.border, valueColor: AlwaysStoppedAnimation(isLow ? MoewColors.danger : MoewColors.success)),
          ),
          SizedBox(height: 10),

          // Nutrition info
          Wrap(spacing: 8, runSpacing: 4, children: [
            if (p['caloriesPer100g'] != null) _chip('${p['caloriesPer100g']} kcal/100g', Icons.local_fire_department),
            if (p['proteinPercent'] != null) _chip('${p['proteinPercent']}% protein', Icons.fitness_center),
            if (p['fatPercent'] != null) _chip('${p['fatPercent']}% fat', Icons.opacity),
          ]),

          // Plans using this product
          if (plans.isNotEmpty) ...[
            SizedBox(height: 8),
            Text('Đang dùng cho ${plans.length} bé', style: TextStyle(fontSize: 11, color: MoewColors.textSub)),
          ],

          // AI analysis
          if (p['aiAnalysis'] != null && p['aiAnalysis'].toString().isNotEmpty) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(color: MoewColors.surface, borderRadius: BorderRadius.circular(MoewRadius.sm)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.auto_awesome, size: 14, color: MoewColors.accent),
                SizedBox(width: 6),
                Expanded(child: Text(p['aiAnalysis'].toString(), style: TextStyle(fontSize: 11, color: MoewColors.textSub), maxLines: 3, overflow: TextOverflow.ellipsis)),
              ]),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _chip(String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: MoewColors.surface, borderRadius: BorderRadius.circular(MoewRadius.full)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: MoewColors.primary),
        SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: MoewColors.textMain)),
      ]),
    );
  }
}
