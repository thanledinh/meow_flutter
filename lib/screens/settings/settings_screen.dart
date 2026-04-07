import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/firebase_messaging_service.dart';
import '../../providers/preferences_provider.dart';
import '../../widgets/toast.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifEnabled = true;
  bool _notifLoading = false;
  String? _pendingTheme;
  bool _isSavingTheme = false;

  static const _items = [
    {'icon': Icons.monitor_heart_outlined, 'label': 'Lịch sử SOS', 'sub': 'Xem các lần gọi cấp cứu', 'route': '/sos-history'},
    {'icon': Icons.calendar_month_outlined, 'label': 'Lịch sử đặt lịch', 'sub': 'Xem lịch hẹn phòng khám', 'route': '/booking-history'},
    {'icon': Icons.chat_bubble_outline, 'label': 'Chat AI cũ', 'sub': 'Xem lại các cuộc hội thoại', 'route': '/chat-sessions'},
    {'icon': Icons.account_balance_wallet_outlined, 'label': 'Ví Meow-Care', 'sub': 'Quản lý ví và giao dịch', 'route': '/wallet'},
    {'icon': Icons.notifications_outlined, 'label': 'Thông báo', 'sub': 'Xem lịch sử thông báo', 'route': '/notifications'},
  ];

  @override
  void initState() {
    super.initState();
    _loadNotifPref();
  }

  Future<void> _loadNotifPref() async {
    final enabled = await FirebaseMessagingService().isEnabled();
    if (mounted) setState(() => _notifEnabled = enabled);
  }

  Future<void> _toggleNotif(bool value) async {
    setState(() { _notifEnabled = value; _notifLoading = true; });
    final svc = FirebaseMessagingService();
    if (value) {
      await svc.enableNotifications();
    } else {
      await svc.disableNotifications();
    }
    if (mounted) setState(() => _notifLoading = false);
  }

  Widget _buildThemeSelector(BuildContext context, PreferencesProvider provider) {
    if (_pendingTheme == null) {
      _pendingTheme = provider.prefs.presetTheme;
    }

    final presets = [
      {'id': 'sakura', 'name': 'Sakura (Hồng)', 'color': Color(0xFFE8628A)},
      {'id': 'lavender', 'name': 'Lavender', 'color': Color(0xFF7C6CD6)},
      {'id': 'peach', 'name': 'Peach (Cam)', 'color': Color(0xFFE8844A)},
      {'id': 'sage', 'name': 'Sage (Xanh)', 'color': Color(0xFF4A9B7F)},
      {'id': 'midnight', 'name': 'Midnight Dark', 'color': Color(0xFFA78BFA)},
    ];

    bool hasChanged = _pendingTheme != provider.prefs.presetTheme;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: MoewColors.white,
        borderRadius: BorderRadius.circular(MoewRadius.lg),
        boxShadow: MoewShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chủ đề ứng dụng',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MoewColors.textMain),
              ),
              if (hasChanged)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: MoewColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text('Chưa lưu', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: MoewColors.accent)),
                ),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: presets.length,
              separatorBuilder: (_, __) => SizedBox(width: 12),
              itemBuilder: (context, index) {
                final preset = presets[index];
                final isSelected = _pendingTheme == preset['id'];
                
                return GestureDetector(
                  onTap: () => setState(() => _pendingTheme = preset['id'] as String),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: 60,
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: preset['color'] as Color,
                            shape: BoxShape.circle,
                            border: isSelected 
                                ? Border.all(color: MoewColors.textMain, width: 3)
                                : Border.all(color: Colors.transparent, width: 3),
                            boxShadow: isSelected ? MoewShadows.card : null,
                          ),
                          child: isSelected 
                              ? Icon(Icons.check, color: Colors.white, size: 22)
                              : null,
                        ),
                        SizedBox(height: 8),
                        Text(
                          preset['name'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? MoewColors.textMain : MoewColors.textSub,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          if (hasChanged) ...[
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: MoewColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoewRadius.md)),
                  elevation: 0,
                ),
                onPressed: _isSavingTheme ? null : () async {
                  setState(() => _isSavingTheme = true);
                  await provider.setThemePreset(_pendingTheme!);
                  setState(() => _isSavingTheme = false);
                  if (mounted) MoewToast.show(context, message: 'Đã đổi giao diện thành công!', type: ToastType.success);
                },
                child: _isSavingTheme 
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Áp dụng giao diện', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrefToggle(String title, String desc, bool value, Function(bool) onChanged) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: MoewColors.white,
          borderRadius: BorderRadius.circular(MoewRadius.lg),
          boxShadow: MoewShadows.card,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: MoewColors.textMain)),
                  SizedBox(height: 2),
                  Text(desc, style: MoewTextStyles.caption),
                ]
              )
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: MoewColors.primary,
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefsProvider = context.watch<PreferencesProvider>();

    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: AppHeader(title: 'Cài đặt'),
      body: ListView(
        padding: EdgeInsets.all(MoewSpacing.lg),
        children: [
          _buildThemeSelector(context, prefsProvider),
          SizedBox(height: 24),
          
          Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Thiết lập thông báo (API)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: MoewColors.textMain),
            ),
          ),
          
          _buildPrefToggle(
            'Lịch ăn uống',
            'Nhận lời nhắc cho ăn hàng ngày',
            prefsProvider.prefs.notifyFeeding,
            (v) => prefsProvider.toggleNotification('notifyFeeding', v)
          ),
          _buildPrefToggle(
            'Sức khoẻ & Tiêm phòng',
            'Cảnh báo đến hạn tiêm, sổ giun',
            prefsProvider.prefs.notifyHealth,
            (v) => prefsProvider.toggleNotification('notifyHealth', v)
          ),
          _buildPrefToggle(
            'Tương tác mạng xã hội',
            'Lượt thích, bình luận, kết bạn mới',
            prefsProvider.prefs.notifySocial,
            (v) => prefsProvider.toggleNotification('notifySocial', v)
          ),
          _buildPrefToggle(
            'Lịch khám thú y',
            'Nhắc nhở trước giờ đến phòng khám',
            prefsProvider.prefs.notifyBooking,
            (v) => prefsProvider.toggleNotification('notifyBooking', v)
          ),

          SizedBox(height: 24),
          
          Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Tính năng khác',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: MoewColors.textMain),
            ),
          ),
          
          // ═══ Menu Items ═══
          ..._items.map((item) => Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, item['route'] as String),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MoewColors.white,
                  borderRadius: BorderRadius.circular(MoewRadius.lg),
                  boxShadow: MoewShadows.card,
                ),
                child: Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: MoewColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item['icon'] as IconData, size: 20, color: MoewColors.primary),
                  ),
                  SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item['label'] as String, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MoewColors.textMain)),
                    SizedBox(height: 2),
                    Text(item['sub'] as String, style: MoewTextStyles.caption),
                  ])),
                  Icon(Icons.chevron_right, size: 20, color: MoewColors.textSub),
                ]),
              ),
            ),
          )),
          
          SizedBox(height: 24),
        ],
      ),
    );
  }
}
