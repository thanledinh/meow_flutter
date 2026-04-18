import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../api/expense_api.dart';
import '../../utils/parse_utils.dart';
import '../../widgets/toast.dart';
import '../../widgets/common_widgets.dart';
import '../../api/pet_api.dart';
import '../../models/pet_model.dart';
import 'package:go_router/go_router.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  List<dynamic> _expenses = [];
  Map<String, dynamic>? _summary;
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  int _totalPages = 1;
  String? _selectedPetId;
  String? _from;
  String? _to;
  List<PetModel> _pets = [];

  @override
  void initState() {
    super.initState();
    _fetchPets();
    _fetchData();
  }

  Future<void> _fetchPets() async {
    try {
      final res = await PetApi.getAll();
      if (res.success && mounted) {
        final List items = (res.data is Map ? res.data['data'] : res.data) ?? [];
        setState(() {
          _pets = items.map((e) => PetModel.fromJson(e)).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchData({bool refresh = true}) async {
    if (!mounted) return;
    if (refresh) {
      setState(() {
        _loading = true;
        _page = 1;
      });
      // Fetch summary
      try {
        final sumRes = await ExpenseApi.getSummary(petId: _selectedPetId, from: _from, to: _to);
        if (sumRes.success) {
          final sData = (sumRes.data as Map?)?['data'];
          if (mounted) setState(() => _summary = sData);
        }
      } catch (e) {
        debugPrint('Failed to load summary: $e');
      }
    } else {
      setState(() => _loadingMore = true);
    }

    try {
      final res = await ExpenseApi.getExpenses(
        page: _page,
        petId: _selectedPetId,
        from: _from,
        to: _to,
      );
      if (!mounted) return;
      if (res.success) {
        final dData = (res.data as Map?)?['data'];
        final items = dData?['items'] as List? ?? [];
        final pagination = dData?['pagination'] as Map? ?? {};
        setState(() {
          if (refresh) {
            _expenses = items;
          } else {
            _expenses.addAll(items);
          }
          _totalPages = pagination['totalPages'] ?? 1;
        });
      } else {
        if (mounted) MoewToast.show(context, message: res.error ?? 'Lỗi tải danh sách', type: ToastType.error);
      }
    } catch (e) {
      if (mounted) MoewToast.show(context, message: 'Lỗi mạng', type: ToastType.error);
    }

    if (mounted) {
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _deleteExpense(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xoá chi tiêu?'),
        content: const Text('Bạn có chắc muốn xoá khoản chi này? (Xoá mềm)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Huỷ', style: TextStyle(color: MoewColors.textSub))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Xoá', style: TextStyle(color: MoewColors.danger))),
        ],
      ),
    );
    if (confirm != true) return;
    
    final res = await ExpenseApi.deleteExpense(id);
    if (!mounted) return;
    if (res.success) {
      MoewToast.show(context, message: 'Đã xoá', type: ToastType.success);
      _fetchData();
    } else {
      MoewToast.show(context, message: res.error ?? 'Lỗi xoá', type: ToastType.error);
    }
  }

  void _showFilterSheet() {
    // Basic filter sheet for petId, from, to
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: MoewSpacing.lg, right: MoewSpacing.lg, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: MoewColors.border, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Bộ lọc thời gian', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final d = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                      if (d != null) setState(() => _from = d.toIso8601String().split('T')[0]);
                      _fetchData();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: MoewColors.background, foregroundColor: MoewColors.textMain),
                    child: Text(_from ?? 'Từ ngày'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final d = await showDatePicker(context: ctx, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                      if (d != null) setState(() => _to = d.toIso8601String().split('T')[0]);
                      _fetchData();
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: MoewColors.background, foregroundColor: MoewColors.textMain),
                    child: Text(_to ?? 'Đến ngày'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_pets.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedPetId,
                decoration: InputDecoration(
                  labelText: 'Lọc theo thú cưng',
                  prefixIcon: const Icon(Icons.pets),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(MoewRadius.md)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tất cả thú cưng')),
                  ..._pets.map((p) => DropdownMenuItem(value: p.id.toString(), child: Text(p.name))),
                ],
                onChanged: (val) {
                  setState(() => _selectedPetId = val);
                  _fetchData();
                  Navigator.pop(ctx);
                },
              ),
            if (_pets.isNotEmpty) const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() { _from = null; _to = null; _selectedPetId = null; });
                  _fetchData();
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: MoewColors.danger.withValues(alpha: 0.1), foregroundColor: MoewColors.danger),
                child: const Text('Bỏ lọc'),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: AppHeader(
        title: 'Quản lý chi tiêu',
        actions: [
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: () => context.push('/expense-calendar'),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: MoewColors.primary,
        onPressed: () async {
          final res = await context.push('/expense-capture');
          if (res == true && mounted) _fetchData();
        },
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchData(),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_summary != null) _buildSummaryCard(),
                  const SizedBox(height: 24),
                  Text('LỊCH SỬ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: MoewColors.textSub, letterSpacing: 1)),
                  const SizedBox(height: 12),
                  if (_expenses.isEmpty)
                    EmptyState(icon: Icons.receipt_long, color: MoewColors.textSub, message: 'Chưa có khoản chi nào')
                  else
                    ..._expenses.map((e) => _buildExpenseItem(e)),
                  if (_page < _totalPages)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: _loadingMore
                            ? const CircularProgressIndicator()
                            : TextButton(
                                onPressed: () {
                                  setState(() => _page++);
                                  _fetchData(refresh: false);
                                },
                                child: const Text('Xem thêm'),
                              ),
                      ),
                    ),
                  const SizedBox(height: 80), // offset for fab
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final tAmount = toDouble(_summary?['totalAmount']);
    final tCount = _summary?['totalCount'] ?? 0;
    final avg = toDouble(_summary?['avgPerDay']);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MoewColors.white,
        borderRadius: BorderRadius.circular(MoewRadius.xl),
        boxShadow: MoewShadows.card,
        border: Border.all(color: MoewColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tổng chi tiêu', style: TextStyle(fontSize: 13, color: MoewColors.textSub, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(formatVND(tAmount), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: MoewColors.primary)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Số lần chi', style: TextStyle(fontSize: 12, color: MoewColors.textSub)),
                    const SizedBox(height: 4),
                    Text('$tCount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: MoewColors.textMain)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trung bình/ngày', style: TextStyle(fontSize: 12, color: MoewColors.textSub)),
                    const SizedBox(height: 4),
                    Text(formatVND(avg), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: MoewColors.textMain)),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildExpenseItem(Map<dynamic, dynamic> e) {
    final amount = toDouble(e['amount']);
    final date = e['date']?.toString().split('T')[0] ?? '';
    final note = e['note']?.toString() ?? 'Ghi chú trống';
    final hasImage = (e['imageUrl'] != null && e['imageUrl'].toString().isNotEmpty);

    return Dismissible(
      key: Key(e['id'].toString()),
      background: Container(
        color: MoewColors.danger,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        setState(() {
          _expenses.removeWhere((item) => item['id'] == e['id']);
        });
      },
      confirmDismiss: (dir) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Xoá chi tiêu?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Xoá', style: TextStyle(color: MoewColors.danger))),
            ],
          ),
        );
        if (confirm != true) return false;
        
        final res = await ExpenseApi.deleteExpense(e['id']);
        if (!mounted) return false;
        
        if (res.success) {
          MoewToast.show(context, message: 'Đã xoá', type: ToastType.success);
          _fetchData(refresh: true);
          return true;
        } else {
          MoewToast.show(context, message: res.error ?? 'Lỗi xoá', type: ToastType.error);
          _fetchData(refresh: true);
          return false;
        }
      },
      child: GestureDetector(
        onTap: () async {
          final res = await context.push('/expense-capture', extra: e);
          if (res == true && mounted) _fetchData();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MoewColors.border.withValues(alpha: 0.3)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: MoewColors.background,
                  borderRadius: BorderRadius.circular(12),
                  image: hasImage ? DecorationImage(image: NetworkImage(e['imageUrl']), fit: BoxFit.cover) : null,
                ),
                child: !hasImage ? Icon(Icons.receipt, color: MoewColors.primary) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(note, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: MoewColors.textMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(date, style: TextStyle(fontSize: 12, color: MoewColors.textSub)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(formatVND(amount), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: MoewColors.danger)),
            ],
          ),
        ),
      ),
    );
  }
}
