import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: AppHeader(title: 'Thú cưng', showBack: false, actions: [
        IconButton(icon: const Icon(Icons.add_circle_outline, color: MoewColors.primary), onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add-pet');
          if (result == true) _fetch();
        }),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MoewColors.primary))
          : _pets.isEmpty
              ? EmptyState(icon: Icons.pets, color: MoewColors.secondary, message: 'Chưa có thú cưng nào', buttonLabel: 'Thêm Boss', onAction: () async {
                  final result = await Navigator.pushNamed(context, '/add-pet');
                  if (result == true) _fetch();
                })
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(MoewSpacing.lg),
                    itemCount: _pets.length,
                    itemBuilder: (ctx, i) {
                      final pet = _pets[i] as Map<String, dynamic>;
                      return GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/pet-detail', arguments: pet['id']),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: MoewSpacing.sm),
                          padding: const EdgeInsets.all(MoewSpacing.md),
                          decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.card),
                          child: Row(children: [
                            pet['avatar'] != null
                                ? ClipRRect(borderRadius: BorderRadius.circular(24), child: CachedNetworkImage(imageUrl: _img(pet['avatar']), width: 48, height: 48, fit: BoxFit.cover))
                                : Container(width: 48, height: 48, decoration: BoxDecoration(color: MoewColors.secondary, borderRadius: BorderRadius.circular(24)), child: const Icon(Icons.pets, size: 22, color: Colors.white)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(pet['name'] ?? 'Pet #${pet['id']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: MoewColors.textMain)),
                              Text(pet['breed'] ?? pet['species'] ?? 'Boss nhà ta', style: const TextStyle(fontSize: 12, color: MoewColors.textSub)),
                            ])),
                            const Icon(Icons.chevron_right, size: 20, color: MoewColors.textSub),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
