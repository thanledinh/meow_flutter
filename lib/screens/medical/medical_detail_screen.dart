import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../utils/parse_utils.dart';
import '../../widgets/common_widgets.dart';

class MedicalDetailScreen extends StatelessWidget {
  final Map<String, dynamic> record;
  const MedicalDetailScreen({super.key, required this.record});

  Color _statusColor(String? s) {
    switch (s) {
      case 'chronic': return MoewColors.warning;
      case 'resolved': case 'cured': case 'recovered': return MoewColors.success;
      case 'active': case 'ongoing': return MoewColors.danger;
      default: return MoewColors.primary;
    }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'chronic': return 'Mãn tính';
      case 'resolved': case 'cured': case 'recovered': return 'Đã khỏi';
      case 'active': case 'ongoing': return 'Đang điều trị';
      case 'monitoring': return 'Theo dõi';
      default: return s ?? 'Không rõ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (record['name'] ?? record['title'] ?? record['vaccineName'] ?? record['reason'] ?? 'Hồ sơ').toString();
    final type = (record['type'] ?? '').toString();
    final status = record['status']?.toString();
    final cost = toDouble(record['cost']);
    final startDate = record['startDate']?.toString() ?? record['date']?.toString() ?? '';
    final endDate = record['endDate']?.toString() ?? '';

    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: AppHeader(title: _typeTitle(type)),
      body: ListView(
        padding: EdgeInsets.all(MoewSpacing.lg),
        children: [
          // ── Header card ──
          Container(
            padding: EdgeInsets.all(MoewSpacing.lg),
            decoration: BoxDecoration(
              color: MoewColors.white,
              borderRadius: BorderRadius.circular(MoewRadius.xl),
              boxShadow: MoewShadows.card,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(MoewRadius.md),
                  ),
                  child: Icon(_typeIcon(type), size: 24, color: _statusColor(status)),
                ),
                SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: MoewTextStyles.h3),
                  SizedBox(height: 4),
                  if (status != null) StatusBadge(label: _statusLabel(status), color: _statusColor(status), icon: Icons.circle),
                ])),
              ]),
              if (type.isNotEmpty) ...[
                SizedBox(height: 12),
                _chip(_typeLabel(type), MoewColors.primary),
              ],
            ]),
          ),
          SizedBox(height: MoewSpacing.md),

          // ── Info card ──
          _card([
            if (record['symptoms'] != null) _row('Triệu chứng', record['symptoms'].toString(), Icons.sick_outlined, MoewColors.danger),
            if (record['diagnosis'] != null) _row('Chẩn đoán', record['diagnosis'].toString(), Icons.search, MoewColors.primary),
            if (record['treatment'] != null) _row('Điều trị', record['treatment'].toString(), Icons.healing_outlined, MoewColors.success),
            // Vaccine-specific fields
            if (record['batchNumber'] != null) _row('Mã lô vaccine', record['batchNumber'].toString(), Icons.qr_code, MoewColors.accent),
            if (record['dose'] != null) _row('Liều', 'Mũi ${record['dose']}', Icons.vaccines, MoewColors.primary),
            if (record['nextDoseDate'] != null) _row('Lịch tiêm tiếp', _fmtDate(record['nextDoseDate'].toString()), Icons.event, MoewColors.warning),
            // Appointment-specific
            if (record['reason'] != null && record['title'] != null) _row('Lý do', record['reason'].toString(), Icons.help_outline, MoewColors.primary),
            // Common
            if (record['veterinarian'] != null) _row('Bác sĩ', record['veterinarian'].toString(), Icons.person_outline, MoewColors.accent),
            if (record['clinic'] != null) _row('Phòng khám', record['clinic'].toString(), Icons.medical_services_outlined, MoewColors.primary),
          ]),
          SizedBox(height: MoewSpacing.md),

          // ── Time & Cost card ──
          _card([
            if (startDate.isNotEmpty) _row('Ngày bắt đầu', _fmtDate(startDate), Icons.calendar_today, MoewColors.primary),
            if (endDate.isNotEmpty && endDate != 'null') _row('Ngày kết thúc', _fmtDate(endDate), Icons.event_available, MoewColors.success),
            if (cost > 0) _row('Chi phí', formatVND(cost), Icons.attach_money, MoewColors.secondary),
          ]),

          // ── Notes ──
          if (record['notes'] != null && record['notes'].toString().isNotEmpty) ...[
            SizedBox(height: MoewSpacing.md),
            Container(
              padding: EdgeInsets.all(MoewSpacing.md),
              decoration: BoxDecoration(
                color: MoewColors.tintYellow,
                borderRadius: BorderRadius.circular(MoewRadius.lg),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.note_outlined, size: 20, color: MoewColors.secondary),
                SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('GHI CHÚ', style: MoewTextStyles.label),
                  SizedBox(height: 4),
                  Text(record['notes'].toString(), style: MoewTextStyles.body),
                ])),
              ]),
            ),
          ],

          // ── Related record ──
          if (record['relatedFrom'] is Map) ...[
            SizedBox(height: MoewSpacing.md),
            Container(
              padding: EdgeInsets.all(MoewSpacing.md),
              decoration: BoxDecoration(
                color: MoewColors.tintBlue,
                borderRadius: BorderRadius.circular(MoewRadius.lg),
              ),
              child: Row(children: [
                Icon(Icons.link, size: 20, color: MoewColors.primary),
                SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('LIÊN QUAN', style: MoewTextStyles.label),
                  SizedBox(height: 4),
                  Text((record['relatedFrom'] as Map)['name']?.toString() ?? 'Hồ sơ liên quan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: MoewColors.primary)),
                ])),
              ]),
            ),
          ],

          SizedBox(height: MoewSpacing.md),

          // ── Mini Bill (Cost Items) ──
          if (record['costItems'] != null && (record['costItems'] as List).isNotEmpty) ...[
            SizedBox(height: MoewSpacing.md),
            Text('HÓA ĐƠN CHI TIẾT', style: MoewTextStyles.label),
            SizedBox(height: MoewSpacing.sm),
            ...((record['costItems'] as List).map((item) {
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(MoewSpacing.md),
                decoration: BoxDecoration(
                  color: MoewColors.white,
                  borderRadius: BorderRadius.circular(MoewRadius.lg),
                  boxShadow: MoewShadows.card,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: MoewColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.receipt_long, size: 18, color: MoewColors.secondary),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['description']?.toString() ?? 'Chi phí', style: TextStyle(fontWeight: FontWeight.w600, color: MoewColors.textMain)),
                          SizedBox(height: 2),
                          Text('${item['type']} • ${_fmtDate(item['date']?.toString() ?? '')}', style: MoewTextStyles.caption),
                        ],
                      ),
                    ),
                    Text(
                      formatVND(toDouble(item['amount'])),
                      style: TextStyle(fontWeight: FontWeight.w700, color: MoewColors.danger),
                    ),
                  ],
                ),
              );
            })),
          ],
          SizedBox(height: MoewSpacing.lg),

          // ── Timestamp ──
          if (record['createdAt'] != null)
            Text('Tạo: ${_fmtDate(record['createdAt'].toString())}', style: MoewTextStyles.caption, textAlign: TextAlign.center),
          if (record['updatedAt'] != null)
            Text('Cập nhật: ${_fmtDate(record['updatedAt'].toString())}', style: MoewTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ── Helpers ──

  Widget _card(List<Widget> children) {
    final filtered = children.where((w) => w is! SizedBox).toList();
    if (filtered.isEmpty) return SizedBox.shrink();
    return Container(
      padding: EdgeInsets.all(MoewSpacing.md),
      decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.card),
      child: Column(children: children),
    );
  }

  Widget _row(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: color),
        ),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: MoewTextStyles.label),
          SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: MoewColors.textMain)),
        ])),
      ]),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }

  String _fmtDate(String iso) {
    if (iso.length < 10) return iso;
    return '${iso.substring(8, 10)}/${iso.substring(5, 7)}/${iso.substring(0, 4)}';
  }

  String _typeTitle(String type) {
    switch (type) {
      case 'vaccination': return 'Chi tiết tiêm chủng';
      case 'appointment': return 'Chi tiết lịch hẹn';
      default: return 'Chi tiết hồ sơ';
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'illness': return 'Bệnh';
      case 'allergy': return 'Dị ứng';
      case 'chronic': return 'Mãn tính';
      case 'injury': return 'Chấn thương';
      case 'surgery': return 'Phẫu thuật';
      case 'checkup': return 'Khám tổng quát';
      case 'vaccination': return 'Tiêm chủng';
      case 'appointment': return 'Lịch hẹn';
      default: return type;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'illness': return Icons.sick_outlined;
      case 'surgery': return Icons.content_cut;
      case 'checkup': return Icons.monitor_heart_outlined;
      case 'vaccination': return Icons.vaccines;
      default: return Icons.medical_services_outlined;
    }
  }
}
