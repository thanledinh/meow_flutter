import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme.dart';
import '../../api/clinic_api.dart';
import '../../api/api_client.dart';
import '../../utils/parse_utils.dart';
import '../../widgets/toast.dart';
import '../../widgets/common_widgets.dart';

class ClinicDetailScreen extends StatefulWidget {
  final dynamic clinicId;
  const ClinicDetailScreen({super.key, required this.clinicId});
  @override
  State<ClinicDetailScreen> createState() => _ClinicDetailScreenState();
}

class _ClinicDetailScreenState extends State<ClinicDetailScreen> {
  Map<String, dynamic>? _clinic;
  List<dynamic> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ClinicApi.getById(widget.clinicId),
      ClinicApi.getReviews(widget.clinicId),
    ]);
    if (!mounted) return;
    setState(() {
      _clinic = (results[0].data as Map?)?['data'] ?? results[0].data as Map<String, dynamic>?;
      final reviewData = (results[1].data as Map?)?['data'];
      _reviews = reviewData is List ? reviewData : (_clinic?['reviews'] is List ? _clinic!['reviews'] : []);
      _loading = false;
    });
  }

  String _img(String? url) =>
      url == null ? '' : (url.startsWith('http') ? url : '${ApiConfig.baseUrl}$url');

  // ─── BUILD ───────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: MoewColors.primary))
          : _clinic == null
              ? Scaffold(body: EmptyState(icon: Icons.medical_services_outlined, color: MoewColors.primary, message: 'Không tìm thấy'))
              : CustomScrollView(slivers: [
                  _buildSliverAppBar(),
                  SliverToBoxAdapter(child: _buildBody()),
                ]),
    );
  }

  // ─── SLIVER APP BAR ──────────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: MoewColors.primary,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(fit: StackFit.expand, children: [
          _clinic!['avatar'] != null
              ? CachedNetworkImage(imageUrl: _img(_clinic!['avatar']), fit: BoxFit.cover)
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [MoewColors.primary, Color(0xFF1A6BA0)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                  child: Center(child: Icon(Icons.medical_services, size: 72, color: Colors.white24)),
                ),
          // Gradient overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
              ),
            ),
          ),
          // Bottom info overlay
          Positioned(left: 20, right: 20, bottom: 16, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(_clinic!['name'] ?? '', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white))),
              if (_clinic!['isVerified'] == true)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: MoewColors.success, borderRadius: BorderRadius.circular(6)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.verified, size: 12, color: Colors.white),
                    SizedBox(width: 3),
                    Text('Xác minh', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
            ]),
            SizedBox(height: 6),
            Row(children: [
              Icon(Icons.star_rounded, size: 18, color: MoewColors.warning),
              SizedBox(width: 3),
              Text('${_clinic!['rating'] ?? 0}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
              if (_clinic!['reviewCount'] != null) Text(' (${_clinic!['reviewCount']})', style: TextStyle(fontSize: 13, color: Colors.white70)),
            ]),
          ])),
        ]),
      ),
    );
  }

  // ─── BODY ────────────────────────────────────────────
  Widget _buildBody() {
    return Padding(
      padding: EdgeInsets.all(MoewSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Action buttons (sticky feel at top) ──
        _buildActionButtons(),
        SizedBox(height: MoewSpacing.lg),

        // ── Contact card ──
        _buildContactCard(),
        SizedBox(height: MoewSpacing.md),

        // ── Description ──
        if (_clinic!['description'] != null && _clinic!['description'].toString().isNotEmpty) ...[
          _buildSectionCard(
            title: 'Giới thiệu',
            icon: Icons.info_outline,
            child: Text(_clinic!['description'].toString(), style: TextStyle(fontSize: 14, color: MoewColors.textMain, height: 1.5)),
          ),
          SizedBox(height: MoewSpacing.md),
        ],

        // ── Open hours ──
        if (_clinic!['openHours'] is Map && (_clinic!['openHours'] as Map).isNotEmpty) ...[
          _buildOpenHoursCard(),
          SizedBox(height: MoewSpacing.md),
        ],

        // ── Services ──
        if (_clinic!['services'] is List && (_clinic!['services'] as List).isNotEmpty) ...[
          _buildServicesCard(),
          SizedBox(height: MoewSpacing.md),
        ],

        // ── Reviews ──
        _buildReviewsSection(),
        SizedBox(height: MoewSpacing.lg),
      ]),
    );
  }

  // ─── ACTION BUTTONS ──────────────────────────────────
  Widget _buildActionButtons() {
    return Row(children: [
      Expanded(
        child: _actionButton(
          icon: Icons.directions_rounded,
          label: 'Chỉ đường',
          color: MoewColors.primary,
          filled: false,
          onTap: _openMap,
        ),
      ),
      SizedBox(width: 12),
      Expanded(
        child: _actionButton(
          icon: Icons.calendar_month_rounded,
          label: 'Đặt lịch khám',
          color: MoewColors.primary,
          filled: true,
          onTap: _showBookingSheet,
        ),
      ),
    ]);
  }

  Widget _actionButton({
    required IconData icon, required String label, required Color color,
    required bool filled, required VoidCallback onTap,
  }) {
    return Material(
      color: filled ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(MoewRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(MoewRadius.lg),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14),
          decoration: filled
              ? null
              : BoxDecoration(
                  border: Border.all(color: color, width: 1.5),
                  borderRadius: BorderRadius.circular(MoewRadius.lg),
                ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 20, color: filled ? Colors.white : color),
            SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: filled ? Colors.white : color)),
          ]),
        ),
      ),
    );
  }

  // ─── CONTACT CARD ────────────────────────────────────
  Widget _buildContactCard() {
    return Container(
      padding: EdgeInsets.all(MoewSpacing.md),
      decoration: BoxDecoration(
        color: MoewColors.white,
        borderRadius: BorderRadius.circular(MoewRadius.lg),
        boxShadow: MoewShadows.card,
      ),
      child: Column(children: [
        _contactRow(Icons.location_on_outlined, _clinic!['address'] ?? '', MoewColors.primary, onTap: _openMap),
        if (_clinic!['phone'] != null) _contactRow(Icons.phone_outlined, _clinic!['phone'], MoewColors.success),
        if (_clinic!['email'] != null) _contactRow(Icons.email_outlined, _clinic!['email'], MoewColors.accent),
        if (_clinic!['website'] != null) _contactRow(Icons.language_rounded, _clinic!['website'], MoewColors.primary),
        if (_clinic!['priceRange'] != null) _contactRow(Icons.attach_money, 'Khoảng giá: ${_clinic!['priceRange']}', MoewColors.secondary),
      ]),
    );
  }

  Widget _contactRow(IconData icon, String text, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: color),
          ),
          SizedBox(width: 12),
          Expanded(child: Text(
            text,
            style: TextStyle(fontSize: 14, color: onTap != null ? color : MoewColors.textMain, fontWeight: FontWeight.w500,
              decoration: onTap != null ? TextDecoration.underline : null, decorationColor: color),
          )),
        ]),
      ),
    );
  }

  // ─── SECTION CARD ────────────────────────────────────
  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: EdgeInsets.all(MoewSpacing.md),
      decoration: BoxDecoration(
        color: MoewColors.white,
        borderRadius: BorderRadius.circular(MoewRadius.lg),
        boxShadow: MoewShadows.card,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: MoewColors.primary),
          SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: MoewColors.textMain, letterSpacing: 0.5)),
        ]),
        SizedBox(height: MoewSpacing.sm),
        child,
      ]),
    );
  }

  // ─── OPEN HOURS ──────────────────────────────────────
  Widget _buildOpenHoursCard() {
    final hours = _clinic!['openHours'] as Map;
    final now = DateTime.now();
    final todayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    final todayKey = now.weekday >= 1 && now.weekday <= 7 ? todayKeys[now.weekday - 1] : '';

    return _buildSectionCard(
      title: 'Giờ mở cửa',
      icon: Icons.access_time_rounded,
      child: SizedBox(
        height: 72,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: hours.entries.map<Widget>((e) {
            final isToday = e.key.toString() == todayKey;
            final dayName = _dayLabel(e.key.toString());
            final hourText = e.value.toString();
            return Container(
              width: 80,
              margin: EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              decoration: BoxDecoration(
                color: isToday ? MoewColors.success.withValues(alpha: 0.1) : MoewColors.surface,
                borderRadius: BorderRadius.circular(MoewRadius.md),
                border: Border.all(color: isToday ? MoewColors.success : MoewColors.border, width: isToday ? 1.5 : 1),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(dayName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isToday ? MoewColors.success : MoewColors.textMain)),
                SizedBox(height: 4),
                Text(hourText, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isToday ? MoewColors.success : MoewColors.textSub)),
              ]),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── SERVICES ────────────────────────────────────────
  Widget _buildServicesCard() {
    final services = _clinic!['services'] as List;
    return _buildSectionCard(
      title: 'Dịch vụ',
      icon: Icons.medical_services_outlined,
      child: Wrap(spacing: 8, runSpacing: 8, children: services.map<Widget>((s) {
        final name = s is Map ? (s['name'] ?? s.toString()) : s.toString();
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: MoewColors.tintBlue,
            borderRadius: BorderRadius.circular(MoewRadius.md),
            border: Border.all(color: MoewColors.primary.withValues(alpha: 0.15)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check_circle_outline, size: 14, color: MoewColors.primary),
            SizedBox(width: 6),
            Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MoewColors.primary)),
          ]),
        );
      }).toList()),
    );
  }

  // ─── REVIEWS ─────────────────────────────────────────
  Widget _buildReviewsSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.rate_review_outlined, size: 18, color: MoewColors.warning),
        SizedBox(width: 8),
        Text('Đánh giá', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: MoewColors.textMain, letterSpacing: 0.5)),
        Spacer(),
        if (_reviews.isNotEmpty) Text('${_reviews.length} đánh giá', style: MoewTextStyles.caption),
      ]),
      SizedBox(height: MoewSpacing.sm),
      if (_reviews.isEmpty)
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(MoewSpacing.lg),
          decoration: BoxDecoration(color: MoewColors.surface, borderRadius: BorderRadius.circular(MoewRadius.lg)),
          child: Column(children: [
            Icon(Icons.chat_bubble_outline, size: 32, color: MoewColors.textSub),
            SizedBox(height: 8),
            Text('Chưa có đánh giá nào', style: MoewTextStyles.caption),
          ]),
        )
      else
        ...List.generate(_reviews.length, (i) => _buildReviewItem(_reviews[i])),
    ]);
  }

  Widget _buildReviewItem(dynamic r) {
    final userName = (r['user'] is Map ? r['user']['displayName'] : r['userName']) ?? 'Sen ẩn danh';
    final rating = (r['rating'] ?? 0) as num;
    final comment = r['comment']?.toString();
    final date = r['createdAt']?.toString();

    return Container(
      margin: EdgeInsets.only(bottom: MoewSpacing.sm),
      padding: EdgeInsets.all(MoewSpacing.md),
      decoration: BoxDecoration(
        color: MoewColors.white,
        borderRadius: BorderRadius.circular(MoewRadius.lg),
        boxShadow: MoewShadows.card,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Avatar circle
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: MoewColors.tintPurple,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: MoewColors.accent),
            )),
          ),
          SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(userName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MoewColors.textMain)),
            if (date != null && date.length >= 10) Text(date.substring(0, 10), style: TextStyle(fontSize: 11, color: MoewColors.textSub)),
          ])),
          // Stars
          Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) =>
            Padding(
              padding: EdgeInsets.only(left: 1),
              child: Icon(i < rating ? Icons.star_rounded : Icons.star_outline_rounded, size: 16, color: i < rating ? MoewColors.warning : MoewColors.border),
            ),
          )),
        ]),
        if (comment != null && comment.isNotEmpty) Padding(
          padding: EdgeInsets.only(top: 10, left: 46),
          child: Text(comment, style: TextStyle(fontSize: 14, color: MoewColors.textMain, height: 1.4)),
        ),
      ]),
    );
  }

  // ─── HELPERS ─────────────────────────────────────────
  String _dayLabel(String key) {
    const map = {
      'mon': 'T2', 'tue': 'T3', 'wed': 'T4',
      'thu': 'T5', 'fri': 'T6', 'sat': 'T7', 'sun': 'CN',
    };
    return map[key.toLowerCase()] ?? key;
  }

  void _openMap() {
    final lat = toDouble(_clinic?['latitude']);
    final lng = toDouble(_clinic?['longitude']);
    final name = _clinic?['name']?.toString() ?? 'Phòng khám';
    if (lat == 0 && lng == 0) {
      MoewToast.show(context, message: 'Phòng khám chưa cập nhật vị trí', type: ToastType.info);
      return;
    }
    Navigator.pushNamed(context, '/guardian-map', arguments: {
      'destination': {'latitude': lat, 'longitude': lng, 'name': name},
    });
  }

  void _showBookingSheet() {
    Navigator.pushNamed(context, '/book-appointment', arguments: {
      'clinicId': widget.clinicId,
      'clinicName': _clinic?['name']?.toString(),
    });
  }
}
