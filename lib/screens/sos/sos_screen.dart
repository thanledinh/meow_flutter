import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../config/theme.dart';
import '../../api/sos_api.dart';
import '../../api/pet_api.dart';
import '../../services/socket_service.dart';
import '../../widgets/toast.dart';
import '../../widgets/common_widgets.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});
  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _pets = [];
  dynamic _selectedPetId;
  final _descCtrl = TextEditingController();
  bool _loading = false;
  bool _searching = false;
  dynamic _sosId;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _fetchPets();
  }

  Future<void> _fetchPets() async {
    final res = await PetApi.getAll();
    if (!mounted) return;
    final pets = (res.data as Map?)?['data'] ?? res.data ?? [];
    setState(() { _pets = pets is List ? pets : []; if (_pets.isNotEmpty) _selectedPetId = _pets[0]['id']; });
  }

  Future<void> _triggerSOS() async {
    if (_selectedPetId == null) { MoewToast.show(context, message: 'Chọn thú cưng', type: ToastType.warning); return; }
    setState(() => _loading = true);

    // Get location
    Position? pos;
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) MoewToast.show(context, message: 'Cần quyền vị trí cho SOS', type: ToastType.error);
        setState(() => _loading = false);
        return;
      }
      pos = await Geolocator.getCurrentPosition();
    } catch (_) { pos = null; }

    final res = await SosApi.trigger({
      'petId': _selectedPetId,
      'description': _descCtrl.text.trim(),
      if (pos != null) 'latitude': pos.latitude,
      if (pos != null) 'longitude': pos.longitude,
    });
    if (!mounted) return;
    setState(() => _loading = false);
    if (res.success) {
      final data = (res.data as Map?)?['data'] ?? res.data;
      _sosId = data?['id'] ?? data?['sosId'];
      setState(() => _searching = true);
      // Listen via socket
      final socket = SocketService();
      await socket.connect();
      socket.on('sos:accepted', (data) {
        if (mounted) {
          setState(() => _searching = false);
          MoewToast.show(context, message: 'Phòng khám đã nhận SOS!', type: ToastType.success);
        }
      });
    } else {
      MoewToast.show(context, message: res.error ?? 'Lỗi gửi SOS', type: ToastType.error);
    }
  }

  Future<void> _cancelSOS() async {
    if (_sosId == null) return;
    final res = await SosApi.cancel(_sosId);
    if (!mounted) return;
    if (res.success) {
      setState(() => _searching = false);
      MoewToast.show(context, message: 'Đã hủy SOS', type: ToastType.info);
    }
  }

  @override
  void dispose() { _pulseCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _searching ? const Color(0xFFFDEDEE) : MoewColors.background,
      appBar: const AppHeader(title: 'SOS Cấp cứu'),
      body: _searching ? _buildSearching() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return ListView(padding: const EdgeInsets.all(MoewSpacing.lg), children: [
      // Warning banner
      Container(
        padding: const EdgeInsets.all(MoewSpacing.md),
        decoration: BoxDecoration(color: MoewColors.tintRed, borderRadius: BorderRadius.circular(MoewRadius.lg), border: Border.all(color: MoewColors.danger.withValues(alpha: 0.3))),
        child: const Row(children: [
          Icon(Icons.warning_amber, size: 24, color: MoewColors.danger),
          SizedBox(width: 12),
          Expanded(child: Text('Chỉ sử dụng khi thú cưng cần cấp cứu ngay lập tức', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: MoewColors.danger))),
        ]),
      ),
      const SizedBox(height: MoewSpacing.lg),

      // Pet selector
      Text('CHỌN THÚ CƯNG', style: MoewTextStyles.label),
      const SizedBox(height: MoewSpacing.sm),
      if (_pets.isEmpty)
        Text('Chưa có thú cưng', style: MoewTextStyles.caption)
      else
        DropdownButtonFormField<dynamic>(
          value: _selectedPetId,
          items: _pets.map((p) => DropdownMenuItem(value: p['id'], child: Text(p['name'] ?? 'Pet'))).toList(),
          onChanged: (v) => setState(() => _selectedPetId = v),
          decoration: const InputDecoration(prefixIcon: Icon(Icons.pets, color: MoewColors.textSub)),
        ),
      const SizedBox(height: MoewSpacing.md),

      Text('MÔ TẢ TÌNH TRẠNG', style: MoewTextStyles.label),
      const SizedBox(height: MoewSpacing.sm),
      TextField(controller: _descCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Mô tả tình trạng thú cưng...')),
      const SizedBox(height: MoewSpacing.xl),

      // SOS button
      SizedBox(
        width: double.infinity, height: 64,
        child: ElevatedButton.icon(
          onPressed: _loading ? null : _triggerSOS,
          icon: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.warning, size: 28, color: Colors.white),
          label: Text(_loading ? 'Đang gửi...' : 'GỬI SOS', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
          style: ElevatedButton.styleFrom(backgroundColor: MoewColors.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoewRadius.xl))),
        ),
      ),
    ]);
  }

  Widget _buildSearching() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (ctx, child) => Container(
            width: 120 + _pulseCtrl.value * 40,
            height: 120 + _pulseCtrl.value * 40,
            decoration: BoxDecoration(
              color: MoewColors.danger.withValues(alpha: 0.15 - _pulseCtrl.value * 0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Center(child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: MoewColors.danger, borderRadius: BorderRadius.circular(50)),
              child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.warning, size: 36, color: Colors.white),
                Text('SOS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
              ]),
            )),
          ),
        ),
        const SizedBox(height: 32),
        Text('Đang tìm phòng khám gần bạn...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: MoewColors.danger)),
        const SizedBox(height: 8),
        Text('Tự động mở rộng: 5km → 10km → 15km', style: MoewTextStyles.caption),
        const SizedBox(height: 32),
        OutlinedButton(
          onPressed: _cancelSOS,
          style: OutlinedButton.styleFrom(side: const BorderSide(color: MoewColors.danger)),
          child: const Text('Hủy SOS', style: TextStyle(color: MoewColors.danger, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}
