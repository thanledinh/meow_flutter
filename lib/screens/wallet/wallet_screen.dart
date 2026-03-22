import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../api/wallet_api.dart';
import '../../utils/parse_utils.dart';
import '../../widgets/toast.dart';
import '../../widgets/common_widgets.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Map<String, dynamic>? _wallet;
  List<dynamic> _transactions = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final res = await WalletApi.get();
    if (!mounted) return;
    final raw = res.data;
    final data = (raw is Map) ? (raw['data'] ?? raw) : null;
    setState(() {
      if (data is Map<String, dynamic>) {
        _wallet = data;
        _transactions = (data['transactions'] is List) ? data['transactions'] : [];
      }
      _loading = false;
    });
  }

  double get _balance => toDouble(_wallet?['balance']);
  double get _debt => toDouble(_wallet?['debt']);

  String _typeLabel(String type) {
    switch (type) {
      case 'topup': return 'Nạp tiền';
      case 'debit': return 'Thanh toán';
      case 'debt': return 'Ghi nợ';
      case 'repay': return 'Trả nợ';
      default: return type;
    }
  }

  void _showTopup() {
    final amountCtrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: MoewSpacing.lg, right: MoewSpacing.lg, top: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: MoewColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: MoewSpacing.md),
          Text('Nạp tiền', style: MoewTextStyles.h2),
          const SizedBox(height: MoewSpacing.lg),
          TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Số tiền (VNĐ)', prefixIcon: Icon(Icons.attach_money))),
          const SizedBox(height: MoewSpacing.lg),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text);
              if (amount == null || amount <= 0) return;
              Navigator.pop(ctx);
              final res = await WalletApi.topup(amount);
              if (mounted) {
                if (res.success) { MoewToast.show(context, message: 'Nạp thành công!', type: ToastType.success); _fetch(); }
                else { MoewToast.show(context, message: res.error ?? 'Lỗi', type: ToastType.error); }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: MoewColors.success),
            child: Text('Nạp tiền', style: MoewTextStyles.button),
          )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: const AppHeader(title: 'Ví Meow-Care'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MoewColors.primary))
          : ListView(padding: const EdgeInsets.all(MoewSpacing.lg), children: [
              // Balance card
              Container(
                padding: const EdgeInsets.all(MoewSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [MoewColors.primary, Color(0xFF1A6BA0)]),
                  borderRadius: BorderRadius.circular(MoewRadius.xl),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('SỐ DƯ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70, letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(formatVND(_balance), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                  if (_debt > 0) Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(children: [
                      const Icon(Icons.warning, size: 16, color: MoewColors.warning),
                      const SizedBox(width: 4),
                      Text('Nợ: ${formatVND(_debt)}', style: const TextStyle(color: MoewColors.warning, fontSize: 14, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  const SizedBox(height: MoewSpacing.md),
                  Row(children: [
                    Expanded(child: ElevatedButton(
                      onPressed: _showTopup,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.2), foregroundColor: Colors.white),
                      child: const Text('Nạp tiền'),
                    )),
                    if (_debt > 0) ...[
                      const SizedBox(width: 8),
                      Expanded(child: ElevatedButton(
                        onPressed: () async {
                          final res = await WalletApi.repay(_debt);
                          if (mounted) {
                            if (res.success) { MoewToast.show(context, message: 'Đã trả nợ!', type: ToastType.success); _fetch(); }
                            else { MoewToast.show(context, message: res.error ?? 'Lỗi', type: ToastType.error); }
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: MoewColors.warning, foregroundColor: Colors.white),
                        child: Text('Trả nợ'),
                      )),
                    ],
                  ]),
                ]),
              ),
              const SizedBox(height: MoewSpacing.xl),

              // Transactions
              Text('LỊCH SỬ GIAO DỊCH', style: MoewTextStyles.label),
              const SizedBox(height: MoewSpacing.md),
              if (_transactions.isEmpty)
                const EmptyState(icon: Icons.receipt_long, color: MoewColors.textSub, message: 'Chưa có giao dịch')
              else
                ..._transactions.map((t) {
                  final amount = toDouble(t['amount']);
                  final type = t['type']?.toString() ?? '';
                  final isPositive = type == 'topup' || type == 'repay';
                  final label = t['note']?.toString() ?? _typeLabel(type);
                  return Container(
                    margin: const EdgeInsets.only(bottom: MoewSpacing.sm),
                    padding: const EdgeInsets.all(MoewSpacing.md),
                    decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.md), boxShadow: MoewShadows.card),
                    child: Row(children: [
                      Icon(isPositive ? Icons.add_circle : Icons.remove_circle, color: isPositive ? MoewColors.success : MoewColors.danger, size: 24),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: MoewColors.textMain)),
                        if (t['createdAt'] != null) Text(t['createdAt'].toString().length >= 16 ? t['createdAt'].toString().substring(0, 16).replaceAll('T', ' ') : t['createdAt'].toString(), style: MoewTextStyles.caption),
                      ])),
                      Text('${isPositive ? '+' : '-'}${formatVND(amount)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isPositive ? MoewColors.success : MoewColors.danger)),
                    ]),
                  );
                }),
            ]),
    );
  }
}
