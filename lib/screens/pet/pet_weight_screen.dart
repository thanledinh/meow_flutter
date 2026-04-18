import 'package:flutter/material.dart';
import 'dart:math';
import '../../config/theme.dart';
import '../../api/pet_api.dart';
import '../../widgets/toast.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/weight_chart.dart';

class PetWeightScreen extends StatefulWidget {
  final dynamic petId;
  const PetWeightScreen({super.key, required this.petId});
  @override
  State<PetWeightScreen> createState() => _PetWeightScreenState();
}

class _PetWeightScreenState extends State<PetWeightScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    final res = await PetApi.getWeightHistory(widget.petId);
    if (!mounted) return;
    final raw = res.data;
    setState(() {
      _data = (raw is Map) ? (raw['data'] is Map ? raw['data'] as Map<String, dynamic> : raw as Map<String, dynamic>) : null;
      _loading = false;
    });
  }

  Future<void> _showAddWeight() async {
    final weightCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setBS) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Cân nặng hôm nay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          SizedBox(height: 4),
          Text(_data?['pet']?['name'] ?? 'Pet', style: TextStyle(fontSize: 12, color: MoewColors.textSub)),
          SizedBox(height: 14),
          TextField(controller: weightCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), autofocus: true, decoration: const InputDecoration(labelText: 'Cân nặng (kg) *', suffixText: 'kg', prefixIcon: Icon(Icons.monitor_weight, size: 18))),
          SizedBox(height: 10),
          TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Ghi chú (tùy chọn)', prefixIcon: Icon(Icons.edit_note, size: 18))),
          SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: saving ? null : () async {
              if (weightCtrl.text.trim().isEmpty) { MoewToast.show(ctx, message: 'Nhập cân nặng', type: ToastType.warning); return; }
              setBS(() => saving = true);
              final body = <String, dynamic>{ 'weight': double.tryParse(weightCtrl.text.trim()) ?? 0 };
              if (noteCtrl.text.trim().isNotEmpty) body['note'] = noteCtrl.text.trim();
              final res = await PetApi.addWeight(widget.petId, body);
              if (!mounted || !ctx.mounted) return;
              setBS(() => saving = false);
              if (res.success) { Navigator.pop(ctx); MoewToast.show(context, message: res.data?['message'] ?? 'Đã ghi nhận!', type: ToastType.success); _fetch(); }
              else { MoewToast.show(ctx, message: res.error ?? 'Lỗi', type: ToastType.error); }
            },
            style: ElevatedButton.styleFrom(backgroundColor: MoewColors.primary, padding: EdgeInsets.symmetric(vertical: 14)),
            child: saving ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Lưu', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          )),
        ]),
      )),
    );
  }

  Future<void> _deleteLog(Map<String, dynamic> log) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text('Xóa?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      content: Text('Xóa bản ghi ${log['weight']}kg ngày ${log['date']?.toString().substring(0, 10) ?? ''}?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Hủy')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Xóa', style: TextStyle(color: MoewColors.danger))),
      ],
    ));
    if (ok != true) return;
    final res = await PetApi.deleteWeightLog(widget.petId, log['id']);
    if (!mounted) return;
    if (res.success) { MoewToast.show(context, message: 'Đã xóa', type: ToastType.success); _fetch(); }
    else { MoewToast.show(context, message: res.error ?? 'Lỗi', type: ToastType.error); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: AppHeader(title: 'Theo dõi cân nặng'),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddWeight,
        backgroundColor: MoewColors.primary,
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: MoewColors.primary))
          : _data == null
              ? EmptyState(icon: Icons.monitor_weight, color: MoewColors.primary, message: 'Chưa có dữ liệu')
              : ListView(padding: EdgeInsets.all(MoewSpacing.md), children: [
                  _buildSummary(),
                  SizedBox(height: 14),
                  _buildChart(),
                  SizedBox(height: 14),
                  _buildHistory(),
                ]),
    );
  }

  Widget _buildSummary() {
    final pet = _data!['pet'] as Map? ?? {};
    final trend = _data!['trend'] as Map? ?? {};
    final stats = _data!['stats'] as Map? ?? {};
    final needsWeighIn = _data!['needsWeighIn'] == true;
    final daysSince = _data!['daysSinceLastWeigh'];

    final direction = trend['direction']?.toString() ?? 'stable';
    final trendIcon = direction == 'gaining' ? Icons.trending_up : direction == 'losing' ? Icons.trending_down : Icons.trending_flat;
    final trendColor = direction == 'gaining' ? MoewColors.warning : direction == 'losing' ? MoewColors.danger : MoewColors.success;
    final trendLabel = direction == 'gaining' ? 'Tăng cân' : direction == 'losing' ? 'Giảm cân' : 'Ổn định';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.soft),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.monitor_weight, size: 20, color: MoewColors.primary),
          SizedBox(width: 8),
          Text(pet['name']?.toString() ?? 'Pet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: trendColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(MoewRadius.full)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(trendIcon, size: 14, color: trendColor),
              SizedBox(width: 4),
              Text(trendLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: trendColor)),
            ]),
          ),
        ]),
        SizedBox(height: 12),
        // Current weight big
        Row(children: [
          Text('${stats['current'] ?? pet['currentWeight'] ?? '?'}', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: MoewColors.primary)),
          Text(' kg', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: MoewColors.textSub)),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (trend['changeKg'] != null) Text('${(trend['changeKg'] as num) > 0 ? '+' : ''}${trend['changeKg']}kg (${trend['changePercent'] ?? 0}%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: trendColor)),
            if (daysSince != null) Text('$daysSince ngày trước', style: TextStyle(fontSize: 11, color: MoewColors.textSub)),
          ]),
        ]),
        if (needsWeighIn) ...[
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: MoewColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(MoewRadius.sm)),
            child: Row(children: [
              Icon(Icons.notifications_active, size: 14, color: MoewColors.warning),
              SizedBox(width: 6),
              Text('Nên cân lại — đã lâu chưa cập nhật', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: MoewColors.warning)),
            ]),
          ),
        ],
        SizedBox(height: 10),
        // Stats row
        Row(children: [
          _miniStat('Min', '${stats['min'] ?? '-'}kg'),
          _miniStat('Max', '${stats['max'] ?? '-'}kg'),
          _miniStat('TB', '${stats['avg'] ?? '-'}kg'),
          _miniStat('Lần cân', '${stats['count'] ?? 0}'),
        ]),
      ]),
    );
  }

  Widget _miniStat(String label, String value) {
    return Expanded(child: Column(children: [
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      Text(label, style: TextStyle(fontSize: 10, color: MoewColors.textSub)),
    ]));
  }

  Widget _buildChart() {
    final chart = _data!['chart'] as List? ?? [];
    if (chart.isEmpty) return SizedBox();

    return WeightChartBox(
      chartData: chart,
      height: 120,
      showTitle: true,
    );
  }

  Widget _buildHistory() {
    final chart = _data!['chart'] as List? ?? [];
    if (chart.isEmpty) return EmptyState(icon: Icons.history, color: MoewColors.textSub, message: 'Chưa có bản ghi');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Lịch sử', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      SizedBox(height: 8),
      ...chart.reversed.map<Widget>((log) {
        final m = log as Map<String, dynamic>;
        final date = m['date']?.toString().substring(0, 10) ?? '';
        return Container(
          margin: EdgeInsets.only(bottom: 6),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.md), boxShadow: MoewShadows.soft),
          child: Row(children: [
            Icon(Icons.monitor_weight, size: 16, color: MoewColors.primary),
            SizedBox(width: 8),
            Text('${m['weight']}kg', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            SizedBox(width: 8),
            Text(date, style: TextStyle(fontSize: 11, color: MoewColors.textSub)),
            if (m['note'] != null) ...[SizedBox(width: 8), Expanded(child: Text(m['note'].toString(), style: TextStyle(fontSize: 10, color: MoewColors.textSub, fontStyle: FontStyle.italic), overflow: TextOverflow.ellipsis))],
            if (m['note'] == null) const Spacer(),
            GestureDetector(
              onTap: () => _deleteLog(m),
              child: Icon(Icons.close, size: 16, color: MoewColors.textSub),
            ),
          ]),
        );
      }),
    ]);
  }
}

