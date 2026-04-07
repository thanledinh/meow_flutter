import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../api/pet_api.dart';
import '../../../widgets/toast.dart';

class AddWeightBottomSheet extends StatefulWidget {
  final dynamic petId;
  final VoidCallback onSaved;

  const AddWeightBottomSheet({
    super.key,
    required this.petId,
    required this.onSaved,
  });

  @override
  State<AddWeightBottomSheet> createState() => _AddWeightBottomSheetState();
}

class _AddWeightBottomSheetState extends State<AddWeightBottomSheet> {
  final TextEditingController ctrl = TextEditingController();
  bool saving = false;

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (ctrl.text.trim().isEmpty) {
      MoewToast.show(context, message: 'Nhập cân nặng', type: ToastType.warning);
      return;
    }
    final weight = double.tryParse(ctrl.text.trim());
    if (weight == null || weight <= 0) {
      MoewToast.show(context, message: 'Cân nặng không hợp lệ', type: ToastType.warning);
      return;
    }

    setState(() => saving = true);
    final res = await PetApi.addWeight(widget.petId, {'weight': weight});
    if (!mounted) return;
    setState(() => saving = false);
    
    if (res.success) {
      Navigator.pop(context);
      MoewToast.show(context, message: 'Đã ghi nhận!', type: ToastType.success);
      widget.onSaved();
    } else {
      MoewToast.show(context, message: res.error ?? 'Lỗi', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Cân mới', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        SizedBox(height: 14),
        TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Cân nặng (kg)', prefixIcon: Icon(Icons.monitor_weight, size: 18), suffixText: 'kg'),
        ),
        SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: saving ? null : _handleSave,
          style: ElevatedButton.styleFrom(backgroundColor: MoewColors.accent, padding: EdgeInsets.symmetric(vertical: 14)),
          child: saving
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Lưu', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        )),
      ]),
    );
  }
}
