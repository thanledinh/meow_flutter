import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../config/theme.dart';
import '../../api/pet_api.dart';
import '../../widgets/toast.dart';
import '../../widgets/common_widgets.dart';

// Breed suggestions
const _breedSuggestions = [
  'Mèo ta', 'Mèo cam', 'Mèo mướp', 'Mèo tam thể', 'Mèo tuxedo',
  'Mèo Anh lông ngắn', 'Mèo Ba Tư', 'Mèo Munchkin', 'Mèo Scottish Fold',
];



class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key});
  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _nameCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _gender = 'male';
  final _breedCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  DateTime? _birthday;
  String? _avatarBase64;
  bool _loading = false;

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
    if (img == null) return;
    final bytes = await File(img.path).readAsBytes();
    setState(() => _avatarBase64 = base64Encode(bytes));
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365)),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: MoewColors.primary)), child: child!),
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      MoewToast.show(context, message: 'Nhập tên boss mèo', type: ToastType.warning);
      return;
    }
    setState(() => _loading = true);
    final data = {
      'name': _nameCtrl.text.trim(),
      'species': 'cat',
      'breed': _breedCtrl.text.trim(),
      'gender': _gender,
      'weight': double.tryParse(_weightCtrl.text) ?? 0,
      'color': _colorCtrl.text.trim(),
      if (_birthday != null) 'birthday': _birthday!.toIso8601String(),
      if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
    };
    final res = await PetApi.create(data);
    if (!mounted) return;
    if (res.success) {
      final petData = (res.data as Map?)?['data'] ?? res.data;
      if (_avatarBase64 != null && petData is Map && petData['id'] != null) {
        await PetApi.uploadAvatar(petData['id'], _avatarBase64!);
      }
      if (!mounted) return;
      MoewToast.show(context, message: 'Đã thêm boss mèo!', type: ToastType.success);
      Navigator.pop(context, true);
    } else {
      MoewToast.show(context, message: res.error ?? 'Lỗi', type: ToastType.error);
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _breedCtrl.dispose();
    _colorCtrl.dispose();
    _weightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: AppHeader(title: 'Thêm Boss Mèo'),
      body: ListView(padding: EdgeInsets.all(MoewSpacing.lg), children: [
        // ── Avatar picker ──
        _buildAvatarPicker(),
        SizedBox(height: MoewSpacing.lg),

        // ── Name ──
        _label('TÊN BOSS'),
        SizedBox(height: MoewSpacing.sm),
        TextField(
          controller: _nameCtrl,
          decoration: InputDecoration(hintText: 'Tên mèo cưng', prefixIcon: Icon(Icons.pets, size: 20, color: MoewColors.textSub)),
        ),
        SizedBox(height: MoewSpacing.md),

        // ── Breed (free text + suggestions) ──
        _label('GIỐNG MÈO'),
        SizedBox(height: MoewSpacing.sm),
        _buildBreedField(),
        SizedBox(height: MoewSpacing.md),

        // ── Gender ──
        _label('GIỚI TÍNH'),
        SizedBox(height: MoewSpacing.sm),
        Row(children: [
          _genderCard('Đực', 'male', Icons.male, MoewColors.primary),
          SizedBox(width: 8),
          _genderCard('Cái', 'female', Icons.female, MoewColors.secondary),
          SizedBox(width: 8),
          _genderCard('Triệt sản', 'neutered', Icons.content_cut, MoewColors.accent),
        ]),
        SizedBox(height: MoewSpacing.md),

        // ── Weight ──
        _label('CÂN NẶNG (KG)'),
        SizedBox(height: MoewSpacing.sm),
        TextField(
          controller: _weightCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: '0.0', prefixIcon: Icon(Icons.monitor_weight_outlined, size: 20, color: MoewColors.textSub), suffixText: 'kg'),
        ),
        SizedBox(height: MoewSpacing.md),

        // ── Fur color ──
        _label('MÀU LÔNG'),
        SizedBox(height: MoewSpacing.sm),
        TextField(
          controller: _colorCtrl,
          decoration: InputDecoration(hintText: 'VD: Cam, trắng, vằn...', prefixIcon: Icon(Icons.palette_outlined, size: 20, color: MoewColors.textSub)),
        ),
        SizedBox(height: MoewSpacing.md),

        // ── Birthday ──
        _label('NGÀY SINH'),
        SizedBox(height: MoewSpacing.sm),
        _buildDatePicker(),
        SizedBox(height: MoewSpacing.md),

        // ── Notes ──
        _label('GHI CHÚ'),
        SizedBox(height: MoewSpacing.sm),
        TextField(
          controller: _notesCtrl,
          maxLines: 3,
          decoration: InputDecoration(hintText: 'Đặc điểm, sở thích... (tùy chọn)', prefixIcon: Padding(padding: EdgeInsets.only(bottom: 40), child: Icon(Icons.notes, size: 20, color: MoewColors.textSub))),
        ),
        SizedBox(height: MoewSpacing.xl),

        // ── Submit ──
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(backgroundColor: MoewColors.secondary, padding: EdgeInsets.symmetric(vertical: 16)),
            child: _loading
                ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.pets, size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Thêm Boss Mèo', style: MoewTextStyles.button),
                  ]),
          ),
        ),
        SizedBox(height: MoewSpacing.lg),
      ]),
    );
  }

  // ─── AVATAR PICKER ───────────────────────────────────
  Widget _buildAvatarPicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickAvatar,
        child: Stack(children: [
          Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              color: MoewColors.tintAmber,
              borderRadius: BorderRadius.circular(55),
              border: Border.all(color: MoewColors.secondary.withValues(alpha: 0.3), width: 3),
              image: _avatarBase64 != null
                  ? DecorationImage(image: MemoryImage(base64Decode(_avatarBase64!)), fit: BoxFit.cover)
                  : null,
              boxShadow: MoewShadows.soft,
            ),
            child: _avatarBase64 == null
                ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.pets, size: 36, color: MoewColors.secondary),
                    SizedBox(height: 2),
                    Text('Ảnh', style: TextStyle(fontSize: 11, color: MoewColors.secondary, fontWeight: FontWeight.w600)),
                  ])
                : null,
          ),
          Positioned(
            right: 0, bottom: 0,
            child: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: MoewColors.primary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: MoewColors.white, width: 2),
              ),
              child: Icon(Icons.camera_alt, size: 14, color: Colors.white),
            ),
          ),
        ]),
      ),
    );
  }

  // ─── BREED FIELD (free text + suggestions) ──────────
  Widget _buildBreedField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: _breedCtrl,
        decoration: InputDecoration(
          hintText: 'Nhập giống mèo (VD: Mèo cam)',
          prefixIcon: Icon(Icons.category_outlined, size: 20, color: MoewColors.textSub),
        ),
        onChanged: (_) => setState(() {}),
      ),
      SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 6, children: _breedSuggestions
        .where((b) => _breedCtrl.text.isEmpty || b.toLowerCase().contains(_breedCtrl.text.toLowerCase()))
        .take(5)
        .map((b) {
          final active = _breedCtrl.text == b;
          return GestureDetector(
            onTap: () => setState(() { _breedCtrl.text = b; _breedCtrl.selection = TextSelection.fromPosition(TextPosition(offset: b.length)); }),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: active ? MoewColors.tintBlue : MoewColors.surface,
                borderRadius: BorderRadius.circular(MoewRadius.full),
                border: Border.all(color: active ? MoewColors.primary : MoewColors.border),
              ),
              child: Text(b, style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? MoewColors.primary : MoewColors.textSub)),
            ),
          );
        }).toList(),
      ),
    ]);
  }



  // ─── DATE PICKER ─────────────────────────────────────
  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: MoewColors.surface,
          borderRadius: BorderRadius.circular(MoewRadius.sm),
          border: Border.all(color: MoewColors.border),
        ),
        child: Row(children: [
          Icon(Icons.calendar_month, size: 20, color: MoewColors.textSub),
          SizedBox(width: 10),
          Text(
            _birthday != null
                ? '${_birthday!.day.toString().padLeft(2, '0')}/${_birthday!.month.toString().padLeft(2, '0')}/${_birthday!.year}'
                : 'Chọn ngày sinh (tùy chọn)',
            style: TextStyle(fontSize: 15, color: _birthday != null ? MoewColors.textMain : MoewColors.textSub),
          ),
          const Spacer(),
          if (_birthday != null) GestureDetector(
            onTap: () => setState(() => _birthday = null),
            child: Icon(Icons.close, size: 18, color: MoewColors.textSub),
          ),
        ]),
      ),
    );
  }

  // ─── GENDER CARD ─────────────────────────────────────
  Widget _genderCard(String label, String value, IconData icon, Color activeColor) {
    final active = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: active ? activeColor.withValues(alpha: 0.1) : MoewColors.surface,
            borderRadius: BorderRadius.circular(MoewRadius.md),
            border: Border.all(color: active ? activeColor : MoewColors.border, width: active ? 2 : 1),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 24, color: active ? activeColor : MoewColors.textSub),
            SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? activeColor : MoewColors.textSub)),
          ]),
        ),
      ),
    );
  }

  // ─── LABEL ──────────────────────────────────────────
  Widget _label(String text) => Text(text, style: MoewTextStyles.label);
}
