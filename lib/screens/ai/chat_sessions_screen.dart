import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../api/feeding_api.dart';
import '../../widgets/common_widgets.dart';

class ChatSessionsScreen extends StatefulWidget {
  const ChatSessionsScreen({super.key});
  @override
  State<ChatSessionsScreen> createState() => _ChatSessionsScreenState();
}

class _ChatSessionsScreenState extends State<ChatSessionsScreen> {
  List<dynamic> _sessions = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    final res = await FeedingApi.getChatSessions();
    if (!mounted) return;
    final raw = res.data;
    setState(() {
      final data = (raw is Map) ? raw['data'] : raw;
      _sessions = data is List ? data : [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: const AppHeader(title: 'Lịch sử chat AI'),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MoewColors.primary))
          : _sessions.isEmpty
              ? const EmptyState(icon: Icons.chat_bubble_outline, color: MoewColors.primary, message: 'Chưa có phiên chat nào')
              : ListView.builder(
                  padding: const EdgeInsets.all(MoewSpacing.md),
                  itemCount: _sessions.length,
                  itemBuilder: (_, i) {
                    final s = _sessions[i] as Map<String, dynamic>;
                    final date = s['updatedAt']?.toString().substring(0, 10) ?? '';
                    return GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/ai-chat', arguments: {'sessionId': s['id'], 'petId': null}),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.soft),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: MoewColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(MoewRadius.md)),
                            child: const Icon(Icons.auto_awesome, color: MoewColors.accent, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s['title']?.toString() ?? 'Phiên chat', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MoewColors.textMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Row(children: [
                              if (s['petName'] != null) ...[
                                const Icon(Icons.pets, size: 12, color: MoewColors.textSub),
                                const SizedBox(width: 3),
                                Text(s['petName'].toString(), style: const TextStyle(fontSize: 11, color: MoewColors.textSub)),
                                const SizedBox(width: 8),
                              ],
                              if (s['foodName'] != null) ...[
                                const Icon(Icons.fastfood, size: 12, color: MoewColors.textSub),
                                const SizedBox(width: 3),
                                Text(s['foodName'].toString(), style: const TextStyle(fontSize: 11, color: MoewColors.textSub)),
                              ],
                            ]),
                          ])),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text(date, style: const TextStyle(fontSize: 10, color: MoewColors.textSub)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: MoewColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(MoewRadius.full)),
                              child: Text('${s['messageCount'] ?? 0} tin', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: MoewColors.primary)),
                            ),
                          ]),
                        ]),
                      ),
                    );
                  },
                ),
    );
  }
}
