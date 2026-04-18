import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/theme.dart';
import '../api/api_client.dart';
import '../api/feeding_api.dart';
import '../api/pet_api.dart';
import '../utils/parse_utils.dart';
import 'common_widgets.dart';
import 'toast.dart';

class TodayScheduleBox extends StatefulWidget {
  const TodayScheduleBox({super.key});

  @override
  State<TodayScheduleBox> createState() => TodayScheduleBoxState();
}

class TodayScheduleBoxState extends State<TodayScheduleBox>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _hasError = false;
  List<dynamic> _feedingTimeline = [];
  List<Map<String, dynamic>> _upcomingEvents = [];

  // GoRouter listener để detect khi navigate back về /home
  GoRouter? _goRouter;
  VoidCallback? _routerListener;
  String _prevLocation = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.of(context);
    if (_goRouter != router) {
      if (_routerListener != null) {
        _goRouter?.routerDelegate.removeListener(_routerListener!);
      }
      _goRouter = router;
      // Ghi nhớ location hiện tại (lúc này đang ở /home)
      _prevLocation = router.routerDelegate.currentConfiguration.uri.path;
      _routerListener = _onRouteChanged;
      _goRouter!.routerDelegate.addListener(_routerListener!);
    }
  }

  /// Được gọi mỗi khi route thay đổi.
  /// Refresh khi URI trở về '/home' từ màn hình khác.
  void _onRouteChanged() {
    if (!mounted) return;
    final loc = _goRouter!.routerDelegate.currentConfiguration.uri.path;
    // Chỉ refresh khi: trước đó KHÔNG phải /home, giờ là /home, và không đang load
    if (loc == '/home' && _prevLocation != '/home' && !_loading) {
      _fetchData();
    }
    _prevLocation = loc;
  }

  /// Refresh khi app từ background trở về foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted && !_loading) {
      _fetchData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_routerListener != null) {
      _goRouter?.routerDelegate.removeListener(_routerListener!);
    }
    super.dispose();
  }


  /// Gọi từ bên ngoài qua GlobalKey (e.g. pull-to-refresh ở HomeScreen)
  Future<void> refresh() => _fetchData();

  // Map type → icon + màu
  static IconData _iconFor(String type) {
    switch (type) {
      case 'feeding':    return Icons.restaurant;
      case 'weigh_in':   return Icons.monitor_weight_outlined;
      case 'vaccine':    return Icons.vaccines;
      case 'booking':    return Icons.medical_services_outlined;
      default:           return Icons.event_note;
    }
  }

  static Color _colorFor(String type) {
    switch (type) {
      case 'feeding':    return MoewColors.primary;
      case 'weigh_in':   return MoewColors.warning;
      case 'vaccine':    return MoewColors.accent;
      case 'booking':    return MoewColors.secondary;
      default:           return MoewColors.textSub;
    }
  }

  Future<void> _fetchData() async {
    setState(() { _loading = true; _hasError = false; });
    try {
      // Bước 1: song song feeding timeline + danh sách pets
      final base = await Future.wait([
        FeedingApi.getToday(),
        PetApi.getAll(),
      ]);
      if (!mounted) return;

      // Feeding timeline (left column)
      final feedData = base[0].data is Map
          ? (base[0].data['data'] ?? base[0].data)
          : null;
      if (feedData is Map && feedData['timeline'] is List) {
        _feedingTimeline = feedData['timeline'];
      }

      // Bước 2: gọi schedule API cho từng pet song song — 1 endpoint thay tất cả
      final petsRaw = base[1].data;
      final petsList = petsRaw is List
          ? petsRaw
          : (petsRaw is Map && petsRaw['data'] is List ? petsRaw['data'] as List : []);

      List<Map<String, dynamic>> merged = [];
      if (petsList.isNotEmpty) {
        final schedResults = await Future.wait(
          petsList.map<Future<ApiResponse>>((p) => PetApi.getSchedule(p['id'])).toList(),
        );
        if (!mounted) return;

        for (int i = 0; i < schedResults.length; i++) {
          final petId = petsList[i]['id'];
          final petName = petsList[i]['name']?.toString() ?? 'Bé mèo';
          final raw = schedResults[i].data;
          // Response: { success: true, data: [...] }
          final events = raw is Map && raw['data'] is List
              ? raw['data'] as List
              : (raw is List ? raw : []);

          for (final ev in events) {
            if (ev is! Map) continue;
            final type = ev['type']?.toString() ?? 'event';
            // Bỏ feeding khỏi right column — đã có feeding timeline riêng bên trái
            if (type == 'feeding') continue;

            final dateStr = ev['date']?.toString() ?? '';
            if (dateStr.isEmpty) continue;

            // Parse datetime — backend trả UTC ISO → toLocal()
            DateTime? dt;
            try {
              dt = DateTime.parse(dateStr).toLocal();
            } catch (_) {}

            merged.add({
              'type': type,
              'title': ev['title']?.toString() ?? type,
              'subtitle': '$petName: ${ev['description']?.toString() ?? ''}',
              'dateStr': dateStr,
              'dt': dt,
              'icon': _iconFor(type),
              'color': _colorFor(type),
              'petId': petId,
              'petName': petName,
            });
          }
        }

        // Dedup: các event giống nhau về type, thười gian và CỦA CÙNG 1 PET
        final seen = <String>{};
        merged = merged.where((e) {
          final type = e['type'] as String? ?? '';
          final pid = e['petId']?.toString() ?? '';
          final key = '${type}_${e['dateStr']}_$pid';
          return seen.add(key);
        }).toList();

        // Sort theo datetime tăng dần (backend đã sort nhưng merge có thể xáo trộn)
        merged.sort((a, b) {
          final d1 = a['dt'] as DateTime?;
          final d2 = b['dt'] as DateTime?;
          if (d1 != null && d2 != null) return d1.compareTo(d2);
          return 0;
        });
      }

      if (mounted) setState(() {
        _upcomingEvents = merged.take(4).toList();
        _loading = false;
      });

    } catch (e, stack) {
      print('TodayScheduleBox fetch error: $e\n$stack');
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }





  @override

  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        margin: const EdgeInsets.symmetric(
          horizontal: MoewSpacing.lg,
          vertical: MoewSpacing.sm,
        ),
        height: 120,
        decoration: BoxDecoration(
          color: MoewColors.white,
          borderRadius: BorderRadius.circular(MoewRadius.xl),
          boxShadow: MoewShadows.card,
        ),
        child: Center(
          child: CircularProgressIndicator(color: MoewColors.primary),
        ),
      );
    }

    if (_hasError) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: MoewSpacing.lg, vertical: MoewSpacing.sm),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: MoewColors.white,
          borderRadius: BorderRadius.circular(MoewRadius.xl),
          boxShadow: MoewShadows.card,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 36, color: MoewColors.textSub.withOpacity(0.5)),
              const SizedBox(height: 12),
              Text(
                'Lỗi tải lịch trình hệ thống',
                style: TextStyle(color: MoewColors.textSub, fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _fetchData,
                child: Text('Tải lại', style: TextStyle(color: MoewColors.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    if (_feedingTimeline.isEmpty && _upcomingEvents.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: MoewSpacing.lg, vertical: MoewSpacing.sm),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: MoewColors.white,
          borderRadius: BorderRadius.circular(MoewRadius.xl),
          boxShadow: MoewShadows.card,
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.event_available_rounded, size: 40, color: MoewColors.border),
              const SizedBox(height: 12),
              Text(
                'Chưa có lịch trình nào hôm nay',
                style: TextStyle(color: MoewColors.textSub, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    List<Widget> feedNodes = [];
    for (int i = 0; i < _feedingTimeline.length; i++) {
      final meal = _feedingTimeline[i];
      final isFed = meal['isFed'] == true;
      feedNodes.add(
        _CompactTimelineNode(
          isFirst: i == 0,
          isLast: i == _feedingTimeline.length - 1,
          isCompleted: isFed,
          color: MoewColors.primary,
          title: '${meal['label'] ?? 'Bữa'} (${meal['time'] ?? '--:--'})',
          subtitle: isFed ? 'Đã cho ăn' : 'Chưa cho ăn',
          onTap: () => context.push('/feeding-today'),
        ),
      );
    }
    if (feedNodes.isEmpty) {
      feedNodes.add(
        Padding(
          padding: EdgeInsets.only(left: 22, top: 8),
          child: Text(
            'Trống',
            style: TextStyle(color: MoewColors.textSub, fontSize: 12),
          ),
        ),
      );
    }

    List<Widget> eventNodes = [];
    for (int i = 0; i < _upcomingEvents.length; i++) {
      final ev = _upcomingEvents[i];
      eventNodes.add(
        _CompactTimelineNode(
          isFirst: i == 0,
          isLast: i == _upcomingEvents.length - 1,
          isCompleted: false, // upcoming is typically not completed
          icon: ev['icon'],
          color: ev['color'],
          title: _fmtDate(ev),
          subtitle: '${ev['title']} - ${ev['subtitle']}',
          onTap: () {
            if (ev['type'] == 'booking') {
              context.push('/clinic-list');
            } else {
              final pid = ev['petId']?.toString();
              if (pid != null && pid.isNotEmpty) {
                if (ev['type'] == 'weigh_in') {
                  context.push('/pet-weight', extra: pid);
                } else if (ev['type'] == 'vaccine') {
                  context.push('/pet-vaccines', extra: pid);
                } else {
                  context.push('/medical', extra: pid);
                }
              } else {
                MoewToast.show(context, message: 'Dữ liệu bị lỗi (thiếu id thú cưng)', type: ToastType.error);
              }
            }
          },
        ),
      );
    }
    if (eventNodes.isEmpty) {
      eventNodes.add(
        Padding(
          padding: EdgeInsets.only(left: 22, top: 8),
          child: Text(
            'Trống',
            style: TextStyle(color: MoewColors.textSub, fontSize: 12),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MoewRadius.xl),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.07),
            blurRadius: 32,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, color: MoewColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Khung lịch trình',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: MoewColors.textMain,
                ),
              ),
              const Spacer(),
              _Badge(
                text:
                    '${_feedingTimeline.length + _upcomingEvents.length} sự kiện',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_feedingTimeline.isNotEmpty && _upcomingEvents.isNotEmpty)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.restaurant,
                              size: 14,
                              color: MoewColors.primary,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Lịch ăn',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: MoewColors.textMain,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        ...feedNodes,
                      ],
                    ),
                  ),
                  VerticalDivider(
                    color: MoewColors.border,
                    width: 24,
                    thickness: 1,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.pets,
                              size: 14,
                              color: MoewColors.accent,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Sắp tới',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: MoewColors.textMain,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        ...eventNodes,
                      ],
                    ),
                  ),
                ],
              ),
            )
          else if (_feedingTimeline.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.restaurant, size: 14, color: MoewColors.primary),
                    SizedBox(width: 6),
                    Text(
                      'Lịch ăn hôm nay',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: MoewColors.textMain,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ...feedNodes,
              ],
            )
          else if (_upcomingEvents.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.pets, size: 14, color: MoewColors.accent),
                    SizedBox(width: 6),
                    Text(
                      'Sự kiện sắp tới',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: MoewColors.textMain,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ...eventNodes,
              ],
            ),
        ],
      ),
    );
  }

  String _fmtDate(Map<String, dynamic> ev) {
    final dt = ev['dt'] as DateTime?;
    if (dt != null) {
      final now = DateTime.now();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      final timeStr = '$h:$m';

      final todayStart = DateTime(now.year, now.month, now.day);
      final evDay = DateTime(dt.year, dt.month, dt.day);
      final diff = evDay.difference(todayStart).inDays;

      if (diff == 0) return 'Hôm nay $timeStr';
      if (diff == 1) return 'Ngày mai $timeStr';

      final d = dt.day.toString().padLeft(2, '0');
      final mo = dt.month.toString().padLeft(2, '0');
      return '$d/$mo $timeStr';
    }

    // fallback
    final iso = ev['dateStr'].toString();
    if (iso.length >= 16) {
      final date = iso.substring(8, 10) + '/' + iso.substring(5, 7);
      final time = iso.substring(11, 16);
      return '$date $time';
    } else if (iso.length >= 10) {
      return iso.substring(8, 10) + '/' + iso.substring(5, 7);
    }
    return iso;
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: MoewColors.tintBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: MoewColors.primary,
        ),
      ),
    );
  }
}

class _CompactTimelineNode extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final bool isCompleted;
  final IconData? icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _CompactTimelineNode({
    required this.isFirst,
    required this.isLast,
    required this.isCompleted,
    this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = isCompleted ? MoewColors.success : MoewColors.border;
    final lineColor = isCompleted
        ? MoewColors.success
        : MoewColors.border.withValues(alpha: 0.5);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 14,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst ? Colors.transparent : lineColor,
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: dotColor, width: 2),
                    color: MoewColors.white,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : lineColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(MoewRadius.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? MoewColors.success.withValues(alpha: 0.05)
                        : MoewColors.surface,
                    borderRadius: BorderRadius.circular(MoewRadius.md),
                  ),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 14, color: color),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: MoewColors.textMain,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 10,
                                color: MoewColors.textSub,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
