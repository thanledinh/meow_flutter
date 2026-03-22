import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../api/api_client.dart';
import '../../api/medical_api.dart';
import '../../widgets/toast.dart';
import '../../widgets/common_widgets.dart';

class AddMedicalScreen extends StatefulWidget {
  final dynamic petId;
  final String type; // 'medical', 'vaccination', 'appointment'
  const AddMedicalScreen({super.key, required this.petId, required this.type});
  @override
  State<AddMedicalScreen> createState() => _AddMedicalScreenState();
}

class _AddMedicalScreenState extends State<AddMedicalScreen> {
  final _titleCtrl = TextEditingController();
  final _diagnosisCtrl = TextEditingController();
  final _treatmentCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _vetCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  bool _loading = false;

  String get _screenTitle {
    switch (widget.type) {
      case 'vaccination': return 'Thêm tiêm chủng';
      case 'appointment': return 'Thêm lịch hẹn';
      default: return 'Thêm hồ sơ y tế';
    }
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      MoewToast.show(context, message: 'Nhập tiêu đề', type: ToastType.warning);
      return;
    }
    setState(() => _loading = true);
    final data = {
      'title': _titleCtrl.text.trim(),
      'date': _date.toIso8601String(),
      if (_diagnosisCtrl.text.isNotEmpty) 'diagnosis': _diagnosisCtrl.text.trim(),
      if (_treatmentCtrl.text.isNotEmpty) 'treatment': _treatmentCtrl.text.trim(),
      if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
      if (_vetCtrl.text.isNotEmpty) 'veterinarian': _vetCtrl.text.trim(),
      if (widget.type == 'vaccination') 'vaccineName': _titleCtrl.text.trim(),
      if (widget.type == 'appointment') 'reason': _titleCtrl.text.trim(),
    };

    late final ApiResponse res;
    switch (widget.type) {
      case 'vaccination': res = await VaccinationApi.create(widget.petId, data); break;
      case 'appointment': res = await AppointmentApi.create(widget.petId, data); break;
      default: res = await MedicalApi.create(widget.petId, data);
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.success) {
      MoewToast.show(context, message: 'Đã thêm thành công!', type: ToastType.success);
      Navigator.pop(context, true);
    } else {
      MoewToast.show(context, message: res.error ?? 'Lỗi', type: ToastType.error);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (picked != null) setState(() => _date = picked);
  }

  @override
  void dispose() { _titleCtrl.dispose(); _diagnosisCtrl.dispose(); _treatmentCtrl.dispose(); _notesCtrl.dispose(); _vetCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: AppHeader(title: _screenTitle),
      body: ListView(padding: const EdgeInsets.all(MoewSpacing.lg), children: [
        _field('TIÊU ĐỀ', _titleCtrl, widget.type == 'vaccination' ? 'Tên vaccine' : widget.type == 'appointment' ? 'Lý do hẹn' : 'Tên bệnh / triệu chứng', Icons.medical_services_outlined),
        Text('NGÀY', style: MoewTextStyles.label),
        const SizedBox(height: MoewSpacing.sm),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: MoewColors.surface, borderRadius: BorderRadius.circular(MoewRadius.sm)),
            child: Row(children: [
              const Icon(Icons.calendar_month, size: 20, color: MoewColors.textSub),
              const SizedBox(width: 10),
              Text('${_date.day}/${_date.month}/${_date.year}', style: MoewTextStyles.body),
            ]),
          ),
        ),
        const SizedBox(height: MoewSpacing.md),
        if (widget.type == 'medical') ...[
          _field('CHẨN ĐOÁN', _diagnosisCtrl, 'Chẩn đoán của bác sĩ', Icons.search),
          _field('ĐIỀU TRỊ', _treatmentCtrl, 'Phương pháp điều trị', Icons.healing),
        ],
        _field('BÁC SĨ', _vetCtrl, 'Tên bác sĩ thú y', Icons.person_outline),
        _field('GHI CHÚ', _notesCtrl, 'Ghi chú thêm (tùy chọn)', Icons.note_outlined, maxLines: 3),
        const SizedBox(height: MoewSpacing.xl),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: MoewColors.primary, padding: const EdgeInsets.symmetric(vertical: 16)),
          child: _loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Lưu', style: MoewTextStyles.button),
        ),
      ]),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MoewSpacing.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: MoewTextStyles.label),
        const SizedBox(height: MoewSpacing.sm),
        TextField(controller: ctrl, maxLines: maxLines, decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, size: 20, color: MoewColors.textSub))),
      ]),
    );
  }
}
