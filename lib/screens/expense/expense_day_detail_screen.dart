import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../api/expense_api.dart';
import '../../utils/parse_utils.dart';
import '../../widgets/toast.dart';
import '../../widgets/common_widgets.dart';

class ExpenseDayDetailScreen extends StatefulWidget {
  final String date;
  final String? petId;

  const ExpenseDayDetailScreen({super.key, required this.date, this.petId});

  @override
  State<ExpenseDayDetailScreen> createState() => _ExpenseDayDetailScreenState();
}

class _ExpenseDayDetailScreenState extends State<ExpenseDayDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final res = await ExpenseApi.getDayDetail(date: widget.date, petId: widget.petId);
    if (!mounted) return;
    if (res.success) {
      final payload = (res.data as Map?)?['data'];
      setState(() {
        _data = payload;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      MoewToast.show(context, message: res.error ?? 'Lỗi tải dữ liệu ngày', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: AppHeader(title: 'Chi tiết ${widget.date}'),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _data == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EmptyState(icon: Icons.error_outline, message: 'Không thể tải dữ liệu', color: MoewColors.textSub),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetch,
                          style: ElevatedButton.styleFrom(backgroundColor: MoewColors.background, foregroundColor: MoewColors.textMain),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(MoewSpacing.lg),
                    children: [
                      _buildSummary(),
                      const SizedBox(height: MoewSpacing.lg),
                      Text('CÁC KHOẢN CHI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: MoewColors.textSub, letterSpacing: 1)),
                      const SizedBox(height: MoewSpacing.md),
                      ...((_data!['items'] as List?) ?? []).map((e) => _buildItem(e)),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSummary() {
    final tAmount = toDouble(_data!['totalAmount']);
    final count = _data!['count'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: MoewColors.primary, borderRadius: BorderRadius.circular(MoewRadius.lg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tổng trong ngày', style: TextStyle(color: Colors.white70)),
          Text(formatVND(tAmount), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('$count khoản chi', style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildItem(Map<dynamic, dynamic> e) {
    final amount = toDouble(e['amount']);
    final note = e['note']?.toString() ?? 'Ghi chú trống';
    final hasImage = (e['imageUrl'] != null && e['imageUrl'].toString().isNotEmpty);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MoewColors.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: MoewColors.background,
              borderRadius: BorderRadius.circular(8),
              image: hasImage ? DecorationImage(image: NetworkImage(e['imageUrl']), fit: BoxFit.cover) : null,
            ),
            child: !hasImage ? Icon(Icons.receipt_long, size: 20, color: MoewColors.primary) : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(note, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text(formatVND(amount), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: MoewColors.danger)),
        ],
      ),
    );
  }
}
