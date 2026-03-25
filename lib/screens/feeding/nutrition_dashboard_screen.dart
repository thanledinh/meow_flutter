import 'package:flutter/material.dart';
import 'dart:math';
import '../../config/theme.dart';
import '../../api/feeding_api.dart';
import '../../api/pet_api.dart';
import '../../widgets/common_widgets.dart';

class NutritionDashboardScreen extends StatefulWidget {
  const NutritionDashboardScreen({super.key});
  @override
  State<NutritionDashboardScreen> createState() => _NutritionDashboardScreenState();
}

class _NutritionDashboardScreenState extends State<NutritionDashboardScreen> {
  List<dynamic> _pets = [];
  dynamic _selectedPetId;
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    final petRes = await PetApi.getAll();
    if (!mounted) return;
    final pets = ((petRes.data is Map ? petRes.data['data'] : petRes.data) as List?) ?? [];
    setState(() {
      _pets = pets;
      if (pets.isNotEmpty) _selectedPetId = pets.first['id'];
    });
    if (_selectedPetId != null) _fetchStats();
    else setState(() => _loading = false);
  }

  Future<void> _fetchStats({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    final res = await FeedingApi.getNutritionStats(_selectedPetId);
    if (!mounted) return;
    setState(() {
      final raw = res.data;
      _stats = (raw is Map<String, dynamic>) ? (raw['data'] is Map ? raw['data'] : raw) : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: const AppHeader(title: 'Thống kê dinh dưỡng'),
      body: _pets.isEmpty && !_loading
          ? const EmptyState(icon: Icons.bar_chart, color: MoewColors.primary, message: 'Chưa có thú cưng')
          : ListView(padding: const EdgeInsets.all(MoewSpacing.md), children: [
              // Pet selector
              SizedBox(
                height: 50,
                child: ListView(scrollDirection: Axis.horizontal, children: _pets.map<Widget>((p) {
                  final active = _selectedPetId == p['id'];
                  return GestureDetector(
                    onTap: () { setState(() => _selectedPetId = p['id']); _fetchStats(); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: active ? MoewColors.primary : MoewColors.white,
                        borderRadius: BorderRadius.circular(MoewRadius.full),
                        border: Border.all(color: active ? MoewColors.primary : MoewColors.border),
                      ),
                      child: Center(child: Text(p['name'] ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: active ? Colors.white : MoewColors.textSub))),
                    ),
                  );
                }).toList()),
              ),
              const SizedBox(height: MoewSpacing.md),

              if (_loading) const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: MoewColors.primary)))
              else if (_stats == null) const EmptyState(icon: Icons.bar_chart, color: MoewColors.primary, message: 'Chưa có dữ liệu')
              else ...[
                // Calorie ring + today stats
                _buildCalorieRing(),
                const SizedBox(height: MoewSpacing.md),

                // Today stats cards
                _buildTodayStats(),
                const SizedBox(height: MoewSpacing.md),

                // Week chart
                _buildWeekChart(),
              ],
            ]),
    );
  }

  // Tolerance-based calorie status
  // ≤100% = green (on track), 100-110% = green (perfect!), 110-120% = yellow (hơi vượt), >120% = red (vượt nhiều)
  ({Color color, String label}) _calorieStatus(num cals, num target) {
    if (target <= 0) return (color: MoewColors.textSub, label: 'Chưa có mục tiêu');
    final ratio = cals / target;
    if (ratio < 0.5) return (color: MoewColors.primary, label: 'Tiếp tục cho ăn');
    if (ratio < 0.8) return (color: MoewColors.primary, label: 'Gần đạt!');
    if (ratio <= 1.10) return (color: MoewColors.success, label: 'Đạt mục tiêu!');
    if (ratio <= 1.20) return (color: MoewColors.warning, label: 'Hơi vượt một chút');
    return (color: MoewColors.danger, label: 'Vượt nhiều!');
  }

  Widget _buildCalorieRing() {
    final today = _stats!['today'] as Map<String, dynamic>? ?? {};
    final target = _stats!['target'] as Map<String, dynamic>? ?? {};
    final cals = (today['calories'] ?? 0) as num;
    final targetCals = (target['dailyCalories'] ?? 1) as num;
    final progress = targetCals > 0 ? (cals / targetCals).clamp(0.0, 2.0) : 0.0;
    final status = _calorieStatus(cals, targetCals);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.soft),
      child: Row(children: [
        // Ring
        SizedBox(
          width: 100, height: 100,
          child: CustomPaint(
            painter: _CalorieRingPainter(progress.toDouble(), status.color),
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${cals.toInt()}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: status.color)),
              Text('/ ${targetCals.toInt()} kcal', style: const TextStyle(fontSize: 10, color: MoewColors.textSub)),
            ])),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(status.label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: status.color)),
          const SizedBox(height: 4),
          Text('Mục tiêu: ${targetCals.toInt()} kcal/ngày', style: const TextStyle(fontSize: 12, color: MoewColors.textSub)),
          Text('Cân nặng: ${target['weight'] ?? '?'}kg', style: const TextStyle(fontSize: 12, color: MoewColors.textSub)),
          if (target['isKitten'] == true) Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: MoewColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(MoewRadius.full)),
            child: const Text('Mèo con', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: MoewColors.accent)),
          ),
        ])),
      ]),
    );
  }

  Widget _buildTodayStats() {
    final today = _stats!['today'] as Map<String, dynamic>? ?? {};
    return Row(children: [
      _statCard('Bữa ăn', '${today['meals'] ?? 0}', Icons.restaurant, MoewColors.primary),
      const SizedBox(width: 10),
      _statCard('Điểm TB', '${(today['avgScore'] ?? 0).toStringAsFixed(1)}', Icons.star, MoewColors.warning),
      const SizedBox(width: 10),
      _statCard('Tổng logs', '${_stats!['totalLogs'] ?? 0}', Icons.history, MoewColors.accent),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.md), boxShadow: MoewShadows.soft),
      child: Column(children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: MoewColors.textSub)),
      ]),
    ));
  }

  Widget _buildWeekChart() {
    final weekChart = _stats!['weekChart'] as List? ?? [];
    final target = _stats!['target'] as Map<String, dynamic>? ?? {};
    final targetCal = (target['dailyCalories'] ?? 200) as num;
    final maxCal = weekChart.fold<num>(targetCal, (m, d) => max(m, (d['calories'] ?? 0) as num)) * 1.2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.soft),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Tuần này', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            ...weekChart.map<Widget>((d) {
              final cal = (d['calories'] ?? 0) as num;
              final h = maxCal > 0 ? (cal / maxCal * 110).clamp(4.0, 110.0) : 4.0;
              final isToday = d == weekChart.last;
              final barStatus = _calorieStatus(cal, targetCal);
              return Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text('${cal.toInt()}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: barStatus.color)),
                  const SizedBox(height: 2),
                  Container(
                    height: h.toDouble(),
                    decoration: BoxDecoration(
                      color: isToday ? MoewColors.primary : barStatus.color.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(d['day']?.toString() ?? '', style: TextStyle(fontSize: 11, fontWeight: isToday ? FontWeight.w800 : FontWeight.w500, color: isToday ? MoewColors.primary : MoewColors.textSub)),
                ]),
              ));
            }),
          ]),
        ),
        // Target line label
        const SizedBox(height: 8),
        Row(children: [
          Container(width: 20, height: 2, color: MoewColors.success),
          const SizedBox(width: 4),
          Text('Mục tiêu: ${targetCal.toInt()} kcal', style: const TextStyle(fontSize: 10, color: MoewColors.textSub)),
        ]),
      ]),
    );
  }
}

class _CalorieRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _CalorieRingPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 6;
    final bgPaint = Paint()..color = MoewColors.border..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round;
    final fgPaint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    final angle = 2 * pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, angle, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
