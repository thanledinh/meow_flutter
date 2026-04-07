import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../api/ai_api.dart';
import '../../utils/parse_utils.dart';
import '../../widgets/toast.dart';
import '../../widgets/common_widgets.dart';

class AiChatScreen extends StatefulWidget {
  final dynamic petId;
  final dynamic foodLogId;
  const AiChatScreen({super.key, this.petId, this.foodLogId});
  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  dynamic _sessionId;
  Map<String, dynamic>? _foodContext;
  bool _sending = false;
  bool _starting = true;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  Future<void> _startSession() async {
    setState(() => _starting = true);
    final body = <String, dynamic>{
      'petId': widget.petId,
      if (widget.foodLogId != null) 'foodLogId': widget.foodLogId,
    };
    final res = await AiApi.chatStart(body);
    if (!mounted) return;
    setState(() => _starting = false);

    if (res.success) {
      final raw = res.data;
      final data = raw is Map ? (raw['data'] is Map ? raw['data'] : raw) : raw;
      _sessionId = data?['sessionId'] ?? data?['id'];

      // Load messages from session
      if (data?['messages'] is List) {
        setState(() => _messages = List<Map<String, dynamic>>.from(
          (data!['messages'] as List).map((m) => m is Map ? Map<String, dynamic>.from(m) : {'role': 'assistant', 'content': m.toString()}),
        ));
      }

      // Load food context if available
      if (data?['foodLog'] is Map) {
        setState(() => _foodContext = Map<String, dynamic>.from(data!['foodLog'] as Map));
      }

      // If there was a foodLogId but no initial messages from backend, 
      // show the food context info and auto-send a greeting
      if (widget.foodLogId != null && _messages.isEmpty) {
        // Send auto first message to get AI to respond with food analysis context
        _autoGreet();
      }

      _scrollDown();
    } else {
      if (mounted) MoewToast.show(context, message: res.error ?? 'Không thể tạo phiên chat', type: ToastType.error);
    }
  }

  Future<void> _autoGreet() async {
    if (_sessionId == null) return;
    setState(() => _sending = true);
    final res = await AiApi.chatSend(_sessionId, 'Phân tích kết quả thức ăn vừa xong cho tôi');
    if (!mounted) return;
    setState(() => _sending = false);
    if (res.success) {
      final data = (res.data as Map?)?['data'] ?? res.data;
      final reply = data?['reply'] ?? data?['message'] ?? data?['content'] ?? '';
      if (reply.toString().isNotEmpty) {
        setState(() => _messages.add({'role': 'assistant', 'content': reply.toString()}));
        _scrollDown();
      }
    }
  }

  Future<void> _send() async {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty || _sessionId == null) return;
    setState(() {
      _messages.add({'role': 'user', 'content': msg});
      _sending = true;
    });
    _msgCtrl.clear();
    _scrollDown();

