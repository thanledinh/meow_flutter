import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../api/pet_api.dart';
import '../../widgets/toast.dart';
import '../../widgets/common_widgets.dart';

class PetVaccineScreen extends StatefulWidget {
  final dynamic petId;
  const PetVaccineScreen({super.key, required this.petId});
  @override
  State<PetVaccineScreen> createState() => _PetVaccineScreenState();
}

class _PetVaccineScreenState extends State<PetVaccineScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    final res = await PetApi.getVaccines(widget.petId);
    if (!mounted) return;
    final raw = res.data;
    setState(() {
      _data = (raw is Map) ? (raw['data'] is Map ? raw['data'] as Map<String, dynamic> : raw as Map<String, dynamic>) : null;
      _loading = false;
    });
  }

  Future<void> _showAddVaccine() async {
    final nameCtrl = TextEditingController();
    final doseCtrl = TextEditingController(text: '1');
    final vetCtrl = TextEditingController();
    final clinicCtrl = TextEditingController();
    final batchCtrl = TextEditingController();
    final costCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime date = DateTime.now();
    DateTime? nextDate;
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setBS) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ghi nhận tiêm chủng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          SizedBox(height: 14),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên vaccine *', prefixIcon: Icon(Icons.vaccines, size: 18))),
          SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: doseCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Mũi số', prefixIcon: Icon(Icons.pin, size: 18)))),
            SizedBox(width: 10),
            Expanded(child: GestureDetector(
              onTap: () async {
                final d = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2030));
                if (d != null) setBS(() => date = d);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Ngày tiêm', prefixIcon: Icon(Icons.calendar_today, size: 18)),
                child: Text('${date.day}/${date.month}/${date.year}', style: TextStyle(fontSize: 14)),
              ),
            )),
          ]),
          SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(context: ctx, initialDate: DateTime.now().add(const Duration(days: 90)), firstDate: DateTime.now(), lastDate: DateTime(2030));
              if (d != null) setBS(() => nextDate = d);
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Ngày tiêm kế tiếp (tùy chọn)', prefixIcon: Icon(Icons.event, size: 18)),
              child: Text(nextDate != null ? '${nextDate!.day}/${nextDate!.month}/${nextDate!.year}' : 'Chọn ngày', style: TextStyle(fontSize: 14, color: nextDate != null ? MoewColors.textMain : MoewColors.textSub)),
            ),
          ),
          SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: vetCtrl, decoration: const InputDecoration(labelText: 'Bác sĩ', prefixIcon: Icon(Icons.person, size: 18)))),
            SizedBox(width: 10),
            Expanded(child: TextField(controller: clinicCtrl, decoration: const InputDecoration(labelText: 'Phòng khám', prefixIcon: Icon(Icons.local_hospital, size: 18)))),
          ]),
          SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: batchCtrl, decoration: const InputDecoration(labelText: 'Số lô', prefixIcon: Icon(Icons.qr_code, size: 18)))),
            SizedBox(width: 10),
            Expanded(child: TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Chi phí (đ)', prefixIcon: Icon(Icons.paid, size: 18)))),
          ]),
          SizedBox(height: 10),
          TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Ghi chú', prefixIcon: Icon(Icons.edit_note, size: 18))),
          SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: saving ? null : () async {
              if (nameCtrl.text.trim().isEmpty) { MoewToast.show(ctx, message: 'Nhập tên vaccine', type: ToastType.warning); return; }
              setBS(() => saving = true);
              final body = <String, dynamic>{
                'vaccineName': nameCtrl.text.trim(),
                'dose': int.tryParse(doseCtrl.text.trim()) ?? 1,
                'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
              };
              if (nextDate != null) body['nextDoseDate'] = '${nextDate!.year}-${nextDate!.month.toString().padLeft(2, '0')}-${nextDate!.day.toString().padLeft(2, '0')}';
              if (vetCtrl.text.trim().isNotEmpty) body['veterinarian'] = vetCtrl.text.trim();
              if (clinicCtrl.text.trim().isNotEmpty) body['clinic'] = clinicCtrl.text.trim();
              if (batchCtrl.text.trim().isNotEmpty) body['batchNumber'] = batchCtrl.text.trim();
              if (costCtrl.text.trim().isNotEmpty) body['cost'] = int.tryParse(costCtrl.text.trim());
              if (noteCtrl.text.trim().isNotEmpty) body['notes'] = noteCtrl.text.trim();

              final res = await PetApi.addVaccine(widget.petId, body);
              if (!mounted || !ctx.mounted) return;
              setBS(() => saving = false);
              if (res.success) { Navigator.pop(ctx); MoewToast.show(context, message: 'Đã ghi nhận!', type: ToastType.success); _fetch(); }
              else { MoewToast.show(ctx, message: res.error ?? 'Lỗi', type: ToastType.error); }
            },
            style: ElevatedButton.styleFrom(backgroundColor: MoewColors.success, padding: EdgeInsets.symmetric(vertical: 14)),
            child: saving ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Lưu', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          )),
        ]),
      )),
    ));
  }

  Future<void> _showEditVaccine(Map<String, dynamic> rec) async {
    final vetCtrl = TextEditingController(text: rec['veterinarian']?.toString() ?? '');
    final clinicCtrl = TextEditingController(text: rec['clinic']?.toString() ?? '');
    final batchCtrl = TextEditingController(text: rec['batchNumber']?.toString() ?? '');
    final costCtrl = TextEditingController(text: rec['cost'] != null ? rec['cost'].toString() : '');
    final noteCtrl = TextEditingController(text: rec['notes']?.toString() ?? '');
    DateTime? nextDate;
    final nextRaw = rec['nextDoseDate']?.toString();
    if (nextRaw != null && nextRaw.length >= 10) nextDate = DateTime.tryParse(nextRaw);
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setBS) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(child: Text('Chỉnh sửa vaccine', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            GestureDetector(onTap: () => Navigator.pop(ctx), child: Icon(Icons.close, size: 20, color: MoewColors.textSub)),
          ]),
          SizedBox(height: 4),
          Text('${rec['vaccineName'] ?? ''} — Mũi ${rec['dose'] ?? ''}', style: TextStyle(fontSize: 12, color: MoewColors.textSub)),
          SizedBox(height: 14),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(context: ctx, initialDate: nextDate ?? DateTime.now().add(const Duration(days: 90)), firstDate: DateTime.now(), lastDate: DateTime(2030));
              if (d != null) setBS(() => nextDate = d);
            },
            child: InputDecorator(
              decoration: const InputDecoration(labelText: 'Ngày tiêm kế tiếp', prefixIcon: Icon(Icons.event, size: 18)),
              child: Text(nextDate != null ? '${nextDate!.day}/${nextDate!.month}/${nextDate!.year}' : 'Chọn ngày', style: TextStyle(fontSize: 14, color: nextDate != null ? MoewColors.textMain : MoewColors.textSub)),
            ),
          ),
          SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: vetCtrl, decoration: const InputDecoration(labelText: 'Bác sĩ', prefixIcon: Icon(Icons.person, size: 18)))),
            SizedBox(width: 10),
            Expanded(child: TextField(controller: clinicCtrl, decoration: const InputDecoration(labelText: 'Phòng khám', prefixIcon: Icon(Icons.local_hospital, size: 18)))),
          ]),
          SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: batchCtrl, decoration: const InputDecoration(labelText: 'Số lô', prefixIcon: Icon(Icons.qr_code, size: 18)))),
            SizedBox(width: 10),
            Expanded(child: TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Chi phí (đ)', prefixIcon: Icon(Icons.paid, size: 18)))),
          ]),
          SizedBox(height: 10),
          TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Ghi chú', prefixIcon: Icon(Icons.edit_note, size: 18))),
          SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: saving ? null : () async {
              setBS(() => saving = true);
              final body = <String, dynamic>{};
              if (nextDate != null) body['nextDoseDate'] = '${nextDate!.year}-${nextDate!.month.toString().padLeft(2, '0')}-${nextDate!.day.toString().padLeft(2, '0')}';
              if (vetCtrl.text.trim().isNotEmpty) body['veterinarian'] = vetCtrl.text.trim();
              if (clinicCtrl.text.trim().isNotEmpty) body['clinic'] = clinicCtrl.text.trim();
              if (batchCtrl.text.trim().isNotEmpty) body['batchNumber'] = batchCtrl.text.trim();
              if (costCtrl.text.trim().isNotEmpty) body['cost'] = int.tryParse(costCtrl.text.trim());
              if (noteCtrl.text.trim().isNotEmpty) body['notes'] = noteCtrl.text.trim();

              final res = await PetApi.updateVaccine(widget.petId, rec['id'], body);
              if (!mounted || !ctx.mounted) return;
              setBS(() => saving = false);
              if (res.success) { Navigator.pop(ctx); MoewToast.show(context, message: 'Đã cập nhật!', type: ToastType.success); _fetch(); }
              else { MoewToast.show(ctx, message: res.error ?? 'Lỗi', type: ToastType.error); }
            },
            style: ElevatedButton.styleFrom(backgroundColor: MoewColors.primary, padding: EdgeInsets.symmetric(vertical: 14)),
            child: saving ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          )),
        ])),
      )),
    );
  }

  Future<void> _deleteVaccine(dynamic id) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text('Xóa?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      content: Text('Xóa bản ghi tiêm chủng này?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Hủy')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Xóa', style: TextStyle(color: MoewColors.danger))),
      ],
    ));
    if (ok != true) return;
    final res = await PetApi.deleteVaccine(widget.petId, id);
    if (!mounted) return;
    if (res.success) { MoewToast.show(context, message: 'Đã xóa', type: ToastType.success); _fetch(); }
    else { MoewToast.show(context, message: res.error ?? 'Lỗi', type: ToastType.error); }
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: AppHeader(title: 'Lịch tiêm chủng'),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVaccine,
        backgroundColor: MoewColors.success,
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: MoewColors.primary))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    final vaccines = _data?['vaccines'] as List? ?? [];
    final total = _data?['total'] ?? 0;

    if (vaccines.isEmpty) return ListView(children: [SizedBox(height: 100), EmptyState(icon: Icons.vaccines, color: MoewColors.success, message: 'Chưa có bản ghi tiêm chủng\nBấm + để thêm')]);

    return ListView(padding: EdgeInsets.all(MoewSpacing.md), children: [
      // Header summary
      Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(color: MoewColors.success.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(MoewRadius.lg)),
        child: Row(children: [
          Icon(Icons.vaccines, size: 22, color: MoewColors.success),
          SizedBox(width: 10),
          Text('$total mũi tiêm', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MoewColors.success)),
          Spacer(),
          Text('${vaccines.length} loại', style: TextStyle(fontSize: 12, color: MoewColors.textSub)),
        ]),
      ),
      SizedBox(height: 14),

      // Vaccine groups
      ...vaccines.map<Widget>((vg) => _buildVaccineGroup(vg as Map<String, dynamic>)),
    ]);
  }

  Widget _buildVaccineGroup(Map<String, dynamic> group) {
    final name = group['vaccineName']?.toString() ?? '';
    final totalDoses = group['totalDoses'] ?? 0;
    final nextDate = group['nextDoseDate']?.toString();
    final records = group['records'] as List? ?? [];

    // Next dose status
    String? statusLabel;
    Color statusColor = MoewColors.textSub;
    if (nextDate != null && nextDate.length >= 10) {
      final next = DateTime.tryParse(nextDate);
      if (next != null) {
        final daysLeft = next.difference(DateTime.now()).inDays;
        if (daysLeft < 0) { statusLabel = 'Quá hạn ${-daysLeft} ngày'; statusColor = MoewColors.danger; }
        else if (daysLeft <= 7) { statusLabel = 'Còn $daysLeft ngày'; statusColor = MoewColors.warning; }
        else { statusLabel = '$daysLeft ngày nữa'; statusColor = MoewColors.success; }
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.soft),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Group header
        Padding(
          padding: EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: MoewColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(MoewRadius.sm)),
              child: Icon(Icons.vaccines, size: 18, color: MoewColors.success),
            ),
            SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              Text('$totalDoses mũi', style: TextStyle(fontSize: 11, color: MoewColors.textSub)),
            ])),
            if (statusLabel != null) Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(MoewRadius.full)),
              child: Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
            ),
          ]),
        ),
        const Divider(height: 1),
        // Records
        ...records.map<Widget>((r) {
          final rec = r as Map<String, dynamic>;
          final date = rec['date']?.toString().substring(0, 10) ?? '';
          final cost = rec['cost'];
          String? costStr;
          if (cost != null) {
            final num = int.tryParse(cost.toString()) ?? 0;
            costStr = '${num.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';
          }
          return _SwipeableRecord(
            key: ValueKey(rec['id']),
            onEdit: () => _showEditVaccine(rec),
            onDelete: () => _deleteVaccine(rec['id']),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MoewColors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                // Dose badge
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [MoewColors.primary.withValues(alpha: 0.15), MoewColors.primary.withValues(alpha: 0.05)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text('${rec['dose'] ?? ''}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: MoewColors.primary))),
                ),
                SizedBox(width: 10),
                // Info
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(date, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    if (costStr != null) ...[
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: MoewColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(MoewRadius.full)),
                        child: Text(costStr, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: MoewColors.primary)),
                      ),
                    ],
                  ]),
                  if (rec['clinic'] != null || rec['veterinarian'] != null) Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Text(
                      [if (rec['clinic'] != null) rec['clinic'].toString(), if (rec['veterinarian'] != null) rec['veterinarian'].toString()].join(' ・ '),
                      style: TextStyle(fontSize: 11, color: MoewColors.textSub), maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (rec['notes'] != null && rec['notes'].toString().isNotEmpty) Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(rec['notes'].toString(), style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: MoewColors.textSub), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ])),
              ]),
            ),
          );
        }),
        SizedBox(height: 4),
      ]),
    );
  }
}

