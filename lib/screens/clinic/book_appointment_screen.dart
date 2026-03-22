import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../api/clinic_api.dart';
import '../../api/pet_api.dart';
import '../../widgets/toast.dart';
import '../../widgets/common_widgets.dart';

const _serviceTypes = [
  {'key': 'checkup', 'label': 'Khám tổng quát', 'icon': Icons.medical_services},
  {'key': 'vaccination', 'label': 'Tiêm phòng', 'icon': Icons.vaccines},
  {'key': 'grooming', 'label': 'Spa & Grooming', 'icon': Icons.spa},
  {'key': 'dental', 'label': 'Nha khoa', 'icon': Icons.health_and_safety},
  {'key': 'surgery', 'label': 'Phẫu thuật', 'icon': Icons.local_hospital},
  {'key': 'emergency', 'label': 'Cấp cứu', 'icon': Icons.emergency},
  {'key': 'other', 'label': 'Khác', 'icon': Icons.more_horiz},
];

const _timeSlots = [
  '08:00', '08:30', '09:00', '09:30', '10:00', '10:30',
  '11:00', '11:30', '13:00', '13:30', '14:00', '14:30',
  '15:00', '15:30', '16:00', '16:30', '17:00',
];

class BookAppointmentScreen extends StatefulWidget {
  final dynamic clinicId;
  final String? clinicName;
  const BookAppointmentScreen({super.key, required this.clinicId, this.clinicName});
  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _notesCtrl = TextEditingController();
  final _notesFocus = FocusNode();
  List<dynamic> _pets = [];
  dynamic _selectedPetId;
  String? _selectedService;
  DateTime? _selectedDate;
  String? _selectedTime;
  bool _loading = false;
  bool _loadingPets = true;

  @override
  void initState() {
    super.initState();
    _fetchPets();
  }

  Future<void> _fetchPets() async {
    final res = await PetApi.getAll();
    if (!mounted) return;
    final raw = res.data;
    final data = (raw is Map) ? raw['data'] : raw;
    setState(() {
      _pets = data is List ? data : [];
      if (_pets.isNotEmpty) _selectedPetId = _pets.first['id'];
      _loadingPets = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (_selectedPetId == null) {
      MoewToast.show(context, message: 'Chọn thú cưng', type: ToastType.warning);
      return;
    }
    if (_selectedService == null) {
      MoewToast.show(context, message: 'Chọn dịch vụ', type: ToastType.warning);
      return;
    }
    if (_selectedService == 'other' && _notesCtrl.text.trim().isEmpty) {
      MoewToast.show(context, message: 'Mô tả dịch vụ bạn cần', type: ToastType.warning);
      _notesFocus.requestFocus();
      return;
    }
    if (_selectedDate == null) {
      MoewToast.show(context, message: 'Chọn ngày khám', type: ToastType.warning);
      return;
    }

    setState(() => _loading = true);
    final data = {
      'petId': _selectedPetId,
      'serviceType': _selectedService,
      'date': _selectedDate!.toIso8601String().substring(0, 10),
      if (_selectedTime != null) 'timeSlot': _selectedTime,
      if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
    };

    final res = await ClinicApi.book(widget.clinicId, data);
    if (!mounted) return;
    setState(() => _loading = false);

    if (res.success) {
      MoewToast.show(context, message: 'Đặt lịch thành công!', type: ToastType.success);
      Navigator.pop(context, true);
    } else {
      MoewToast.show(context, message: res.error ?? 'Lỗi đặt lịch', type: ToastType.error);
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: AppHeader(title: 'Đặt lịch ${widget.clinicName ?? ''}'),
      body: _loadingPets
          ? const Center(child: CircularProgressIndicator(color: MoewColors.primary))
          : ListView(padding: const EdgeInsets.all(MoewSpacing.lg), children: [
              // ── Pet selector ──
              _buildSection('CHỌN THÚ CƯNG', Icons.pets),
              const SizedBox(height: MoewSpacing.sm),
              if (_pets.isEmpty)
                Text('Chưa có thú cưng nào', style: MoewTextStyles.caption)
              else
                SizedBox(
                  height: 80,
                  child: ListView(scrollDirection: Axis.horizontal, children: _pets.map<Widget>((p) {
                    final active = _selectedPetId == p['id'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedPetId = p['id']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 80,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: active ? MoewColors.primary.withValues(alpha: 0.1) : MoewColors.white,
                          borderRadius: BorderRadius.circular(MoewRadius.md),
                          border: Border.all(color: active ? MoewColors.primary : MoewColors.border, width: active ? 2 : 1),
                        ),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.pets, size: 24, color: active ? MoewColors.primary : MoewColors.textSub),
                          const SizedBox(height: 4),
                          Text(p['name'] ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: active ? MoewColors.primary : MoewColors.textSub), overflow: TextOverflow.ellipsis),
                        ]),
                      ),
                    );
                  }).toList()),
                ),
              const SizedBox(height: MoewSpacing.lg),