    final res = await AiApi.chatSend(_sessionId, msg);
    if (!mounted) return;
    setState(() => _sending = false);
    if (res.success) {
      final data = (res.data as Map?)?['data'] ?? res.data;
      final reply = data?['reply'] ?? data?['message'] ?? data?['content'] ?? '';
      setState(() => _messages.add({'role': 'assistant', 'content': reply.toString()}));
      _scrollDown();
    } else {
      MoewToast.show(context, message: 'Lỗi gửi tin nhắn', type: ToastType.error);
    }
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: const AppHeader(title: 'Bác sĩ Moew AI'),
      body: Column(children: [
        // ── Food context banner ──
        if (_foodContext != null) _buildFoodBanner(),

        // ── Messages ──
        Expanded(
          child: _starting
              ? Center(child: CircularProgressIndicator(color: MoewColors.accent))
              : _messages.isEmpty && !_sending
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.auto_awesome, size: 48, color: MoewColors.accent),
                      SizedBox(height: 12),
                      Text(widget.foodLogId != null ? 'Đang tải kết quả phân tích...' : 'Hỏi AI bất cứ điều gì!', style: MoewTextStyles.body),
                      SizedBox(height: 4),
                      Text('AI đóng vai bác sĩ thú y Moew', style: MoewTextStyles.caption),
                    ]))
                  : ListView.builder(
                      controller: _scroll,
                      padding: EdgeInsets.all(MoewSpacing.md),
                      itemCount: _messages.length,
                      itemBuilder: (ctx, i) => _buildMessage(_messages[i]),
                    ),
        ),

        // ── Typing indicator ──
        if (_sending) Container(
          padding: EdgeInsets.symmetric(horizontal: MoewSpacing.lg, vertical: 8),
          child: Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: MoewColors.tintPurple, borderRadius: BorderRadius.circular(14)),
              child: Icon(Icons.auto_awesome, size: 14, color: MoewColors.accent),
            ),
            SizedBox(width: 10),
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: MoewColors.accent, strokeWidth: 2)),
            SizedBox(width: 8),
            Text('Moew đang suy nghĩ...', style: MoewTextStyles.caption),
          ]),
        ),

        // ── Input bar ──
        Container(
          padding: EdgeInsets.only(left: 12, right: 8, top: 8, bottom: MediaQuery.of(context).padding.bottom + 8),
          decoration: BoxDecoration(
            color: MoewColors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: Offset(0, -2), blurRadius: 8)],
          ),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _msgCtrl,
              decoration: InputDecoration(
                hintText: 'Hỏi bác sĩ Moew...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(MoewRadius.full), borderSide: BorderSide.none),
                filled: true,
                fillColor: MoewColors.surface,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                isDense: true,
              ),
              onSubmitted: (_) => _send(),
              textInputAction: TextInputAction.send,
            )),
            SizedBox(width: 6),
            Container(
              decoration: BoxDecoration(color: MoewColors.primary, borderRadius: BorderRadius.circular(MoewRadius.full)),
              child: IconButton(
                onPressed: _sending ? null : _send,
                icon: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                padding: EdgeInsets.all(10),
                constraints: const BoxConstraints(),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Food context card ──
  Widget _buildFoodBanner() {
    final name = _foodContext!['foodName']?.toString() ?? 'Thức ăn';
    final score = toDouble(_foodContext!['suitabilityScore']);
    final calories = _foodContext!['estimatedCalories']?.toString();
    final scoreColor = score >= 7 ? MoewColors.success : score >= 5 ? MoewColors.warning : MoewColors.danger;

    return Container(
      margin: EdgeInsets.all(MoewSpacing.sm),
      padding: EdgeInsets.all(MoewSpacing.sm),
      decoration: BoxDecoration(
        color: MoewColors.tintPurple,
        borderRadius: BorderRadius.circular(MoewRadius.md),
        border: Border.all(color: MoewColors.accent.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: MoewColors.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.restaurant, size: 18, color: MoewColors.accent),
        ),
        SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MoewColors.textMain)),
          Row(children: [
            if (calories != null) Text('$calories kcal', style: MoewTextStyles.caption),
            if (calories != null && score > 0) Text(' · ', style: MoewTextStyles.caption),
            if (score > 0) Text('Điểm: ${score.toStringAsFixed(0)}/10', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scoreColor)),
          ]),
        ])),
        Icon(Icons.chat_bubble_outline, size: 16, color: MoewColors.accent),
      ]),
    );
  }

  // ── Message bubble ──
  Widget _buildMessage(Map<String, dynamic> m) {
    final isUser = m['role'] == 'user';
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 30, height: 30,
              margin: EdgeInsets.only(right: 8, top: 2),
              decoration: BoxDecoration(color: MoewColors.tintPurple, borderRadius: BorderRadius.circular(15)),
              child: Icon(Icons.auto_awesome, size: 14, color: MoewColors.accent),
            ),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? MoewColors.primary : MoewColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: isUser ? null : MoewShadows.soft,
              ),
              child: Text(
                m['content']?.toString() ?? '',
                style: TextStyle(fontSize: 14, color: isUser ? Colors.white : MoewColors.textMain, height: 1.4),
              ),
            ),
          ),
          if (isUser) SizedBox(width: 38),
        ],
      ),
    );
  }
}