/// Swipe-left-to-reveal edit/delete actions — kiểu iOS
class _SwipeableRecord extends StatefulWidget {
  final Widget child;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _SwipeableRecord({super.key, required this.child, required this.onEdit, required this.onDelete});
  @override
  State<_SwipeableRecord> createState() => _SwipeableRecordState();
}

class _SwipeableRecordState extends State<_SwipeableRecord> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _dragExtent = 0;
  static const _maxSlide = 140.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _animation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  void _onDragUpdate(DragUpdateDetails d) {
    _dragExtent += d.primaryDelta!;
    _dragExtent = _dragExtent.clamp(-_maxSlide, 0);
    _controller.value = (-_dragExtent / _maxSlide).clamp(0, 1);
  }

  void _onDragEnd(DragEndDetails d) {
    if (_controller.value > 0.4 || d.primaryVelocity! < -300) {
      _controller.forward();
      _dragExtent = -_maxSlide;
    } else {
      _close();
    }
  }

  void _close() {
    _controller.reverse();
    _dragExtent = 0;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (ctx, _) {
        final slide = -_animation.value * _maxSlide;
        return Stack(
          children: [
            // Action buttons behind
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Edit button
                    GestureDetector(
                      onTap: () { _close(); widget.onEdit(); },
                      child: Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Color(0xFF7C83FD), width: 1.5),
                        ),
                        child: Center(child: Icon(Icons.edit_outlined, size: 20, color: Color(0xFF7C83FD))),
                      ),
                    ),
                    SizedBox(width: 8),
                    // Delete button
                    GestureDetector(
                      onTap: () { _close(); widget.onDelete(); },
                      child: Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Color(0xFFFF6B6B), width: 1.5),
                        ),
                        child: Center(child: Icon(Icons.delete_outline, size: 20, color: Color(0xFFFF6B6B))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Foreground card
            Transform.translate(
              offset: Offset(slide, 0),
              child: GestureDetector(
                onHorizontalDragUpdate: _onDragUpdate,
                onHorizontalDragEnd: _onDragEnd,
                onTap: _controller.value > 0.1 ? _close : null,
                child: widget.child,
              ),
            ),
          ],
        );
      },
    );
  }
}
