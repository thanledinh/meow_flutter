import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../api/notification_api.dart';
import '../../widgets/common_widgets.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> _notifications = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final res = await NotificationApi.getHistory();
    if (!mounted) return;
    setState(() { _notifications = (res.data as Map?)?['data'] ?? []; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: const AppHeader(title: 'Thông báo'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MoewColors.primary))
          : _notifications.isEmpty
              ? const EmptyState(icon: Icons.notifications_none, color: MoewColors.textSub, message: 'Chưa có thông báo')
              : RefreshIndicator(onRefresh: _fetch, child: ListView.builder(
                  padding: const EdgeInsets.all(MoewSpacing.lg),
                  itemCount: _notifications.length,
                  itemBuilder: (ctx, i) {
                    final n = _notifications[i] as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: MoewSpacing.sm),
                      padding: const EdgeInsets.all(MoewSpacing.md),
                      decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.card),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: MoewColors.tintBlue, borderRadius: BorderRadius.circular(MoewRadius.sm)),
                          child: const Icon(Icons.notifications, size: 20, color: MoewColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(n['title'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MoewColors.textMain)),
                          if (n['body'] != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(n['body'], style: MoewTextStyles.body)),
                          if (n['createdAt'] != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(n['createdAt'].toString().substring(0, 16).replaceAll('T', ' '), style: MoewTextStyles.caption)),
                        ])),
                      ]),
                    );
                  },
                )),
    );
  }
}
