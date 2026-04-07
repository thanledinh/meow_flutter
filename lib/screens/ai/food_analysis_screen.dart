import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../config/theme.dart';
import '../../api/ai_api.dart';
import '../../api/pet_api.dart';
import '../../utils/parse_utils.dart';
import '../../widgets/toast.dart';
import '../../widgets/common_widgets.dart';

class FoodAnalysisScreen extends StatefulWidget {
  final dynamic petId;
  final String? petName;
  const FoodAnalysisScreen({super.key, this.petId, this.petName});
  @override
  State<FoodAnalysisScreen> createState() => _FoodAnalysisScreenState();
}

class _FoodAnalysisScreenState extends State<FoodAnalysisScreen> {
  String? _imageBase64;
  Map<String, dynamic>? _result;
  bool _analyzing = false;
  String _mealTime = 'morning';
  List<dynamic> _pets = [];
  dynamic _selectedPetId;

  @override
  void initState() {
    super.initState();
    _selectedPetId = widget.petId;
    _fetchPets();
  }

  Future<void> _fetchPets() async {
    final res = await PetApi.getAll();
    if (!mounted) return;
    final pets = toList(res.data);
    setState(() {
      _pets = pets;
      if (_selectedPetId == null && _pets.isNotEmpty) {
        _selectedPetId = _pets[0]['id'];
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: source, maxWidth: 1200, imageQuality: 80);
    if (img == null) return;
    final bytes = await File(img.path).readAsBytes();
    setState(() { _imageBase64 = base64Encode(bytes); _result = null; });
  }

  Future<void> _analyze() async {
    if (_imageBase64 == null) {
      MoewToast.show(context, message: 'Chụp hoặc chọn ảnh thức ăn trước', type: ToastType.warning);
      return;
    }
    if (_selectedPetId == null) {
      MoewToast.show(context, message: 'Chọn thú cưng trước', type: ToastType.warning);
      return;
    }
    setState(() => _analyzing = true);
    final res = await AiApi.analyzeFood({
      'image': _imageBase64,
      'petId': _selectedPetId,
      'mealTime': _mealTime,
    });
    if (!mounted) return;
    setState(() => _analyzing = false);
    if (res.success) {
      final raw = res.data;
      final data = raw is Map ? (raw['data'] is Map ? raw['data'] : raw) : null;
      setState(() => _result = data != null ? Map<String, dynamic>.from(data as Map) : null);
    } else {
      MoewToast.show(context, message: res.error ?? 'Lỗi phân tích', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedPet = _pets.firstWhere((p) => p['id'] == _selectedPetId, orElse: () => null);
    final title = selectedPet != null ? 'AI Thức ăn — ${selectedPet['name']}' : 'AI Phân tích thức ăn';
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: AppHeader(title: title, showBack: false),
      body: ListView(padding: EdgeInsets.fromLTRB(MoewSpacing.lg, MoewSpacing.lg, MoewSpacing.lg, 110), children: [
        // Pet selector
        Text('CHỌN THÚ CƯNG', style: MoewTextStyles.label),
        SizedBox(height: MoewSpacing.sm),
        if (_pets.isEmpty)
          Text('Đang tải danh sách thú cưng...', style: MoewTextStyles.caption)
        else
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.md), boxShadow: MoewShadows.card),
            child: DropdownButtonHideUnderline(child: DropdownButton<dynamic>(
              value: _selectedPetId,
              isExpanded: true,
              icon: Icon(Icons.expand_more, color: MoewColors.textSub),
              items: _pets.map((p) => DropdownMenuItem(
                value: p['id'],
                child: Row(children: [
                  Icon(Icons.pets, size: 18, color: MoewColors.secondary),
                  SizedBox(width: 10),
                  Text(p['name'] ?? 'Pet #${p['id']}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  if (p['breed'] != null) ...[SizedBox(width: 8), Text('(${p['breed']})', style: MoewTextStyles.caption)],
                ]),
              )).toList(),
              onChanged: (v) => setState(() => _selectedPetId = v),
            )),
          ),
        SizedBox(height: MoewSpacing.lg),

        // Image area
        GestureDetector(
          onTap: () => _showImagePicker(),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              color: MoewColors.surface,
              borderRadius: BorderRadius.circular(MoewRadius.xl),
              border: Border.all(color: MoewColors.border, width: 1.5),
              image: _imageBase64 != null ? DecorationImage(image: MemoryImage(base64Decode(_imageBase64!)), fit: BoxFit.cover) : null,
            ),
            child: _imageBase64 == null
                ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.camera_alt_outlined, size: 48, color: MoewColors.textSub),
                    SizedBox(height: 8),
                    Text('Chụp ảnh thức ăn', style: TextStyle(fontSize: 15, color: MoewColors.textSub)),
                  ])
                : null,
          ),
        ),
        SizedBox(height: MoewSpacing.md),

        // Meal time chips
        Text('BỮA ĂN', style: MoewTextStyles.label),
        SizedBox(height: MoewSpacing.sm),
        Wrap(spacing: 8, children: [
          _mealChip('Sáng', 'morning', Icons.wb_sunny_outlined),
          _mealChip('Trưa', 'afternoon', Icons.wb_cloudy_outlined),
          _mealChip('Tối', 'evening', Icons.nightlight_outlined),
          _mealChip('Snack', 'snack', Icons.local_cafe_outlined),
        ]),
        SizedBox(height: MoewSpacing.lg),

