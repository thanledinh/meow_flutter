import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../api/pet_api.dart';
import '../../api/api_client.dart';
import '../../utils/parse_utils.dart';
import '../../widgets/common_widgets.dart';

class PetProfileScreen extends StatefulWidget {
  const PetProfileScreen({super.key});
  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  List<dynamic> _pets = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final res = await PetApi.getAll();
    if (!mounted) return;
    setState(() {
      _pets = toList(res.data);
      _loading = false;
    });
  }

  String _img(String? url) => url == null ? '' : (url.startsWith('http') ? url : '${ApiConfig.baseUrl}$url');


  String _calcAge(dynamic birthDateStr) {
    if (birthDateStr == null || birthDateStr.toString().trim().isEmpty) return 'Chưa rõ tuổi';
    try {
      String dateStr = birthDateStr.toString().trim();
      if (RegExp(r'^\d{2}[-/]\d{2}[-/]\d{4}').hasMatch(dateStr)) {
        final parts = dateStr.split(RegExp(r'[-/]'));
        dateStr = '${parts[2]}-${parts[1]}-${parts[0]}';
      }
      final bDate = DateTime.parse(dateStr);
      final now = DateTime.now();
      int years = now.year - bDate.year;
      int months = now.month - bDate.month;
      if (months < 0) {
        years--;
        months += 12;
      }
      if (years > 0 && months > 0) return '$years năm $months tháng';
      if (years > 0) return '$years năm';
      if (months > 0) return '$months tháng';
      return 'Sơ sinh';
    } catch (_) {
      return 'Chưa rõ tuổi';
    }
  }

  Widget _buildChecklistItem(String title, IconData icon, bool checked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: MoewColors.textSub),
          const SizedBox(width: 6),
          Expanded(child: Text(title, style: TextStyle(fontSize: 11, color: MoewColors.textSub), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Icon(checked ? Icons.check_box : Icons.check_box_outline_blank, 
               size: 16, color: checked ? MoewColors.primary : MoewColors.textSub.withOpacity(0.3)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: AppHeader(title: 'Thú cưng', showBack: false, actions: [
        IconButton(icon: Icon(Icons.add_circle_outline, color: MoewColors.primary), onPressed: () async {
          final result = await context.push('/add-pet');
          if (result == true) _fetch();
        }),
      ]),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: MoewColors.primary))
          : _pets.isEmpty
              ? EmptyState(icon: Icons.pets, color: MoewColors.secondary, message: 'Chưa có thú cưng nào', buttonLabel: 'Thêm Boss', onAction: () async {
                  final result = await context.push('/add-pet');
                  if (result == true) _fetch();
                })
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(MoewSpacing.lg, MoewSpacing.lg, MoewSpacing.lg, 110),
                    itemCount: _pets.length,
                    itemBuilder: (ctx, i) {
                      final pet = _pets[i] as Map<String, dynamic>;
                      IconData genderIcon = pet['gender'] == 'male' ? Icons.male : (pet['gender'] == 'female' ? Icons.female : Icons.pets);
                      
                      return GestureDetector(
                        onTap: () => context.push('/pet-detail', extra: pet['id']),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Left 40%
                                Expanded(
                                  flex: 4,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: MoewColors.primary.withOpacity(0.1),
                                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                                      child: pet['avatar'] != null
                                          ? CachedNetworkImage(imageUrl: _img(pet['avatar']), fit: BoxFit.cover)
                                          : Center(child: Icon(Icons.pets, size: 50, color: MoewColors.primary.withOpacity(0.3))),
                                    ),
                                  ),
                                ),
                                // Right 60%
                                Expanded(
                                  flex: 6,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                pet['name'] ?? 'Pet #${pet['id']}', 
                                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(color: MoewColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                              child: Icon(genderIcon, size: 16, color: MoewColors.primary),
                                            )
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Tuổi: ${_calcAge(pet['birthDate'])}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                        const SizedBox(height: 12),
                                        
                                        // Mock Checklist Box
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
                                          child: Column(
                                            children: [
                                              _buildChecklistItem('Grooming', Icons.cut, true),
                                              _buildChecklistItem('Walking for 5 km', Icons.directions_walk, true),
                                              _buildChecklistItem('Healthy food', Icons.restaurant, false),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        
                                        // View details button
                                        SizedBox(
                                          width: double.infinity,
                                          height: 36,
                                          child: ElevatedButton(
                                            onPressed: () => context.push('/pet-detail', extra: pet['id']),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: MoewColors.primary,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              padding: EdgeInsets.zero
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: const [
                                                Text('Soi hồ sơ báo thủ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                                SizedBox(width: 4),
                                                Icon(Icons.arrow_forward_rounded, size: 14),
                                              ],
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
},
                  ),
                ),
    );
  }
}
