import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../config/theme.dart';
import '../../api/ekyc_api.dart';
import '../../widgets/toast.dart';
import '../../widgets/common_widgets.dart';

class EkycScreen extends StatefulWidget {
  const EkycScreen({super.key});
  @override
  State<EkycScreen> createState() => _EkycScreenState();
}

class _EkycScreenState extends State<EkycScreen> {
  final _idNumberCtrl = TextEditingController();
  final _idNameCtrl = TextEditingController();
  String? _frontImage;
  String? _backImage;
  bool _loading = false;
  Map<String, dynamic>? _status;

  @override
  void initState() { super.initState(); _checkStatus(); }

  Future<void> _checkStatus() async {
    final res = await EkycApi.getStatus();
    if (mounted && res.success) {
      setState(() => _status = (res.data as Map?)?['data'] ?? res.data as Map<String, dynamic>?);
    }
  }

  Future<void> _pickImage(bool isFront) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.camera, maxWidth: 1200, imageQuality: 80);
    if (img == null) return;
    final bytes = await File(img.path).readAsBytes();
    final b64 = base64Encode(bytes);
    setState(() => isFront ? _frontImage = b64 : _backImage = b64);
  }

  Future<void> _submit() async {
    if (_idNumberCtrl.text.trim().isEmpty || _idNameCtrl.text.trim().isEmpty) {
      MoewToast.show(context, message: 'Nhập đầy đủ thông tin CCCD', type: ToastType.warning);
      return;
    }
    if (_frontImage == null || _backImage == null) {
      MoewToast.show(context, message: 'Chụp ảnh mặt trước và mặt sau CCCD', type: ToastType.warning);
      return;
    }
    setState(() => _loading = true);
    final res = await EkycApi.submit({
      'idCardNumber': _idNumberCtrl.text.trim(),
      'idCardName': _idNameCtrl.text.trim(),
      'idCardFront': _frontImage,
      'idCardBack': _backImage,
    });
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.success) {
      MoewToast.show(context, message: 'Đã gửi xác minh!', type: ToastType.success);
      _checkStatus();
    } else {
      MoewToast.show(context, message: res.error ?? 'Lỗi', type: ToastType.error);
    }
  }

  @override
  void dispose() { _idNumberCtrl.dispose(); _idNameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: const AppHeader(title: 'Xác minh danh tính'),
      body: ListView(padding: const EdgeInsets.all(MoewSpacing.lg), children: [
        if (_status != null) ...[
          StatusBadge(
            label: _status!['status'] ?? 'Pending',
            color: _status!['status'] == 'verified' ? MoewColors.success : MoewColors.warning,
            icon: _status!['status'] == 'verified' ? Icons.check_circle : Icons.hourglass_bottom,
          ),
          const SizedBox(height: MoewSpacing.lg),
        ],
        Text('SỐ CCCD', style: MoewTextStyles.label),
        const SizedBox(height: MoewSpacing.sm),
        TextField(controller: _idNumberCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Nhập số CCCD')),
        const SizedBox(height: MoewSpacing.md),
        Text('HỌ TÊN TRÊN CCCD', style: MoewTextStyles.label),
        const SizedBox(height: MoewSpacing.sm),
        TextField(controller: _idNameCtrl, decoration: const InputDecoration(hintText: 'Nhập họ tên')),
        const SizedBox(height: MoewSpacing.lg),
        Row(children: [
          Expanded(child: _imgPicker('Mặt trước', _frontImage != null, () => _pickImage(true))),
          const SizedBox(width: 12),
          Expanded(child: _imgPicker('Mặt sau', _backImage != null, () => _pickImage(false))),
        ]),
        const SizedBox(height: MoewSpacing.xl),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: MoewColors.success, padding: const EdgeInsets.symmetric(vertical: 16)),
          child: _loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Gửi xác minh', style: MoewTextStyles.button),
        ),
      ]),
    );
  }

  Widget _imgPicker(String label, bool taken, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: taken ? MoewColors.tintGreen : MoewColors.surface,
          borderRadius: BorderRadius.circular(MoewRadius.lg),
          border: Border.all(color: taken ? MoewColors.success : MoewColors.border, width: 1.5),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(taken ? Icons.check_circle : Icons.camera_alt_outlined, size: 32, color: taken ? MoewColors.success : MoewColors.textSub),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: taken ? MoewColors.success : MoewColors.textSub)),
        ]),
      ),
    );
  }
}
