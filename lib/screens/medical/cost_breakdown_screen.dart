import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../api/medical_api.dart';
import '../../utils/parse_utils.dart';
import '../../widgets/toast.dart';
import '../../widgets/common_widgets.dart';

class CostBreakdownScreen extends StatefulWidget {
  final dynamic petId;
  final dynamic recordId;
  final String type;
  const CostBreakdownScreen({super.key, required this.petId, required this.recordId, required this.type});
  @override
  State<CostBreakdownScreen> createState() => _CostBreakdownScreenState();
}

class _CostBreakdownScreenState extends State<CostBreakdownScreen> {
  List<dynamic> _costs = [];
  bool _loading = true;
  double _total = 0;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final res = await CostApi.getAll(widget.type, widget.petId, widget.recordId);
    if (!mounted) return;
    // API might return List directly, or Map with nested data
    final raw = res.data;
    List<dynamic> costs = [];
    if (raw is Map) {
      final d = raw['data'];
      if (d is List) {
        costs = d;
      } else if (d is Map) {
        costs = (d['items'] ?? d['costs'] ?? d['data'] ?? []) as List;
      } else {
        costs = [];
      }
    } else if (raw is List) {
      costs = raw;
    }
    double total = 0;
    for (final c in costs) {
      if (c is Map) total += toDouble(c['amount']);
    }
    setState(() { _costs = costs; _total = total; _loading = false; });
  }

  void _addCost() {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String selectedType = 'other';
    final types = {'consultation': 'Phí khám', 'medication': 'Thuốc', 'lab': 'Xét nghiệm', 'surgery': 'Phẫu thuật', 'vaccine': 'Vaccine', 'additional': 'Phụ thu', 'other': 'Khác'};
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setSheetState) => Padding(
        padding: EdgeInsets.only(left: MoewSpacing.lg, right: MoewSpacing.lg, top: 16, bottom: MediaQuery.of(ctx2).viewInsets.bottom + 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: MoewColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: MoewSpacing.md),
          Text('Thêm chi phí', style: MoewTextStyles.h2),
          const SizedBox(height: MoewSpacing.lg),
          // Type selector
          Wrap(spacing: 8, runSpacing: 8, children: types.entries.map((e) => GestureDetector(
            onTap: () => setSheetState(() => selectedType = e.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selectedType == e.key ? MoewColors.primary : MoewColors.surface,
                borderRadius: BorderRadius.circular(MoewRadius.md),
              ),
              child: Text(e.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selectedType == e.key ? Colors.white : MoewColors.textMain)),
            ),
          )).toList()),
          const SizedBox(height: MoewSpacing.md),
          TextField(controller: descCtrl, decoration: const InputDecoration(hintText: 'Mô tả chi phí', prefixIcon: Icon(Icons.label_outline))),
          const SizedBox(height: MoewSpacing.md),
          TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Số tiền (VNĐ)', prefixIcon: Icon(Icons.attach_money))),
          const SizedBox(height: MoewSpacing.lg),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              if (descCtrl.text.isEmpty || amountCtrl.text.isEmpty) return;
              Navigator.pop(ctx2);
              final res = await CostApi.create(widget.type, widget.petId, widget.recordId, {
                'type': selectedType,
                'description': descCtrl.text.trim(),
                'amount': double.tryParse(amountCtrl.text) ?? 0,
                'isPaid': true,
                'date': DateTime.now().toIso8601String().substring(0, 10),
              });
              if (mounted) {
                if (res.success) { MoewToast.show(context, message: 'Đã thêm!', type: ToastType.success); _fetch(); }
                else { MoewToast.show(context, message: res.error ?? 'Lỗi', type: ToastType.error); }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: MoewColors.secondary),
            child: Text('Thêm', style: MoewTextStyles.button),
          )),
        ]),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: const AppHeader(title: 'Chi phí'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MoewColors.primary))
          : Column(children: [
              // Total header
              Container(
                margin: const EdgeInsets.all(MoewSpacing.lg),
                padding: const EdgeInsets.all(MoewSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [MoewColors.secondary, Color(0xFFE67E22)]),
                  borderRadius: BorderRadius.circular(MoewRadius.xl),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('TỔNG CHI PHÍ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70, letterSpacing: 1)),
                    SizedBox(height: 4),
                  ]),
                  Text(formatVND(_total), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                ]),
              ),
              Expanded(
                child: _costs.isEmpty
                    ? const EmptyState(icon: Icons.attach_money, color: MoewColors.secondary, message: 'Chưa có chi phí nào')
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: MoewSpacing.lg),
                        itemCount: _costs.length,
                        itemBuilder: (ctx, i) {
                          final c = _costs[i] as Map<String, dynamic>;
                          return Container(
                            margin: const EdgeInsets.only(bottom: MoewSpacing.sm),
                            padding: const EdgeInsets.all(MoewSpacing.md),
                            decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.card),
                            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Expanded(child: Row(children: [
                                Container(width: 40, height: 40, decoration: BoxDecoration(color: MoewColors.tintAmber, borderRadius: BorderRadius.circular(MoewRadius.sm)), child: const Icon(Icons.receipt_outlined, size: 20, color: MoewColors.secondary)),
                                const SizedBox(width: 12),
                                Expanded(child: Text((c['description'] ?? c['name'] ?? '').toString(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: MoewColors.textMain), overflow: TextOverflow.ellipsis)),
                              ])),
                              Text(formatVND(c['amount']), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MoewColors.secondary)),
                            ]),
                          );
                        },
                      ),
              ),
            ]),
      floatingActionButton: FloatingActionButton(onPressed: _addCost, backgroundColor: MoewColors.secondary, child: const Icon(Icons.add, color: Colors.white)),
    );
  }
}
