import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/common_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _items = [
    {'icon': Icons.monitor_heart_outlined, 'label': 'Lịch sử SOS', 'sub': 'Xem các lần gọi cấp cứu', 'route': '/sos-history'},
    {'icon': Icons.calendar_month_outlined, 'label': 'Lịch sử đặt lịch', 'sub': 'Xem lịch hẹn phòng khám', 'route': '/booking-history'},
    {'icon': Icons.chat_bubble_outline, 'label': 'Chat AI cũ', 'sub': 'Xem lại các cuộc hội thoại', 'route': '/chat-sessions'},
    {'icon': Icons.account_balance_wallet_outlined, 'label': 'Ví Meow-Care', 'sub': 'Quản lý ví và giao dịch', 'route': '/wallet'},
    {'icon': Icons.notifications_outlined, 'label': 'Thông báo', 'sub': 'Quản lý thông báo', 'route': '/notifications'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: const AppHeader(title: 'Cài đặt'),
      body: ListView.separated(
        padding: const EdgeInsets.all(MoewSpacing.lg),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final item = _items[i];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, item['route'] as String),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MoewColors.white,
                borderRadius: BorderRadius.circular(MoewRadius.lg),
                boxShadow: MoewShadows.card,
              ),
              child: Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: MoewColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item['icon'] as IconData, size: 20, color: MoewColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item['label'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MoewColors.textMain)),
                  const SizedBox(height: 2),
                  Text(item['sub'] as String, style: MoewTextStyles.caption),
                ])),
                const Icon(Icons.chevron_right, size: 20, color: MoewColors.textSub),
              ]),
            ),
          );
        },
      ),
    );
  }
}
