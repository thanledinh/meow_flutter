import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../api/feeding_api.dart';
import '../../widgets/common_widgets.dart';

class FoodHistoryScreen extends StatefulWidget {
  final dynamic petId;
  const FoodHistoryScreen({super.key, required this.petId});
  @override
  State<FoodHistoryScreen> createState() => _FoodHistoryScreenState();
}

class _FoodHistoryScreenState extends State<FoodHistoryScreen> {
  List<dynamic> _history = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  int _total = 0;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch({bool reset = true}) async {
    if (reset) {
      setState(() { _page = 1; _loading = true; });
    }
    final res = await FeedingApi.getFeedingHistory(petId: widget.petId, page: _page);
    if (!mounted) return;
    final raw = res.data;
    final data = (raw is Map) ? raw['data'] : null;
    final history = (data is Map ? data['history'] : null) as List? ?? [];
    final pagination = (data is Map ? data['pagination'] : null) as Map? ?? {};
    setState(() {
      if (reset) {
        _history = history;
      } else {
        _history.addAll(history);
      }
      _total = (pagination['total'] ?? 0) as int;
      _loading = false;
      _loadingMore = false;
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _history.length >= _total) return;
    setState(() { _page++; _loadingMore = true; });
    await _fetch(reset: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: const AppHeader(title: 'Lịch sử ăn'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MoewColors.primary))
          : _history.isEmpty
              ? const EmptyState(icon: Icons.restaurant, color: MoewColors.primary, message: 'Chưa có lịch sử ăn')
              : NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n is ScrollEndNotification && n.metrics.pixels > n.metrics.maxScrollExtent - 100) _loadMore();
                      return false;
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(MoewSpacing.md),
                      itemCount: _history.length + (_loadingMore ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == _history.length) return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: MoewColors.primary, strokeWidth: 2)));
                        return _buildDayGroup(_history[i] as Map<String, dynamic>);
                      },
                    ),
                  ),
    );
  }

  Widget _buildDayGroup(Map<String, dynamic> dayData) {
    final date = dayData['date']?.toString() ?? '';
    final totalCal = (dayData['totalCalories'] ?? 0) as num;
    final items = dayData['items'] as List? ?? [];

    // Format date
    String dateLabel = date;
    final now = DateTime.now();
    final dateStr = date.length >= 10 ? date.substring(0, 10) : date;
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    if (dateStr == today) dateLabel = 'Hôm nay';
    else if (dateStr == yesterdayStr) dateLabel = 'Hôm qua';
    else dateLabel = dateStr.split('-').reversed.join('/');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Day header
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Text(dateLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: MoewColors.textMain)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: MoewColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(MoewRadius.full)),
            child: Text('${totalCal.toInt()} kcal', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: MoewColors.primary)),
          ),
        ]),
      ),

      // Items
      ...items.map<Widget>((item) {
        final m = item as Map<String, dynamic>;
        final isFeeding = m['type'] == 'feeding';
        final isScan = m['type'] == 'ai_scan';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: MoewColors.white,
            borderRadius: BorderRadius.circular(MoewRadius.md),
            boxShadow: MoewShadows.soft,
            border: Border(left: BorderSide(color: isFeeding ? MoewColors.success : MoewColors.accent, width: 3)),
          ),
          child: Row(children: [
            // Icon
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: (isFeeding ? MoewColors.success : MoewColors.accent).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(MoewRadius.sm),
              ),
              child: Icon(
                isFeeding ? Icons.restaurant : isScan ? Icons.qr_code_scanner : Icons.history,
                size: 18,
                color: isFeeding ? MoewColors.success : MoewColors.accent,
              ),
            ),
            const SizedBox(width: 10),
            // Details
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(m['label']?.toString() ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: MoewColors.textMain)),
                if (m['time'] != null) Text(' ・ ${m['time']}', style: const TextStyle(fontSize: 11, color: MoewColors.textSub)),
              ]),
              const SizedBox(height: 2),
              Text('${m['petName'] ?? ''} — ${m['foodName'] ?? ''}', style: const TextStyle(fontSize: 11, color: MoewColors.textSub)),
              if (m['note'] != null && m['note'].toString().isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(m['note'].toString(), style: const TextStyle(fontSize: 10, color: MoewColors.textSub, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ])),
            // Cal + grams
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (m['calories'] != null) Text('${m['calories']} kcal', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MoewColors.primary)),
              if (m['grams'] != null) Text('${m['grams']}g', style: const TextStyle(fontSize: 10, color: MoewColors.textSub)),
            ]),
          ]),
        );
      }),

      const SizedBox(height: 4),
    ]);
  }
}
