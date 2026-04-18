import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../api/expense_api.dart';
import '../../utils/parse_utils.dart';
import '../../widgets/toast.dart';
import '../../widgets/common_widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ExpenseCalendarScreen extends StatefulWidget {
  final String? petId;
  const ExpenseCalendarScreen({super.key, this.petId});

  @override
  State<ExpenseCalendarScreen> createState() => _ExpenseCalendarScreenState();
}

class _ExpenseCalendarScreenState extends State<ExpenseCalendarScreen> {
  DateTime _currentMonth = DateTime.now();
  Map<String, dynamic>? _calendarData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  String get _monthStr => DateFormat('yyyy-MM').format(_currentMonth);

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final res = await ExpenseApi.getCalendar(month: _monthStr, petId: widget.petId);
    if (!mounted) return;
    if (res.success) {
      final payload = (res.data as Map?)?['data'];
      setState(() {
        _calendarData = payload;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      MoewToast.show(context, message: res.error ?? 'Lỗi tải lịch', type: ToastType.error);
    }
  }

  void _nextMonth() {
    setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1));
    _fetch();
  }

  void _prevMonth() {
    setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1));
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: AppHeader(title: 'Lịch chi tiêu'),
      body: Column(
        children: [
          _buildMonthSelector(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildCalendarGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: _prevMonth),
          Text(DateFormat('MM/yyyy').format(_currentMonth), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextMonth),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    if (_calendarData == null) return EmptyState(icon: Icons.calendar_today, message: 'Dữ liệu trống', color: MoewColors.textSub);

    final days = (_calendarData!['days'] as List?) ?? [];
    if (days.isEmpty) return EmptyState(icon: Icons.calendar_today, message: 'Tháng này chưa có dữ liệu', color: MoewColors.textSub);

    // To respect actual weekday of 1st day of month
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final prevMonthDaysOffset = firstDay.weekday - 1; // 1 = Monday, 7 = Sunday => 0 offset if Monday

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.7,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: days.length + prevMonthDaysOffset + 7, // +7 for header row
      itemBuilder: (ctx, idx) {
        if (idx < 7) {
          final weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
          return Center(child: Text(weekdays[idx], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: MoewColors.textSub)));
        }

        final cellIdx = idx - 7;
        if (cellIdx < prevMonthDaysOffset) return const SizedBox(); // empty cell
        
        final dayIdx = cellIdx - prevMonthDaysOffset;
        if (dayIdx >= days.length) return const SizedBox();

        final dayInfo = days[dayIdx] as Map;
        final tAmount = toDouble(dayInfo['totalAmount']);
        final dayNum = dayIdx + 1;
        final thumb = dayInfo['thumbnailUrl']?.toString();

        final isToday = dayInfo['date'] == DateTime.now().toIso8601String().split('T')[0];

        return GestureDetector(
          onTap: () {
            context.push('/expense-day?date=${dayInfo['date']}');
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: isToday ? Border.all(color: MoewColors.primary, width: 2) : Border.all(color: MoewColors.border.withValues(alpha: 0.3)),
              image: thumb != null ? DecorationImage(image: NetworkImage(thumb), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.4), BlendMode.darken)) : null,
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 2, left: 4,
                  child: Text('$dayNum', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: thumb != null ? Colors.white : (isToday ? MoewColors.primary : MoewColors.textMain))),
                ),
                if (tAmount > 0)
                  Positioned(
                    bottom: 2, right: 2, left: 2,
                    child: Text(formatShortAmount(tAmount), textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: thumb != null ? Colors.white : MoewColors.danger)),
                  )
              ],
            ),
          ),
        );
      },
    );
  }

  // Utility local format
  String formatShortAmount(double amt) {
    if (amt >= 1000000) return '${(amt / 1000000).toStringAsFixed(1)}Tr';
    if (amt >= 1000) return '${(amt / 1000).toStringAsFixed(0)}K';
    return amt.toStringAsFixed(0);
  }
}
