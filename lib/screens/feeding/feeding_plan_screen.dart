import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../api/feeding_api.dart';
import '../../api/pet_api.dart';
import '../../widgets/toast.dart';
import '../../widgets/common_widgets.dart';

class FeedingPlanScreen extends StatefulWidget {
  const FeedingPlanScreen({super.key});
  @override
  State<FeedingPlanScreen> createState() => _FeedingPlanScreenState();
}

class _FeedingPlanScreenState extends State<FeedingPlanScreen> {
  List<dynamic> _plans = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    final res = await FeedingApi.getPlans();
    if (!mounted) return;
    final raw = res.data;
    setState(() {
      final data = (raw is Map) ? raw['data'] : raw;
      _plans = data is List ? data : [];
      _loading = false;
    });
  }

  Future<void> _showGenerate() async {
    // Fetch products and pets
    final prodRes = await FeedingApi.getProducts();
    final petRes = await PetApi.getAll();
    if (!mounted) return;

    final products = ((prodRes.data is Map ? prodRes.data['data'] : prodRes.data) as List?) ?? [];
    final pets = ((petRes.data is Map ? petRes.data['data'] : petRes.data) as List?) ?? [];

    if (products.isEmpty) {
      MoewToast.show(context, message: 'Thêm sản phẩm vào kho trước', type: ToastType.warning);
      return;
    }
    if (pets.isEmpty) {
      MoewToast.show(context, message: 'Thêm thú cưng trước', type: ToastType.warning);
      return;
    }

    dynamic selectedProduct = products.first['id'];
    Set<dynamic> selectedPets = {pets.first['id']};
    int mealsPerDay = 3;
    String activityLevel = 'normal';
    bool generating = false;

    const activityOptions = [
      {'value': 'active', 'label': 'Vận động nhiều', 'desc': 'Chưa triệt sản (×1.4)'},
      {'value': 'normal', 'label': 'Bình thường', 'desc': 'Trưởng thành (×1.2)'},
      {'value': 'neutered', 'label': 'Đã triệt sản', 'desc': 'Ít vận động (×1.0)'},
      {'value': 'weight_loss', 'label': 'Giảm cân', 'desc': 'Đang giảm cân (×0.8)'},
      {'value': 'senior', 'label': 'Mèo già', 'desc': '> 7 tuổi (×0.9)'},
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setBS) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('AI tạo khẩu phần', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Chọn thức ăn và thú cưng', style: TextStyle(fontSize: 12, color: MoewColors.textSub)),
            const SizedBox(height: 16),

            // Product selector
            const Text('Sản phẩm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MoewColors.textSub)),
            const SizedBox(height: 6),
            SizedBox(
              height: 60,
              child: ListView(scrollDirection: Axis.horizontal, children: products.map<Widget>((p) {
                final active = selectedProduct == p['id'];
                return GestureDetector(
                  onTap: () => setBS(() => selectedProduct = p['id']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: active ? MoewColors.primary.withValues(alpha: 0.1) : MoewColors.white,
                      borderRadius: BorderRadius.circular(MoewRadius.md),
                      border: Border.all(color: active ? MoewColors.primary : MoewColors.border, width: active ? 2 : 1),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(p['name'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? MoewColors.primary : MoewColors.textMain)),
                      Text('${p['remainingGrams'] ?? 0}g', style: TextStyle(fontSize: 10, color: active ? MoewColors.primary : MoewColors.textSub)),
                    ]),
                  ),
                );
              }).toList()),
            ),
            const SizedBox(height: 14),

            // Pet multi-select
            const Text('Chọn bé (nhiều bé)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MoewColors.textSub)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: pets.map<Widget>((p) {
              final active = selectedPets.contains(p['id']);
              return GestureDetector(
                onTap: () => setBS(() { if (active) selectedPets.remove(p['id']); else selectedPets.add(p['id']); }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? MoewColors.success.withValues(alpha: 0.1) : MoewColors.white,
                    borderRadius: BorderRadius.circular(MoewRadius.full),
                    border: Border.all(color: active ? MoewColors.success : MoewColors.border, width: active ? 2 : 1),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(active ? Icons.check_circle : Icons.pets, size: 14, color: active ? MoewColors.success : MoewColors.textSub),
                    const SizedBox(width: 4),
                    Text(p['name'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? MoewColors.success : MoewColors.textSub)),
                  ]),
                ),
              );
            }).toList()),
            const SizedBox(height: 14),

            // Meals per day
            Row(children: [
              const Text('Số bữa/ngày: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ...List.generate(4, (i) {
                final n = i + 1;
                return GestureDetector(
                  onTap: () => setBS(() => mealsPerDay = n),
                  child: Container(
                    width: 36, height: 36,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: mealsPerDay == n ? MoewColors.primary : MoewColors.surface,
                      borderRadius: BorderRadius.circular(MoewRadius.sm),
                    ),
                    child: Center(child: Text('$n', style: TextStyle(fontWeight: FontWeight.w700, color: mealsPerDay == n ? Colors.white : MoewColors.textSub))),
                  ),
                );
              }),
            ]),
            const SizedBox(height: 14),

            // Activity level
            const Text('Mức hoạt động', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MoewColors.textSub)),
            const SizedBox(height: 6),
            SizedBox(
              height: 56,
              child: ListView(scrollDirection: Axis.horizontal, children: activityOptions.map<Widget>((opt) {
                final active = activityLevel == opt['value'];
                return GestureDetector(
                  onTap: () => setBS(() => activityLevel = opt['value']!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: active ? MoewColors.accent.withValues(alpha: 0.1) : MoewColors.white,
                      borderRadius: BorderRadius.circular(MoewRadius.md),
                      border: Border.all(color: active ? MoewColors.accent : MoewColors.border, width: active ? 2 : 1),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(opt['label']!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? MoewColors.accent : MoewColors.textMain)),
                      Text(opt['desc']!, style: TextStyle(fontSize: 9, color: active ? MoewColors.accent : MoewColors.textSub)),
                    ]),
                  ),
                );
              }).toList()),
            ),
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: generating ? null : () async {
                  if (selectedPets.isEmpty) { MoewToast.show(ctx, message: 'Chọn thú cưng', type: ToastType.warning); return; }
                  setBS(() => generating = true);
                  final res = await FeedingApi.generatePlans({
                    'productId': selectedProduct,
                    'petIds': selectedPets.toList(),
                    'mealsPerDay': mealsPerDay,
                    'activityLevel': activityLevel,
                  });
                  if (!mounted) return;
                  setBS(() => generating = false);
                  if (res.success) {
                    Navigator.pop(ctx);
                    MoewToast.show(context, message: 'Đã tạo khẩu phần!', type: ToastType.success);
                    _fetch();
                  } else {
                    MoewToast.show(ctx, message: res.error ?? 'Lỗi', type: ToastType.error);
                  }
                },
                icon: generating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
                label: Text(generating ? 'AI đang tính...' : 'Tạo khẩu phần', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: MoewColors.success, padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ]),
        );
      }),
    );
  }

  static const _activityOptions = [
    {'value': 'active', 'label': 'Vận động nhiều', 'desc': '×1.4'},
    {'value': 'normal', 'label': 'Bình thường', 'desc': '×1.2'},
    {'value': 'neutered', 'label': 'Đã triệt sản', 'desc': '×1.0'},
    {'value': 'weight_loss', 'label': 'Giảm cân', 'desc': '×0.8'},
    {'value': 'senior', 'label': 'Mèo già', 'desc': '×0.9'},
  ];

  Future<void> _showEditPlan(Map<String, dynamic> plan) async {
    final petName = plan['pet']?['name'] ?? 'Pet';
    String activityLevel = plan['activityLevel']?.toString() ?? 'normal';
    int mealsPerDay = plan['mealsPerDay'] ?? 3;
    bool isActive = plan['isActive'] != false;
    final gramsCtrl = TextEditingController(text: '${plan['dailyGrams'] ?? ''}');
    final noteCtrl = TextEditingController(text: plan['healthNote']?.toString() ?? '');
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setBS) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.pets, size: 18, color: MoewColors.primary),
            const SizedBox(width: 6),
            Text('Chỉnh khẩu phần $petName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const Spacer(),
            // Active toggle
            Row(children: [
              Text(isActive ? 'Đang bật' : 'Tạm dừng', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isActive ? MoewColors.success : MoewColors.textSub)),
              const SizedBox(width: 4),
              Switch(
                value: isActive,
                onChanged: (v) => setBS(() => isActive = v),
                activeColor: MoewColors.success,
              ),
            ]),
          ]),
          const SizedBox(height: 14),

          // Activity level
          const Text('MỨC HOẠT ĐỘNG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: MoewColors.textSub, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          SizedBox(
            height: 48,
            child: ListView(scrollDirection: Axis.horizontal, children: _activityOptions.map<Widget>((opt) {
              final active = activityLevel == opt['value'];
              return GestureDetector(
                onTap: () => setBS(() => activityLevel = opt['value']!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: active ? MoewColors.accent.withValues(alpha: 0.1) : MoewColors.surface,
                    borderRadius: BorderRadius.circular(MoewRadius.md),
                    border: Border.all(color: active ? MoewColors.accent : MoewColors.border, width: active ? 2 : 1),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(opt['label']!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: active ? MoewColors.accent : MoewColors.textMain)),
                    Text(opt['desc']!, style: TextStyle(fontSize: 9, color: active ? MoewColors.accent : MoewColors.textSub)),
                  ]),
                ),
              );
            }).toList()),
          ),
          const SizedBox(height: 14),

          // Meals per day
          Row(children: [
            const Text('SỐ BỮA/NGÀY: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: MoewColors.textSub)),
            ...List.generate(4, (i) {
              final n = i + 1;
              return GestureDetector(
                onTap: () => setBS(() => mealsPerDay = n),
                child: Container(
                  width: 34, height: 34,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(
                    color: mealsPerDay == n ? MoewColors.primary : MoewColors.surface,
                    borderRadius: BorderRadius.circular(MoewRadius.sm),
                  ),
                  child: Center(child: Text('$n', style: TextStyle(fontWeight: FontWeight.w700, color: mealsPerDay == n ? Colors.white : MoewColors.textSub))),
                ),
              );
            }),
          ]),
          const SizedBox(height: 14),

          // Daily grams override
          TextField(
            controller: gramsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Gram/ngày (để trống = auto)', suffixText: 'g', prefixIcon: Icon(Icons.scale, size: 18)),
          ),
          const SizedBox(height: 10),

          // Health note
          TextField(
            controller: noteCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Ghi chú sức khỏe (bệnh, dị ứng...)', prefixIcon: Icon(Icons.medical_services, size: 18)),
          ),
          const SizedBox(height: 16),

          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: saving ? null : () async {
              setBS(() => saving = true);
              final body = <String, dynamic>{
                'activityLevel': activityLevel,
                'mealsPerDay': mealsPerDay,
                'isActive': isActive,
              };
              if (gramsCtrl.text.trim().isNotEmpty) body['dailyGrams'] = int.tryParse(gramsCtrl.text.trim());
              if (noteCtrl.text.trim().isNotEmpty) body['healthNote'] = noteCtrl.text.trim();

              final res = await FeedingApi.updatePlan(plan['id'], body);
              if (!mounted) return;
              setBS(() => saving = false);
              if (res.success) {
                Navigator.pop(ctx);
                MoewToast.show(context, message: res.data?['message'] ?? 'Đã cập nhật!', type: ToastType.success);
                // Show changes summary
                final changes = res.data?['changes'] as List?;
                if (changes != null && changes.isNotEmpty) {
                  Future.delayed(const Duration(milliseconds: 800), () {
                    if (!mounted) return;
                    MoewToast.show(context, message: changes.join('\n'), type: ToastType.info);
                  });
                }
                _fetch();
              } else {
                MoewToast.show(ctx, message: res.error ?? 'Lỗi', type: ToastType.error);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: MoewColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
            child: saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          )),
        ]),
      ))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: const AppHeader(title: 'Khẩu phần ăn'),
      floatingActionButton: FloatingActionButton(
        onPressed: _showGenerate,
        backgroundColor: MoewColors.success,
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MoewColors.primary))
          : _plans.isEmpty
              ? const EmptyState(icon: Icons.pie_chart, color: MoewColors.primary, message: 'Chưa có khẩu phần\nBấm ✨ để AI tạo')
              : ListView.builder(
                  padding: const EdgeInsets.all(MoewSpacing.md),
                  itemCount: _plans.length,
                  itemBuilder: (_, i) => _buildPlanCard(_plans[i] as Map<String, dynamic>),
                ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final pet = plan['pet'] as Map<String, dynamic>? ?? {};
    final food = plan['foodProduct'] as Map<String, dynamic>? ?? {};
    final schedules = plan['schedules'] as List? ?? [];
    final isActive = plan['isActive'] != false;

    return GestureDetector(
      onTap: () => _showEditPlan(plan),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: MoewColors.white,
        borderRadius: BorderRadius.circular(MoewRadius.lg),
        boxShadow: MoewShadows.soft,
        border: Border(left: BorderSide(color: isActive ? MoewColors.success : MoewColors.textSub, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MoewSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Icon(Icons.pets, size: 18, color: isActive ? MoewColors.primary : MoewColors.textSub),
            const SizedBox(width: 6),
            Expanded(child: Text(pet['name']?.toString() ?? 'Pet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isActive ? MoewColors.textMain : MoewColors.textSub))),
            if (!isActive) Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: MoewColors.textSub.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(MoewRadius.full)),
              child: const Text('Tạm dừng', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: MoewColors.textSub)),
            ),
          ]),
          const SizedBox(height: 8),

          // Stats
          Row(children: [
            _statChip('${plan['dailyGrams'] ?? 0}g/ngày', Icons.scale),
            const SizedBox(width: 8),
            _statChip('${plan['dailyCalories'] ?? 0} kcal', Icons.local_fire_department),
            const SizedBox(width: 8),
            _statChip('${plan['mealsPerDay'] ?? 0} bữa', Icons.restaurant),
          ]),
          const SizedBox(height: 8),

          // Food product
          Text('${food['name'] ?? ''} (${food['remainingGrams'] ?? 0}g còn)', style: const TextStyle(fontSize: 12, color: MoewColors.textSub)),

          // Schedules
          if (schedules.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: schedules.map<Widget>((s) {
              final hasFed = (s['feedingLogs'] as List?)?.isNotEmpty ?? false;
              return Expanded(child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: hasFed ? MoewColors.success.withValues(alpha: 0.1) : MoewColors.surface,
                  borderRadius: BorderRadius.circular(MoewRadius.sm),
                  border: Border.all(color: hasFed ? MoewColors.success : MoewColors.border),
                ),
                child: Column(children: [
                  Text(s['label'] ?? '', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hasFed ? MoewColors.success : MoewColors.textSub)),
                  Text(s['time'] ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: hasFed ? MoewColors.success : MoewColors.textMain)),
                  Text('${s['portionGrams'] ?? 0}g', style: TextStyle(fontSize: 10, color: hasFed ? MoewColors.success : MoewColors.textSub)),
                ]),
              ));
            }).toList()),
          ],

          // AI recommendation
          if (plan['aiRecommendation'] != null) ...[
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.auto_awesome, size: 12, color: MoewColors.accent),
              const SizedBox(width: 4),
              Expanded(child: Text(plan['aiRecommendation'].toString(), style: const TextStyle(fontSize: 11, color: MoewColors.textSub, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis)),
            ]),
          ],
        ]),
      ),
    ));
  }

  Widget _statChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: MoewColors.surface, borderRadius: BorderRadius.circular(MoewRadius.full)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: MoewColors.primary),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