              // ── Service type ──
              _buildSection('DỊCH VỤ', Icons.medical_services_outlined),
              const SizedBox(height: MoewSpacing.sm),
              Wrap(spacing: 8, runSpacing: 8, children: _serviceTypes.map((s) {
                final active = _selectedService == s['key'];
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedService = s['key'] as String);
                    if (s['key'] == 'other') Future.delayed(const Duration(milliseconds: 200), () => _notesFocus.requestFocus());
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? MoewColors.success.withValues(alpha: 0.1) : MoewColors.white,
                      borderRadius: BorderRadius.circular(MoewRadius.full),
                      border: Border.all(color: active ? MoewColors.success : MoewColors.border, width: active ? 2 : 1),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(s['icon'] as IconData, size: 16, color: active ? MoewColors.success : MoewColors.textSub),
                      const SizedBox(width: 6),
                      Text(s['label'] as String, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? MoewColors.success : MoewColors.textSub)),
                    ]),
                  ),
                );
              }).toList()),
              const SizedBox(height: MoewSpacing.lg),

              // ── Date ──
              _buildSection('NGÀY KHÁM', Icons.calendar_month),
              const SizedBox(height: MoewSpacing.sm),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.sm), border: Border.all(color: MoewColors.border)),
                  child: Row(children: [
                    Icon(Icons.calendar_month, size: 20, color: _selectedDate != null ? MoewColors.primary : MoewColors.textSub),
                    const SizedBox(width: 10),
                    Text(
                      _selectedDate != null
                          ? '${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}'
                          : 'Chọn ngày khám',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _selectedDate != null ? MoewColors.textMain : MoewColors.textSub),
                    ),
                    const Spacer(),
                    const Icon(Icons.expand_more, color: MoewColors.textSub),
                  ]),
                ),
              ),
              const SizedBox(height: MoewSpacing.lg),

              // ── Time slot ──
              _buildSection('GIỜ KHÁM (tùy chọn)', Icons.access_time),
              const SizedBox(height: MoewSpacing.sm),
              Wrap(spacing: 8, runSpacing: 8, children: _timeSlots.map((t) {
                final active = _selectedTime == t;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTime = active ? null : t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? MoewColors.accent.withValues(alpha: 0.1) : MoewColors.white,
                      borderRadius: BorderRadius.circular(MoewRadius.sm),
                      border: Border.all(color: active ? MoewColors.accent : MoewColors.border, width: active ? 2 : 1),
                    ),
                    child: Text(t, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? MoewColors.accent : MoewColors.textSub)),
                  ),
                );
              }).toList()),
              const SizedBox(height: MoewSpacing.lg),

              // ── Notes (visible when 'Khác' selected) ──
              if (_selectedService == 'other') ...[
                _buildSection('MÔ TẢ DỊCH VỤ (bắt buộc)', Icons.edit_note),
                const SizedBox(height: MoewSpacing.sm),
                TextField(
                  controller: _notesCtrl,
                  focusNode: _notesFocus,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Mô tả dịch vụ bạn cần...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(MoewRadius.sm), borderSide: const BorderSide(color: MoewColors.success, width: 2)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(MoewRadius.sm), borderSide: const BorderSide(color: MoewColors.success, width: 2)),
                  ),
                ),
              ],
              const SizedBox(height: MoewSpacing.xl),

              // ── Submit ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: MoewColors.success, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Icon(Icons.check_circle, size: 20, color: Colors.white),
                          const SizedBox(width: 8),
                          Text('Xác nhận đặt lịch', style: MoewTextStyles.button),
                        ]),
                ),
              ),
              const SizedBox(height: MoewSpacing.lg),
            ]),
    );
  }

  Widget _buildSection(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 16, color: MoewColors.textSub),
      const SizedBox(width: 6),
      Text(title, style: MoewTextStyles.label),
    ]);
  }
}
