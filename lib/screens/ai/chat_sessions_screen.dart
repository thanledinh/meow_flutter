import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      appBar: AppHeader(title: 'Lịch sử chat AI'),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: MoewColors.primary))
          : _sessions.isEmpty
              ? EmptyState(icon: Icons.chat_bubble_outline, color: MoewColors.primary, message: 'Chưa có phiên chat nào')
              : ListView.builder(
                  padding: EdgeInsets.all(MoewSpacing.md),
                  itemCount: _sessions.length,
                  itemBuilder: (_, i) {
                    final s = _sessions[i] as Map<String, dynamic>;
                    final date = s['updatedAt']?.toString().substring(0, 10) ?? '';
                    return GestureDetector(
                      onTap: () => context.push('/ai-chat', extra: {'sessionId': s['id'], 'petId': null}),
                      child: Container(
                        margin: EdgeInsets.only(bottom: 10),
                        padding: EdgeInsets.all(14),
                        decoration: BoxDecoration(color: MoewColors.white, borderRadius: BorderRadius.circular(MoewRadius.lg), boxShadow: MoewShadows.soft),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: MoewColors.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(MoewRadius.md)),
                            child: Icon(Icons.auto_awesome, color: MoewColors.accent, size: 22),
                          ),
                          SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(s['title']?.toString() ?? 'Phiên chat', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MoewColors.textMain), maxLines: 1, overflow: TextOverflow.ellipsis),
                            SizedBox(height: 2),
                            Row(children: [
                              if (s['petName'] != null) ...[
                                Icon(Icons.pets, size: 12, color: MoewColors.textSub),
                                SizedBox(width: 3),
                                Text(s['petName'].toString(), style: TextStyle(fontSize: 11, color: MoewColors.textSub)),
                                SizedBox(width: 8),
                              ],
                              if (s['foodName'] != null) ...[
                                Icon(Icons.fastfood, size: 12, color: MoewColors.textSub),
                                SizedBox(width: 3),
                                Text(s['foodName'].toString(), style: TextStyle(fontSize: 11, color: MoewColors.textSub)),
                              ],
                            ]),
                          ])),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text(date, style: TextStyle(fontSize: 10, color: MoewColors.textSub)),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: MoewColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(MoewRadius.full)),
                              child: Text('${s['messageCount'] ?? 0} tin', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: MoewColors.primary)),
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
