import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../api/feeding_api.dart';
import '../../widgets/toast.dart';
import '../../widgets/common_widgets.dart';

class FeedingTodayScreen extends StatefulWidget {
  const FeedingTodayScreen({super.key});
  @override
  State<FeedingTodayScreen> createState() => _FeedingTodayScreenState();
}

class _FeedingTodayScreenState extends State<FeedingTodayScreen> {
  Map<String, dynamic>? _data;
  int _streak = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    final res = await FeedingApi.getToday();
    final streakRes = await FeedingApi.getStreak();
    if (!mounted) return;
    setState(() {
      final raw = res.data;
      _data = (raw is Map<String, dynamic>) ? (raw['data'] is Map ? raw['data'] : raw) : null;
      final sr = streakRes.data;
      _streak = (sr is Map ? (sr['data'] is Map ? sr['data']['streak'] : sr['streak']) : 0) ?? 0;
      _loading = false;
    });
  }

  Future<void> _confirmMeal(Map<String, dynamic> meal) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoewRadius.lg)),
        title: Row(children: [
          const Icon(Icons.restaurant, color: MoewColors.success, size: 22),
          const SizedBox(width: 8),
          Expanded(child: Text('Cho ${meal['petName']} ăn ${meal['label']}?', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: MoewColors.surface, borderRadius: BorderRadius.circular(MoewRadius.sm)),
            child: Row(children: [
              const Icon(Icons.scale, size: 16, color: MoewColors.textSub),
              const SizedBox(width: 8),
              Text('${meal['portionGrams']}g ${meal['foodName']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 12),
          TextField(controller: noteCtrl, decoration: const InputDecoration(hintText: 'Ghi chú (tùy chọn)', prefixIcon: Icon(Icons.edit_note, size: 18))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: MoewColors.success),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final res = await FeedingApi.confirmMeal(meal['scheduleId'], note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim());
    if (!mounted) return;
    if (res.success) {
      final d = res.data is Map ? (res.data['data'] is Map ? res.data['data'] : res.data) : res.data;
      MoewToast.show(context, message: res.data?['message'] ?? 'Đã xác nhận!', type: ToastType.success);
      // Show early/late warning if present
      if (d is Map && d['warning'] != null && d['warning'].toString().isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          MoewToast.show(context, message: d['warning'].toString(), type: d['isLate'] == true ? ToastType.error : ToastType.warning);
        });
      }
      _fetch();
    } else {
      MoewToast.show(context, message: res.error ?? 'Lỗi', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: const AppHeader(title: 'Cho ăn hôm nay'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MoewColors.primary))
          : _data == null
              ? const EmptyState(icon: Icons.restaurant, color: MoewColors.primary, message: 'Chưa có lịch cho ăn.\nTạo khẩu phần trước nhé!')
              : ListView(padding: const EdgeInsets.all(MoewSpacing.md), children: [
                  // ── Streak + Summary ──
                  _buildHeader(),
                  const SizedBox(height: MoewSpacing.md),

                  // ── Timeline ──
                  ...(_data!['timeline'] as List? ?? []).map<Widget>((m) => _buildMealCard(m as Map<String, dynamic>)),

                  const SizedBox(height: MoewSpacing.lg),

                  // ── Quick links ──
                  Row(children: [
                    Expanded(child: _linkBtn('Kho thức ăn', Icons.inventory_2, '/food-products')),
                    const SizedBox(width: 10),
                    Expanded(child: _linkBtn('Khẩu phần', Icons.pie_chart, '/feeding-plan')),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _linkBtn('Thống kê', Icons.bar_chart, '/nutrition-dashboard')),
                    const SizedBox(width: 10),
                    Expanded(child: _linkBtn('Chuyển đổi', Icons.swap_horiz, '/food-transition')),
                  ]),
                  const SizedBox(height: MoewSpacing.lg),
                ]),
    );
  }

  Widget _buildHeader() {
    final total = _data!['totalMeals'] ?? 0;
    final fed = _data!['fedCount'] ?? 0;
    final progress = total > 0 ? fed / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(MoewSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [MoewColors.primary.withValues(alpha: 0.08), MoewColors.success.withValues(alpha: 0.08)]),
        borderRadius: BorderRadius.circular(MoewRadius.lg),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          // Streak
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: MoewColors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(MoewRadius.full)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('🔥', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 4),
              Text('$_streak ngày', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: MoewColors.warning)),
            ]),
          ),
          // Progress
          Text('$fed / $total bữa', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: MoewColors.textMain)),
        ]),
        const SizedBox(height: 12),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: MoewColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? MoewColors.success : MoewColors.primary),
          ),
        ),
        if (progress >= 1.0)
          const Padding(padding: EdgeInsets.only(top: 8), child: Text('Tuyệt vời! Đã cho ăn đủ!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MoewColors.success))),
      ]),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal) {
    final isFed = meal['isFed'] == true;
    final time = meal['time']?.toString() ?? '';
    final label = meal['label']?.toString() ?? '';
    final petName = meal['petName']?.toString() ?? '';
    final foodName = meal['foodName']?.toString() ?? '';
    final grams = meal['portionGrams'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: MoewColors.white,
        borderRadius: BorderRadius.circular(MoewRadius.lg),
        boxShadow: MoewShadows.soft,
        border: Border(left: BorderSide(color: isFed ? MoewColors.success : MoewColors.warning, width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          // Time badge
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: (isFed ? MoewColors.success : MoewColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(MoewRadius.md),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(time, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isFed ? MoewColors.success : MoewColors.primary)),
              Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: isFed ? MoewColors.success : MoewColors.textSub)),
            ]),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.pets, size: 14, color: isFed ? MoewColors.success : MoewColors.textMain),
              const SizedBox(width: 4),
              Text(petName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isFed ? MoewColors.success : MoewColors.textMain)),
            ]),
            const SizedBox(height: 2),
            Text('${grams}g $foodName', style: const TextStyle(fontSize: 12, color: MoewColors.textSub)),
            if (isFed && meal['feedingNote'] != null)
              Padding(padding: const EdgeInsets.only(top: 2), child: Text('"${meal['feedingNote']}"', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: MoewColors.textSub))),
          ])),

          // Status / Action
          if (isFed)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: MoewColors.success.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 20, color: MoewColors.success),
            )
          else
            ElevatedButton(
              onPressed: () => _confirmMeal(meal),
              style: ElevatedButton.styleFrom(backgroundColor: MoewColors.primary, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), minimumSize: Size.zero),
              child: const Text('Cho ăn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
        ]),
      ),
    );
  }

  Widget _linkBtn(String label, IconData icon, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.md), boxShadow: MoewShadows.soft),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: MoewColors.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MoewColors.textMain)),
        ]),
      ),
    );
  }
}
