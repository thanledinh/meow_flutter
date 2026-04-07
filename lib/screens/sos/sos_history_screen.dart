import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../api/sos_api.dart';
import '../../utils/parse_utils.dart';
import '../../widgets/common_widgets.dart';

class SosHistoryScreen extends StatefulWidget {
  const SosHistoryScreen({super.key});
  @override
  State<SosHistoryScreen> createState() => _SosHistoryScreenState();
}

class _SosHistoryScreenState extends State<SosHistoryScreen> {
  List<dynamic> _history = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final res = await SosApi.getHistory();
    if (!mounted) return;
    setState(() { _history = (res.data as Map?)?['data'] ?? []; _loading = false; });
  }

  Color _statusColor(String? s) {
    switch (s) { case 'accepted': return MoewColors.success; case 'completed': return MoewColors.primary; case 'cancelled': case 'expired': return MoewColors.textSub; default: return MoewColors.warning; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: AppHeader(title: 'Lịch sử SOS'),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: MoewColors.primary))
          : _history.isEmpty
              ? EmptyState(icon: Icons.monitor_heart_outlined, color: MoewColors.danger, message: 'Chưa có SOS nào')
              : RefreshIndicator(onRefresh: _fetch, child: ListView.builder(
                  padding: EdgeInsets.all(MoewSpacing.lg),
                  itemCount: _history.length,
                  itemBuilder: (ctx, i) {
                    final h = _history[i] as Map<String, dynamic>;
                    return Container(
                      margin: EdgeInsets.only(bottom: MoewSpacing.sm),
                      padding: EdgeInsets.all(MoewSpacing.md),
                      decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.card),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('SOS #${h['id']}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MoewColors.textMain)),
                          StatusBadge(label: h['status'] ?? 'searching', color: _statusColor(h['status']), icon: Icons.circle),
                        ]),
                        if (h['pet'] is Map) Padding(padding: EdgeInsets.only(top: 4), child: Row(children: [Icon(Icons.pets, size: 14, color: MoewColors.textSub), SizedBox(width: 4), Text(h['pet']['name'] ?? '', style: MoewTextStyles.caption)])),
                        if (h['description'] != null) Padding(padding: EdgeInsets.only(top: 4), child: Text(h['description'], style: MoewTextStyles.body)),
                        if (h['clinic'] is Map) Padding(padding: EdgeInsets.only(top: 4), child: Row(children: [Icon(Icons.medical_services_outlined, size: 14, color: MoewColors.success), SizedBox(width: 4), Expanded(child: Text(h['clinic']['name'] ?? '', style: TextStyle(fontSize: 13, color: MoewColors.success, fontWeight: FontWeight.w600)))])),
                        if (h['totalCost'] != null) Padding(padding: EdgeInsets.only(top: 4), child: Row(children: [Icon(Icons.attach_money, size: 14, color: MoewColors.secondary), SizedBox(width: 4), Text(formatVND(h['totalCost']), style: TextStyle(fontSize: 13, color: MoewColors.secondary, fontWeight: FontWeight.w600))])),
                        if (h['createdAt'] != null) Padding(padding: EdgeInsets.only(top: 4), child: Text(h['createdAt'].toString().substring(0, 16).replaceAll('T', ' '), style: MoewTextStyles.caption)),
                      ]),
                    );
                  },
                )),
    );
  }
}
