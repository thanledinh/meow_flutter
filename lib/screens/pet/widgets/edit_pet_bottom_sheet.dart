import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../api/pet_api.dart';
import '../../../widgets/toast.dart';

class EditPetBottomSheet extends StatefulWidget {
  final dynamic petId;
  final Map<String, dynamic> petData;
  final VoidCallback onSaved;

  const EditPetBottomSheet({
    super.key,
    required this.petId,
    required this.petData,
    required this.onSaved,
  });

  @override
  State<EditPetBottomSheet> createState() => _EditPetBottomSheetState();
}

class _EditPetBottomSheetState extends State<EditPetBottomSheet> {
  late TextEditingController nameCtrl;
  late TextEditingController breedCtrl;
  late TextEditingController colorCtrl;
  late TextEditingController featuresCtrl;
  late TextEditingController notesCtrl;
  late TextEditingController birthDateCtrl;
  String? gender;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.petData['name'] ?? '');
    breedCtrl = TextEditingController(text: widget.petData['breed'] ?? '');
    colorCtrl = TextEditingController(text: widget.petData['color'] ?? '');
    featuresCtrl = TextEditingController(text: widget.petData['features'] ?? '');
    notesCtrl = TextEditingController(text: widget.petData['notes'] ?? '');
    
    final birthDate = widget.petData['birthDate'];
    String bDateStr = '';
    if (birthDate != null && birthDate.toString().isNotEmpty) {
      try {
         String bStr = birthDate.toString();
         if (RegExp(r'^\d{2}[-/]\d{2}[-/]\d{4}').hasMatch(bStr)) {
            bDateStr = bStr.replaceAll('-', '/');
         } else {
            final d = DateTime.parse(bStr);
            bDateStr = '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
         }
      } catch (_) {
         bDateStr = birthDate.toString().substring(0, 10);
      }
    }
    birthDateCtrl = TextEditingController(text: bDateStr);
    gender = widget.petData['gender'];
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    breedCtrl.dispose();
    colorCtrl.dispose();
    featuresCtrl.dispose();
    notesCtrl.dispose();
    birthDateCtrl.dispose();
    super.dispose();
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (nameCtrl.text.trim().isEmpty) {
      MoewToast.show(context, message: 'Tên không được để trống', type: ToastType.warning);
      return;
    }
    
    setState(() => saving = true);
    final data = <String, dynamic>{
      'name': nameCtrl.text.trim(),
      if (breedCtrl.text.trim().isNotEmpty) 'breed': breedCtrl.text.trim(),
      if (colorCtrl.text.trim().isNotEmpty) 'color': colorCtrl.text.trim(),
      if (featuresCtrl.text.trim().isNotEmpty) 'features': featuresCtrl.text.trim(),
      if (notesCtrl.text.trim().isNotEmpty) 'notes': notesCtrl.text.trim(),
      if (gender != null) 'gender': gender,
      if (birthDateCtrl.text.isNotEmpty) 'birthDate': () {
        final p = birthDateCtrl.text.split('/');
        if (p.length == 3) return '${p[2]}-${p[1]}-${p[0]}';
        return birthDateCtrl.text;
      }(),
    };
    
    final res = await PetApi.update(widget.petId, data);
    if (!mounted) return;
    setState(() => saving = false);
    
    if (res.success) {
      context.pop();
      MoewToast.show(context, message: 'Đã cập nhật!', type: ToastType.success);
      widget.onSaved();
    } else {
      MoewToast.show(context, message: res.error ?? 'Lỗi', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            const Expanded(child: Text('Sửa thông tin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            IconButton(onPressed: () => context.pop(), icon: Icon(Icons.close)),
          ]),
          SizedBox(height: 8),
          _field(nameCtrl, 'Tên *', Icons.pets),
          _field(breedCtrl, 'Giống', Icons.category),
          _field(colorCtrl, 'Màu lông', Icons.palette),
          _field(featuresCtrl, 'Đặc điểm', Icons.star_outline),
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              value: gender,
              decoration: const InputDecoration(
                labelText: 'Giới tính', prefixIcon: Icon(Icons.wc, size: 18),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'male', child: Text('Đực')),
                DropdownMenuItem(value: 'female', child: Text('Cái')),
              ],
              onChanged: (v) => setState(() => gender = v),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: birthDateCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Ngày sinh', prefixIcon: Icon(Icons.cake, size: 18),
                border: OutlineInputBorder(),
              ),
              onTap: () async {
                DateTime initDate = DateTime.now();
                if (birthDateCtrl.text.isNotEmpty) {
                  try {
                    final parts = birthDateCtrl.text.split('/');
                    if (parts.length == 3) {
                      initDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
                    } else {
                      initDate = DateTime.parse(birthDateCtrl.text); 
                    }
                  } catch (_) {}
                }
                final date = await showDatePicker(
                  context: context,
                  initialDate: initDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  birthDateCtrl.text = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                }
              },
            ),
          ),
          _field(notesCtrl, 'Ghi chú', Icons.note_outlined, maxLines: 3),
          SizedBox(height: 8),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: saving ? null : _handleSave,
            style: ElevatedButton.styleFrom(backgroundColor: MoewColors.primary, padding: EdgeInsets.symmetric(vertical: 14)),
            child: saving
                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Lưu thay đổi', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          )),
        ]),
      ),
    );
  }
}
