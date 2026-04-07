import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../api/feeding_api.dart';
import '../../api/pet_api.dart';
import '../../widgets/toast.dart';
import '../../widgets/common_widgets.dart';

class FoodTransitionScreen extends StatefulWidget {
  const FoodTransitionScreen({super.key});
  @override
  State<FoodTransitionScreen> createState() => _FoodTransitionScreenState();
}

class _FoodTransitionScreenState extends State<FoodTransitionScreen> {
  List<dynamic> _products = [];
  List<dynamic> _pets = [];
  bool _loadingInit = true;
  bool _generating = false;
  Map<String, dynamic>? _result;

  dynamic _oldProductId;
  dynamic _newProductId;
  Set<dynamic> _selectedPets = {};
  int _transitionDays = 7;

  @override
  void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    final prodRes = await FeedingApi.getProducts();
    final petRes = await PetApi.getAll();
    if (!mounted) return;
    setState(() {
      _products = ((prodRes.data is Map ? prodRes.data['data'] : prodRes.data) as List?) ?? [];
      _pets = ((petRes.data is Map ? petRes.data['data'] : petRes.data) as List?) ?? [];
      if (_products.length >= 2) { _oldProductId = _products[0]['id']; _newProductId = _products[1]['id']; }
      if (_pets.isNotEmpty) _selectedPets = {_pets.first['id']};
      _loadingInit = false;
    });
  }

  Future<void> _generate() async {
    if (_oldProductId == null || _newProductId == null) { MoewToast.show(context, message: 'Chọn 2 sản phẩm', type: ToastType.warning); return; }
    if (_oldProductId == _newProductId) { MoewToast.show(context, message: 'Chọn 2 sản phẩm khác nhau', type: ToastType.warning); return; }
    if (_selectedPets.isEmpty) { MoewToast.show(context, message: 'Chọn thú cưng', type: ToastType.warning); return; }

    setState(() => _generating = true);
    final res = await FeedingApi.createTransition({
      'oldProductId': _oldProductId,
      'newProductId': _newProductId,
      'petIds': _selectedPets.toList(),
      'transitionDays': _transitionDays,
    });
    if (!mounted) return;
    setState(() {
      _generating = false;
      if (res.success) {
        final raw = res.data;
        _result = (raw is Map<String, dynamic>) ? (raw['data'] is Map ? raw['data'] : raw) : null;
      } else {
        MoewToast.show(context, message: res.error ?? 'Lỗi', type: ToastType.error);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: AppHeader(title: 'Chuyển đổi thức ăn'),
      body: _loadingInit
          ? Center(child: CircularProgressIndicator(color: MoewColors.primary))
          : _products.length < 2
              ? EmptyState(icon: Icons.swap_horiz, color: MoewColors.primary, message: 'Cần ít nhất 2 sản phẩm\ntrong kho để chuyển đổi')
              : ListView(padding: EdgeInsets.all(MoewSpacing.md), children: [
                  if (_result == null) ..._buildForm() else ..._buildResult(),
                ]),
    );
  }

  List<Widget> _buildForm() {
    return [
      _sectionLabel('Thức ăn CŨ'),
      _productSelector(_oldProductId, (v) => setState(() => _oldProductId = v)),
      SizedBox(height: 12),
      Center(child: Icon(Icons.arrow_downward, color: MoewColors.primary, size: 28)),
      SizedBox(height: 4),
      _sectionLabel('Thức ăn MỚI'),
      _productSelector(_newProductId, (v) => setState(() => _newProductId = v)),
      SizedBox(height: 16),

      _sectionLabel('Chọn bé'),
      Wrap(spacing: 8, runSpacing: 8, children: _pets.map<Widget>((p) {
        final active = _selectedPets.contains(p['id']);
        return GestureDetector(
          onTap: () => setState(() { if (active) {
            _selectedPets.remove(p['id']);
          } else {
            _selectedPets.add(p['id']);
          } }),
          child: Chip(
            avatar: Icon(active ? Icons.check_circle : Icons.pets, size: 16, color: active ? MoewColors.success : MoewColors.textSub),
            label: Text(p['name'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, color: active ? MoewColors.success : MoewColors.textSub)),
            backgroundColor: active ? MoewColors.success.withValues(alpha: 0.1) : MoewColors.surface,
            side: BorderSide(color: active ? MoewColors.success : MoewColors.border),
          ),
        );
      }).toList()),
      SizedBox(height: 16),

      _sectionLabel('Số ngày chuyển đổi: $_transitionDays'),
      Slider(value: _transitionDays.toDouble(), min: 3, max: 14, divisions: 11, label: '$_transitionDays ngày',
        activeColor: MoewColors.primary,
        onChanged: (v) => setState(() => _transitionDays = v.round()),
      ),
      SizedBox(height: 16),

      SizedBox(width: double.infinity, child: ElevatedButton.icon(
        onPressed: _generating ? null : _generate,
        icon: _generating ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Icon(Icons.auto_awesome, size: 18, color: Colors.white),
        label: Text(_generating ? 'Đang tạo lịch...' : 'Tạo lịch chuyển đổi', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        style: ElevatedButton.styleFrom(backgroundColor: MoewColors.success, padding: EdgeInsets.symmetric(vertical: 14)),
      )),
    ];
  }

  List<Widget> _buildResult() {
    final petPlans = _result!['petPlans'] as List? ?? [];
    final warnings = _result!['warnings'] as List? ?? [];
    final oldName = _result!['oldProduct']?['name'] ?? '';
    final newName = _result!['newProduct']?['name'] ?? '';

    return [
      // Title
      Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(color: MoewColors.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(MoewRadius.lg)),
        child: Row(children: [
          Icon(Icons.swap_horiz, color: MoewColors.primary),
          SizedBox(width: 8),
          Expanded(child: Text('$oldName → $newName', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
        ]),
      ),
      SizedBox(height: 12),

      // Warnings
      ...warnings.map<Widget>((w) {
        final color = w['level'] == 'danger' ? MoewColors.danger : w['level'] == 'warning' ? MoewColors.warning : MoewColors.primary;
        return Container(
          margin: EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(MoewRadius.sm), border: Border.all(color: color.withValues(alpha: 0.3))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(w['level'] == 'danger' ? Icons.error : Icons.info, size: 16, color: color),
            SizedBox(width: 8),
            Expanded(child: Text(w['message']?.toString() ?? '', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600))),
          ]),
        );
      }),

      // Per-pet schedule
      ...petPlans.map<Widget>((pp) {
        final schedule = pp['schedule'] as List? ?? [];
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(height: 8),
          Text('${pp['petName']} (${pp['dailyCalories']} kcal/ngày)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          ...schedule.map<Widget>((day) => Container(
            margin: EdgeInsets.only(bottom: 4),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: day['newPercent'] == 100 ? MoewColors.success.withValues(alpha: 0.08) : MoewColors.white,
              borderRadius: BorderRadius.circular(MoewRadius.sm),
              border: Border.all(color: MoewColors.border),
            ),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: MoewColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(MoewRadius.sm)),
                child: Center(child: Text('${day['day']}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: MoewColors.primary))),
              ),
              SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(day['label']?.toString() ?? '', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 2),
                Row(children: [
                  Expanded(child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(value: (day['newPercent'] ?? 0) / 100.0, minHeight: 6, backgroundColor: MoewColors.warning.withValues(alpha: 0.3), valueColor: AlwaysStoppedAnimation(MoewColors.success)),
                  )),
                  SizedBox(width: 8),
                  Text('${day['newPercent']}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: MoewColors.success)),
                ]),
              ])),
            ]),
          )),
        ]);
      }),

      SizedBox(height: 16),
      SizedBox(width: double.infinity, child: OutlinedButton(
        onPressed: () => setState(() => _result = null),
        child: Text('Tạo lại'),
      )),
    ];
  }

  Widget _productSelector(dynamic selectedId, ValueChanged<dynamic> onSelect) {
    return SizedBox(
      height: 56,
      child: ListView(scrollDirection: Axis.horizontal, children: _products.map<Widget>((p) {
        final active = selectedId == p['id'];
        return GestureDetector(
          onTap: () => onSelect(p['id']),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: active ? MoewColors.primary.withValues(alpha: 0.1) : MoewColors.white,
              borderRadius: BorderRadius.circular(MoewRadius.md),
              border: Border.all(color: active ? MoewColors.primary : MoewColors.border, width: active ? 2 : 1),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(p['name'] ?? '', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? MoewColors.primary : MoewColors.textMain)),
              Text('${p['remainingGrams'] ?? 0}g', style: TextStyle(fontSize: 10, color: active ? MoewColors.primary : MoewColors.textSub)),
            ]),
          ),
        );
      }).toList()),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MoewColors.textSub, letterSpacing: 0.5)),
    );
  }
}
