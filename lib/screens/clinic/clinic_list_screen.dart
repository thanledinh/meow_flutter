import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../api/clinic_api.dart';
import '../../api/api_client.dart';
import '../../widgets/common_widgets.dart';

class ClinicListScreen extends StatefulWidget {
  const ClinicListScreen({super.key});
  @override
  State<ClinicListScreen> createState() => _ClinicListScreenState();
}

class _ClinicListScreenState extends State<ClinicListScreen> {
  List<dynamic> _clinics = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch({String? search}) async {
    setState(() => _loading = true);
    final res = await ClinicApi.getAll(search: search);
    if (!mounted) return;
    setState(() {
      final data = res.data;
      // API returns {data: [...], pagination: {...}} or {data: [...]}
      _clinics = (data is Map && data['data'] is List) ? data['data'] : (data is List ? data : []);
      _loading = false;
    });
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: AppHeader(title: 'Phòng khám', showBack: false),
      body: Column(children: [
        // Search
        Padding(
          padding: EdgeInsets.symmetric(horizontal: MoewSpacing.lg),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Tìm phòng khám...',
              prefixIcon: Icon(Icons.search, color: MoewColors.textSub),
              suffixIcon: _searchCtrl.text.isNotEmpty ? IconButton(icon: Icon(Icons.close), onPressed: () { _searchCtrl.clear(); _fetch(); }) : null,
            ),
            onSubmitted: (v) => _fetch(search: v.trim().isNotEmpty ? v.trim() : null),
          ),
        ),
        SizedBox(height: MoewSpacing.md),
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: MoewColors.primary))
              : _clinics.isEmpty
                  ? EmptyState(icon: Icons.medical_services_outlined, color: MoewColors.primary, message: 'Không tìm thấy phòng khám')
                  : RefreshIndicator(onRefresh: _fetch, child: ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: MoewSpacing.lg),
                      itemCount: _clinics.length,
                      itemBuilder: (ctx, i) {
                        final c = _clinics[i] as Map<String, dynamic>;
                        return GestureDetector(
                          onTap: () => context.push('/clinic-detail', extra: c['id']),
                          child: Container(
                            margin: EdgeInsets.only(bottom: MoewSpacing.sm),
                            padding: EdgeInsets.all(MoewSpacing.md),
                            decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.card),
                            child: Row(children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(MoewRadius.sm),
                                child: c['avatar'] != null
                                    ? CachedNetworkImage(imageUrl: c['avatar'].toString().startsWith('http') ? c['avatar'] : '${ApiConfig.baseUrl}${c['avatar']}', width: 60, height: 60, fit: BoxFit.cover)
                                    : Container(width: 60, height: 60, color: MoewColors.tintBlue, child: Icon(Icons.medical_services, color: MoewColors.primary)),
                              ),
                              SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(c['name'] ?? '', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: MoewColors.textMain)),
                                Text(c['address'] ?? '', style: MoewTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                                Row(children: [
                                  Icon(Icons.star, size: 14, color: MoewColors.warning),
                                  SizedBox(width: 4),
                                  Text('${c['rating'] ?? 0}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MoewColors.textMain)),
                                  if (c['reviewCount'] != null) ...[Text(' · ', style: MoewTextStyles.caption), Text('${c['reviewCount']} đánh giá', style: MoewTextStyles.caption)],
                                  if (c['distance'] != null) ...[Text(' · ', style: MoewTextStyles.caption), Text('${c['distance']}km', style: MoewTextStyles.caption)],
                                ]),
                              ])),
                              Icon(Icons.chevron_right, size: 20, color: MoewColors.textSub),
                            ]),
                          ),
                        );
                      },
                    )),
        ),
      ]),
    );
  }
}
