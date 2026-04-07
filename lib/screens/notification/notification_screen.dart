import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../api/notification_api.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/toast.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final res = await NotificationApi.getHistory();
    if (!mounted) return;
    final data = (res.data as Map?)?['data'];
    setState(() {
      _notifications = data?['notifications'] ?? [];
      _unreadCount = data?['unreadCount'] ?? 0;
      _loading = false;
    });
  }

  Future<void> _markRead(Map<String, dynamic> n) async {
    if (n['isRead'] == true) return;
    await NotificationApi.markRead(n['id']);
    setState(() {
      n['isRead'] = true;
      _unreadCount = (_unreadCount - 1).clamp(0, 9999);
    });
  }

  Future<void> _readAll() async {
    final res = await NotificationApi.readAll();
    if (!mounted) return;
    if (res.success) {
      setState(() {
        for (var n in _notifications) {
          if (n is Map) n['isRead'] = true;
        }
        _unreadCount = 0;
      });
      MoewToast.show(context, message: 'Đã đọc tất cả', type: ToastType.success);
    }
  }

  // Type → icon + color
  Map<String, Map<String, dynamic>> get _typeConfig => {
    'system':      {'icon': Icons.campaign_outlined,          'color': MoewColors.primary},
    'feeding':     {'icon': Icons.restaurant_outlined,        'color': MoewColors.secondary},
    'booking':     {'icon': Icons.calendar_month_outlined,    'color': MoewColors.accent},
    'vaccine':     {'icon': Icons.vaccines_outlined,          'color': MoewColors.success},
    'appointment': {'icon': Icons.schedule_outlined,          'color': MoewColors.primary},
    'sos':         {'icon': Icons.emergency_outlined,         'color': MoewColors.danger},
  };

  IconData _icon(String? type) => (_typeConfig[type]?['icon'] as IconData?) ?? Icons.notifications_outlined;
  Color _color(String? type) => (_typeConfig[type]?['color'] as Color?) ?? MoewColors.primary;

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return dateStr;
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return dateStr.substring(0, 10);
  }

  void _onTapNotification(Map<String, dynamic> n) {
    _markRead(n);
    final data = n['data'] as Map<String, dynamic>?;
    if (data == null) return;
    final screen = data['screen'] as String?;
    switch (screen) {
      case 'Feeding':
      case 'FeedingDetail':
        Navigator.pushNamed(context, '/food-history', arguments: data['scheduleId']);
        break;
      case 'Vaccine':
      case 'VaccinationDetail':
        // Navigate to vaccine screen (would need petId)
        break;
      case 'BookingDetail':
        Navigator.pushNamed(context, '/booking-history');
        break;
      case 'Home':
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: AppHeader(
        title: 'Thông báo',
        showBack: false,
        actions: _unreadCount > 0
            ? [
                GestureDetector(
                  onTap: _readAll,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: MoewColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(MoewRadius.full),
                    ),
                    child: Text('Đọc hết', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: MoewColors.primary)),
                  ),
                ),
              ]
            : null,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: MoewColors.primary))
          : _notifications.isEmpty
              ? EmptyState(icon: Icons.notifications_none, color: MoewColors.textSub, message: 'Chưa có thông báo')
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(MoewSpacing.lg, MoewSpacing.lg, MoewSpacing.lg, 110),
                    itemCount: _notifications.length + (_unreadCount > 0 ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      // Unread count header
                      if (_unreadCount > 0 && i == 0) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Row(children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: MoewColors.danger, borderRadius: BorderRadius.circular(MoewRadius.full)),
                              child: Text('$_unreadCount chưa đọc', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                            ),
                          ]),
                        );
                      }

                      final idx = _unreadCount > 0 ? i - 1 : i;
                      final n = _notifications[idx] as Map<String, dynamic>;
                      final isRead = n['isRead'] == true;
                      final type = n['type'] as String?;

                      return GestureDetector(
                        onTap: () => _onTapNotification(n),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isRead ? MoewColors.white : MoewColors.primary.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(MoewRadius.lg),
                            boxShadow: MoewShadows.card,
                            border: isRead ? null : Border.all(color: MoewColors.primary.withValues(alpha: 0.12), width: 1),
                          ),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            // Type icon
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                color: _color(type).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(_icon(type), size: 20, color: _color(type)),
                            ),
                            SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(
                                  n['title'] ?? '',
                                  style: TextStyle(fontSize: 14, fontWeight: isRead ? FontWeight.w600 : FontWeight.w800, color: MoewColors.textMain),
                                  maxLines: 2, overflow: TextOverflow.ellipsis,
                                )),
                                if (!isRead) ...[
                                  SizedBox(width: 8),
                                  Container(width: 8, height: 8, decoration: BoxDecoration(color: MoewColors.danger, shape: BoxShape.circle)),
                                ],
                              ]),
                              if (n['body'] != null) Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(n['body'], style: TextStyle(fontSize: 13, color: isRead ? MoewColors.textSub : MoewColors.textMain), maxLines: 2, overflow: TextOverflow.ellipsis),
                              ),
                              Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: Text(_timeAgo(n['createdAt']?.toString()), style: TextStyle(fontSize: 11, color: MoewColors.textSub)),
                              ),
                            ])),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
