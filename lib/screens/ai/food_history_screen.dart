import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../api/ai_api.dart';
import '../../widgets/common_widgets.dart';

class FoodHistoryScreen extends StatefulWidget {
  final dynamic petId;
  const FoodHistoryScreen({super.key, required this.petId});
  @override
  State<FoodHistoryScreen> createState() => _FoodHistoryScreenState();
}

class _FoodHistoryScreenState extends State<FoodHistoryScreen> {
  List<dynamic> _logs = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final res = await AiApi.foodHistory(widget.petId);
    if (!mounted) return;
    setState(() {
      final raw = res.data;
      // API returns {data: {totalCalories, mealCount, meals: [...]}}
      if (raw is Map && raw['data'] is Map && raw['data']['meals'] is List) {
        _logs = raw['data']['meals'];
      } else if (raw is Map && raw['data'] is List) {
        _logs = raw['data'];
      } else {
        _logs = [];
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: AppHeader(title: 'Lịch sử ăn uống'),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: MoewColors.primary))
          : _logs.isEmpty
              ? EmptyState(icon: Icons.restaurant_outlined, color: MoewColors.secondary, message: 'Chưa có lịch sử ăn')
              : RefreshIndicator(onRefresh: _fetch, child: ListView.builder(
                  padding: EdgeInsets.all(MoewSpacing.lg),
                  itemCount: _logs.length,
                  itemBuilder: (ctx, i) {
                    final log = _logs[i] as Map<String, dynamic>;
                    return Container(
                      margin: EdgeInsets.only(bottom: MoewSpacing.sm),
                      padding: EdgeInsets.all(MoewSpacing.md),
                      decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.card),
                      child: Row(children: [
                        Container(width: 40, height: 40, decoration: BoxDecoration(color: MoewColors.tintAmber, borderRadius: BorderRadius.circular(MoewRadius.sm)), child: Icon(Icons.restaurant, size: 20, color: MoewColors.secondary)),
                        SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(log['foodName'] ?? 'Bữa ăn', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MoewColors.textMain)),
                          Row(children: [
                            if (log['estimatedCalories'] != null) Text('${log['estimatedCalories']} kcal', style: TextStyle(fontSize: 12, color: MoewColors.secondary, fontWeight: FontWeight.w600)),
                            if (log['mealTime'] != null) ...[Text(' · ', style: MoewTextStyles.caption), Text(log['mealTime'], style: MoewTextStyles.caption)],
                          ]),
                        ])),
                        if (log['suitabilityScore'] != null) Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (log['suitabilityScore'] as num) >= 7 ? MoewColors.tintGreen : (log['suitabilityScore'] as num) >= 5 ? MoewColors.tintAmber : MoewColors.tintRed,
                            borderRadius: BorderRadius.circular(MoewRadius.sm),
                          ),
                          child: Text('${log['suitabilityScore']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: (log['suitabilityScore'] as num) >= 7 ? MoewColors.success : (log['suitabilityScore'] as num) >= 5 ? MoewColors.warning : MoewColors.danger)),
                        ),
                      ]),
                    );
                  },
                )),
    );
  }
}
