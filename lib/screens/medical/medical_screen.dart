import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../api/medical_api.dart';
import '../../utils/parse_utils.dart';
import '../../widgets/common_widgets.dart';

class MedicalScreen extends StatefulWidget {
  final dynamic petId;
  const MedicalScreen({super.key, required this.petId});
  @override
  State<MedicalScreen> createState() => _MedicalScreenState();
}

class _MedicalScreenState extends State<MedicalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _medical = [], _vaccines = [], _appointments = [];
  bool _loading = true;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() => setState(() => _tab = _tabCtrl.index));
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      MedicalApi.getAll(widget.petId),
      VaccinationApi.getAll(widget.petId),
      AppointmentApi.getAll(widget.petId),
    ]);
    if (!mounted) return;
    setState(() {
      _medical = toList(results[0].data);
      _vaccines = toList(results[1].data);
      _appointments = toList(results[2].data);
      _loading = false;
    });
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: const AppHeader(title: 'Hồ sơ y tế'),
      body: Column(children: [
        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: MoewSpacing.lg),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: MoewColors.surface, borderRadius: BorderRadius.circular(MoewRadius.md)),
          child: TabBar(
            controller: _tabCtrl,
            indicator: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.sm), boxShadow: MoewShadows.card),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: MoewColors.primary,
            unselectedLabelColor: MoewColors.textSub,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            dividerHeight: 0,
            tabs: const [
              Tab(icon: Icon(Icons.medical_services_outlined, size: 18), text: 'Y tế'),
              Tab(icon: Icon(Icons.fitness_center, size: 18), text: 'Tiêm chủng'),
              Tab(icon: Icon(Icons.calendar_month, size: 18), text: 'Lịch hẹn'),
            ],
          ),
        ),
        const SizedBox(height: MoewSpacing.md),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: MoewColors.primary))
              : TabBarView(controller: _tabCtrl, children: [
                  _buildList(_medical, 'Chưa có hồ sơ y tế', MoewColors.danger, Icons.medical_services_outlined),
                  _buildList(_vaccines, 'Chưa có lịch tiêm', MoewColors.success, Icons.fitness_center),
                  _buildList(_appointments, 'Chưa có lịch hẹn', MoewColors.primary, Icons.calendar_month),
                ]),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add-medical', arguments: {'petId': widget.petId, 'type': ['medical', 'vaccination', 'appointment'][_tab]});
          if (result == true) _fetchAll();
        },
        backgroundColor: MoewColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildList(List<dynamic> items, String emptyMsg, Color color, IconData icon) {
    if (items.isEmpty) return EmptyState(icon: icon, color: color, message: emptyMsg);
    return RefreshIndicator(
      onRefresh: _fetchAll,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: MoewSpacing.lg),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final item = (items[i] is Map) ? items[i] as Map<String, dynamic> : <String, dynamic>{};
          final title = (item['title'] ?? item['name'] ?? item['vaccineName'] ?? item['reason'] ?? 'Bản ghi').toString();
          final date = item['startDate']?.toString() ?? item['date']?.toString() ?? '';
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/medical-detail', arguments: item),
            child: Container(
              margin: const EdgeInsets.only(bottom: MoewSpacing.sm),
              padding: const EdgeInsets.all(MoewSpacing.md),
              decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.card),
              child: Row(children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(MoewRadius.sm)), child: Icon(icon, size: 20, color: color)),
                const SizedBox(width: MoewSpacing.md),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MoewColors.textMain)),
                  if (date.length >= 10) Text(date.substring(0, 10), style: MoewTextStyles.caption),
                ])),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/cost-breakdown', arguments: {'petId': widget.petId, 'recordId': item['id'] ?? item['_id'], 'type': ['medical', 'vaccination', 'appointment'][_tab]}),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: MoewColors.tintAmber, borderRadius: BorderRadius.circular(MoewRadius.sm)),
                    child: const Icon(Icons.attach_money, size: 18, color: MoewColors.secondary),
                  ),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }
}
