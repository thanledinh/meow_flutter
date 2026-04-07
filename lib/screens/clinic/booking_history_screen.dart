import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../api/clinic_api.dart';
import '../../widgets/toast.dart';
import '../../widgets/common_widgets.dart';
import '../../services/mqtt_service.dart';

const _statusTabs = [
  {'key': null, 'label': 'Tất cả'},
  {'key': 'pending', 'label': 'Chờ xác nhận'},
  {'key': 'confirmed', 'label': 'Đã xác nhận'},
  {'key': 'completed', 'label': 'Hoàn thành'},
  {'key': 'cancelled', 'label': 'Đã hủy'},
];

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});
  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  List<dynamic> _bookings = [];
  bool _loading = true;
  String? _statusFilter;
  StreamSubscription? _mqttSub;

  @override
  void initState() {
    super.initState();
    _fetch();
    _listenMqtt();
  }

  void _listenMqtt() {
    _mqttSub = MqttService().messageStream.listen((data) {
      if (!mounted) return;
      final type = data['type'] as String?;
      switch (type) {
        case 'booking_created':
          MoewToast.show(
            context,
            message: data['title']?.toString() ?? 'Đặt lịch thành công!',
            type: ToastType.success,
          );
          _fetch(); // refresh list
          break;

        case 'booking_status':
          final status = data['status']?.toString();
          const labels = {
            'confirmed': 'Lịch hẹn đã được xác nhận!',
            'completed': 'Lịch hẹn hoàn thành!',
            'cancelled': 'Lịch hẹn bị hủy.',
          };
          if (status != null && labels.containsKey(status)) {
            MoewToast.show(
              context,
              message: labels[status]!,
              type: status == 'cancelled' ? ToastType.error : ToastType.success,
            );
            _fetch(); // refresh list
          }
          break;
      }
    });
  }

  @override
  void dispose() {
    _mqttSub?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final res = await ClinicApi.getBookings(status: _statusFilter);
    if (!mounted) return;
    final raw = res.data;
    setState(() {
      final data = (raw is Map) ? raw['data'] : raw;
      _bookings = data is List ? data : [];
      _loading = false;
    });
  }

  Future<void> _cancelBooking(Map<String, dynamic> booking) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hủy lịch hẹn?'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Bạn muốn hủy lịch tại ${booking['clinic']?['name'] ?? 'phòng khám'}?', style: MoewTextStyles.body),
          SizedBox(height: 12),
          TextField(controller: reasonCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'Lý do hủy (tùy chọn)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Không')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hủy lịch', style: TextStyle(color: MoewColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final res = await ClinicApi.cancelBooking(booking['id'], reason: reasonCtrl.text.trim());
    if (!mounted) return;
    if (res.success) {
      MoewToast.show(context, message: 'Đã hủy lịch hẹn', type: ToastType.success);
      _fetch();
    } else {
      MoewToast.show(context, message: res.error ?? 'Lỗi hủy', type: ToastType.error);
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'confirmed': return MoewColors.success;
      case 'cancelled': return MoewColors.danger;
      case 'completed': return MoewColors.primary;
      default: return MoewColors.warning;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'pending': return 'Chờ xác nhận';
      case 'confirmed': return 'Đã xác nhận';
      case 'completed': return 'Hoàn thành';
      case 'cancelled': return 'Đã hủy';
      default: return status ?? 'Không rõ';
    }
  }

  String _serviceLabel(String? type) {
    switch (type) {
      case 'checkup': return 'Khám tổng quát';
      case 'vaccination': return 'Tiêm phòng';
      case 'grooming': return 'Spa & Grooming';
      case 'dental': return 'Nha khoa';
      case 'surgery': return 'Phẫu thuật';
      case 'emergency': return 'Cấp cứu';
      default: return type ?? 'Khác';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: const AppHeader(title: 'Lịch hẹn'),
      body: Column(children: [
        // ── Status filter tabs ──
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: MoewSpacing.md),
            children: _statusTabs.map((t) {
              final active = _statusFilter == t['key'];
              return GestureDetector(
                onTap: () {
                  setState(() => _statusFilter = t['key']);
                  _fetch();
                },
                child: Container(
                  margin: EdgeInsets.only(right: 8),
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? MoewColors.primary : MoewColors.white,
                    borderRadius: BorderRadius.circular(MoewRadius.full),
                    border: Border.all(color: active ? MoewColors.primary : MoewColors.border),
                  ),
                  child: Center(child: Text(t['label'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : MoewColors.textSub))),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: MoewSpacing.sm),

        // ── Booking list ──
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: MoewColors.primary))
              : _bookings.isEmpty
                  ? EmptyState(icon: Icons.calendar_month, color: MoewColors.primary, message: 'Không có lịch hẹn nào')
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      child: ListView.builder(
                        padding: EdgeInsets.all(MoewSpacing.md),
                        itemCount: _bookings.length,
                        itemBuilder: (ctx, i) => _buildBookingCard(_bookings[i] as Map<String, dynamic>),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> b) {
    final status = b['status']?.toString();
    final color = _statusColor(status);
    final canCancel = status == 'pending' || status == 'confirmed';

    return Container(
      margin: EdgeInsets.only(bottom: MoewSpacing.sm),
      decoration: BoxDecoration(
        color: MoewColors.white,
        borderRadius: BorderRadius.circular(MoewRadius.lg),
        boxShadow: MoewShadows.soft,
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(MoewSpacing.md),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header: clinic name + status
          Row(children: [
            Expanded(child: Text(
              (b['clinic'] is Map ? b['clinic']['name'] : '') ?? 'Phòng khám',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: MoewColors.textMain),
              overflow: TextOverflow.ellipsis,
            )),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(MoewRadius.full)),
              child: Text(_statusLabel(status), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
            ),
          ]),
          SizedBox(height: 10),

          // Info rows
          _infoRow(Icons.pets, b['pet'] is Map ? b['pet']['name'] ?? '' : ''),
          _infoRow(Icons.medical_services_outlined, _serviceLabel(b['serviceType']?.toString())),
          _infoRow(Icons.calendar_month, b['date'] != null ? b['date'].toString().substring(0, 10) : ''),
          if (b['timeSlot'] != null) _infoRow(Icons.access_time, b['timeSlot'].toString()),
          if (b['notes'] != null && b['notes'].toString().isNotEmpty) _infoRow(Icons.notes, b['notes'].toString()),
          if (b['totalCost'] != null) _infoRow(Icons.attach_money, '${b['totalCost']} VNĐ'),
          if (b['cancelReason'] != null && b['cancelReason'].toString().isNotEmpty)
            _infoRow(Icons.info_outline, 'Lý do: ${b['cancelReason']}', color: MoewColors.danger),

          // Cancel button
          if (canCancel) ...[
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _cancelBooking(b),
                icon: Icon(Icons.cancel_outlined, size: 16, color: MoewColors.danger),
                label: Text('Hủy lịch hẹn', style: TextStyle(color: MoewColors.danger, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: MoewColors.danger), padding: EdgeInsets.symmetric(vertical: 10)),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    if (text.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Icon(icon, size: 14, color: color ?? MoewColors.textSub),
        SizedBox(width: 6),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: color ?? MoewColors.textSub), maxLines: 2, overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}