        // Analyze button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _analyzing ? null : _analyze,
            icon: _analyzing ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Icon(Icons.auto_awesome, color: Colors.white),
            label: Text(_analyzing ? 'Đang phân tích...' : 'Phân tích bằng AI', style: MoewTextStyles.button),
            style: ElevatedButton.styleFrom(backgroundColor: MoewColors.accent, padding: EdgeInsets.symmetric(vertical: 16)),
          ),
        ),
        SizedBox(height: MoewSpacing.lg),

        // Results
        if (_result != null) ...[
          Container(
            padding: EdgeInsets.all(MoewSpacing.md),
            decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.card),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: MoewColors.tintPurple, borderRadius: BorderRadius.circular(MoewRadius.sm)), child: Icon(Icons.auto_awesome, size: 20, color: MoewColors.accent)),
                SizedBox(width: 12),
                Text('Kết quả phân tích', style: MoewTextStyles.h3),
              ]),
              SizedBox(height: MoewSpacing.md),
              if (_result!['foodName'] != null) _resultRow('Tên thức ăn', _result!['foodName'].toString()),
              if (_result!['estimatedCalories'] != null) _resultRow('Calories', '${_result!['estimatedCalories']} kcal'),
              if (_result!['suitabilityScore'] != null) ...[
                Builder(builder: (_) {
                  final score = toDouble(_result!['suitabilityScore']);
                  return _resultRow(
                    'Điểm phù hợp', '${score.toStringAsFixed(0)}/10',
                    color: score >= 7 ? MoewColors.success : score >= 5 ? MoewColors.warning : MoewColors.danger,
                  );
                }),
              ],
              if (_result!['mealTime'] != null) _resultRow('Bữa ăn', _result!['mealTime']),
              // Good ingredients
              if (_result!['goodIngredients'] is List && (_result!['goodIngredients'] as List).isNotEmpty) ...[
                SizedBox(height: MoewSpacing.sm),
                Text('Thành phần tốt', style: MoewTextStyles.label),
                SizedBox(height: 4),
                Wrap(spacing: 6, runSpacing: 6, children: (_result!['goodIngredients'] as List).map<Widget>((g) => Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: MoewColors.tintGreen, borderRadius: BorderRadius.circular(MoewRadius.sm)),
                  child: Text(g.toString(), style: TextStyle(fontSize: 12, color: MoewColors.success, fontWeight: FontWeight.w600)),
                )).toList()),
              ],
              // Bad ingredients
              if (_result!['badIngredients'] is List && (_result!['badIngredients'] as List).isNotEmpty) ...[
                SizedBox(height: MoewSpacing.sm),
                Text('Thành phần xấu', style: MoewTextStyles.label),
                SizedBox(height: 4),
                Wrap(spacing: 6, runSpacing: 6, children: (_result!['badIngredients'] as List).map<Widget>((b) => Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: MoewColors.tintRed, borderRadius: BorderRadius.circular(MoewRadius.sm)),
                  child: Text(b.toString(), style: TextStyle(fontSize: 12, color: MoewColors.danger, fontWeight: FontWeight.w600)),
                )).toList()),
              ],
              // AI advice
              if (_result!['aiAdvice'] != null) ...[
                SizedBox(height: MoewSpacing.sm),
                Text('Lời khuyên AI', style: MoewTextStyles.label),
                SizedBox(height: 4),
                Text(_result!['aiAdvice'].toString(), style: MoewTextStyles.body),
              ],
            ]),
          ),
          SizedBox(height: MoewSpacing.md),
          // Chat about this result
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/ai-chat', arguments: {'petId': _selectedPetId, 'foodLogId': _result!['id']}),
            icon: Icon(Icons.chat_bubble_outline, color: MoewColors.accent),
            label: Text('Hỏi AI thêm', style: TextStyle(color: MoewColors.accent, fontWeight: FontWeight.w700)),
            style: OutlinedButton.styleFrom(side: BorderSide(color: MoewColors.accent), padding: EdgeInsets.symmetric(vertical: 14)),
          ),
        ],
      ]),
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: Icon(Icons.camera_alt, color: MoewColors.primary), title: Text('Chụp ảnh'), onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); }),
        ListTile(leading: Icon(Icons.photo_library, color: MoewColors.secondary), title: Text('Chọn từ thư viện'), onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); }),
      ])),
    );
  }

  Widget _mealChip(String label, String value, IconData icon) {
    final active = _mealTime == value;
    return GestureDetector(
      onTap: () => setState(() => _mealTime = value),
      child: Chip(
        avatar: Icon(icon, size: 16, color: active ? Colors.white : MoewColors.textSub),
        label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : MoewColors.textSub)),
        backgroundColor: active ? MoewColors.secondary : MoewColors.surface,
        side: BorderSide.none,
        padding: EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Widget _resultRow(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: MoewTextStyles.caption),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color ?? MoewColors.textMain)),
      ]),
    );
  }
}
