import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../api/feeding_api.dart';
import '../../widgets/toast.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/eat_status_picker.dart';
import 'package:provider/provider.dart';
import '../../repositories/pet_repository.dart';

class FeedingTodayScreen extends StatefulWidget {
  const FeedingTodayScreen({super.key});
  @override
  State<FeedingTodayScreen> createState() => _FeedingTodayScreenState();
}

class _FeedingTodayScreenState extends State<FeedingTodayScreen> {
  Map<String, dynamic>? _data;
  int _streak = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch({bool showLoading = true}) async {
    if (showLoading) setState(() => _loading = true);
    final res = await FeedingApi.getToday();
    final streakRes = await FeedingApi.getStreak();
    if (!mounted) return;
    setState(() {
      final raw = res.data;
      _data = (raw is Map<String, dynamic>) ? (raw['data'] is Map ? raw['data'] : raw) : null;
      final sr = streakRes.data;
      _streak = (sr is Map ? (sr['data'] is Map ? sr['data']['streak'] : sr['streak']) : 0) ?? 0;
      _loading = false;
    });
  }

  Future<void> _confirmMeal(Map<String, dynamic> meal) async {
    final noteCtrl = TextEditingController();
    EatStatus selectedStatus = EatStatus.ateAll;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoewRadius.lg)),
          title: Row(children: [
            Icon(Icons.restaurant, color: MoewColors.success, size: 22),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Xác nhận cho ${meal['petName']} ăn',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ]),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Meal info chip
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MoewColors.surface,
                  borderRadius: BorderRadius.circular(MoewRadius.sm),
                ),
                child: Row(children: [
                  Icon(Icons.scale, size: 16, color: MoewColors.textSub),
                  SizedBox(width: 8),
                  Text(
                    '${meal['label']} • ${meal['portionGrams']}g ${meal['foodName']}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
              SizedBox(height: 14),

              // EatStatus Picker
              EatStatusPicker(
                initialStatus: EatStatus.ateAll,
                onChanged: (s) {
                  setDialogState(() => selectedStatus = s);
                },
              ),
              SizedBox(height: 14),

              // Note field
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                  hintText: 'Ghi chú (tùy chọn)',
                  prefixIcon: Icon(Icons.edit_note, size: 18),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: MoewColors.success),
              child: Text(
                'Xác nhận',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;

    final res = await FeedingApi.confirmMeal(
      meal['scheduleId'],
      eatStatus: selectedStatus.value,
      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
    );
    if (!mounted) return;

    if (res.success) {
      final d = res.data is Map
          ? (res.data['data'] is Map ? res.data['data'] : res.data)
          : res.data;

      // Early/Late warning
      if (d is Map && d['warning'] != null && d['warning'].toString().isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          MoewToast.show(
            context,
            message: d['warning'].toString(),
            type: d['isLate'] == true ? ToastType.error : ToastType.warning,
          );
        });
      }

      // Flagged snackbar (ate_little / ate_none)
      final isFlagged = d is Map && d['isFlagged'] == true;
      if (isFlagged) {
        MoewToast.show(
          context,
          message: 'Đã ghi nhận 🐾 Nếu bé bỏ ăn liên tục, hãy theo dõi thêm hoặc liên hệ bác sĩ.',
          type: ToastType.warning,
        );
      } else {
        MoewToast.show(
          context,
          message: res.data?['message'] ?? '✅ Đã xác nhận!',
          type: ToastType.success,
        );
      }

      _fetch(showLoading: false);
    } else {
      MoewToast.show(context, message: res.error ?? 'Lỗi', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPets = context.watch<PetRepository>().pets.isNotEmpty;

    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: const AppHeader(title: 'Cho ăn hôm nay', showBack: false),
        body: Center(child: CircularProgressIndicator(color: MoewColors.primary)),
      );
    }

    final timeline = _data?['timeline'] as List? ?? [];

    if (_data == null || timeline.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: const AppHeader(title: 'Cho ăn hôm nay', showBack: false),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: MoewColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.restaurant_menu, size: 48, color: MoewColors.primary),
                ),
                SizedBox(height: 24),
                Text(
                  'Chưa có lịch ăn nào!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: MoewColors.textMain),
                ),
                SizedBox(height: 12),
                Text(
                  hasPets 
                    ? 'Hãy thêm thức ăn vào kho và lên lịch ăn\n cho bé cưng nhé 🍲'
                    : 'Bạn cần thêm thú cưng và thiết lập\n khẩu phần ăn trước nhé 🐾',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: MoewColors.textSub, height: 1.5),
                ),
                SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/food-products'),
                    icon: Icon(Icons.inventory_2, size: 20),
                    label: Text('Quản lý Kho Thức Ăn'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MoewColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoewRadius.md)),
                      elevation: 0,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/feeding-plan'),
                    icon: Icon(Icons.calendar_today, size: 20),
                    label: Text('Thiết lập lịch ăn'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MoewColors.primary,
                      side: BorderSide(color: MoewColors.primary),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoewRadius.md)),
                    ),
                  ),
                ),
                if (!hasPets) ...[
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/add-pet'),
                      icon: Icon(Icons.pets, size: 20),
                      label: Text('Thêm thú cưng mới'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MoewColors.textSub,
                        side: BorderSide(color: MoewColors.border),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoewRadius.md)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    List<Map<String, dynamic>> morning = [];
    List<Map<String, dynamic>> noon = [];
    List<Map<String, dynamic>> evening = [];

    for (var m in timeline) {
      final meal = m as Map<String, dynamic>;
      final timeStr = meal['time']?.toString() ?? '';
      int hr = 12; // Default if parse fails
      if (timeStr.isNotEmpty) {
        final parts = timeStr.split(':');
        if (parts.isNotEmpty) hr = int.tryParse(parts[0]) ?? 12;
      }
      if (hr < 12) {
        morning.add(meal);
      } else if (hr < 17) {
        noon.add(meal);
      } else {
        evening.add(meal);
      }
    }

    int hr = DateTime.now().hour;
    int initialIndex = hr < 12 ? 0 : (hr < 17 ? 1 : 2);

    return DefaultTabController(
      length: 3,
      initialIndex: initialIndex,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: const AppHeader(title: 'Cho ăn hôm nay', showBack: false),
        body: Column(
          children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _buildHeader(),
          ),

          // Custom TabBar
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(MoewRadius.lg),
              boxShadow: MoewShadows.soft,
            ),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: MoewColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(MoewRadius.lg),
              ),
              labelPadding: EdgeInsets.zero,
              labelColor: MoewColors.primary,
              unselectedLabelColor: MoewColors.textSub,
              dividerColor: Colors.transparent,
              tabs: [
                _buildTab('Buổi sáng', morning),
                _buildTab('Buổi trưa', noon),
                _buildTab('Buổi tối', evening),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              children: [
                _buildMealList(morning, 'Buổi sáng (00:00 - 11:59)', '⛅'),
                _buildMealList(noon, 'Buổi trưa (12:00 - 16:59)', '☀️'),
                _buildMealList(evening, 'Buổi tối (17:00 - 23:59)', '🌙'),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildTab(String title, List<Map<String,dynamic>> meals) {
    bool hasUnfed = meals.any((m) => m['isFed'] != true);
    bool allFed = meals.isNotEmpty && meals.every((m) => m['isFed'] == true);
    
    return Tab(
      height: 48,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                title, 
                style: TextStyle(
                  fontSize: 13, 
                  fontWeight: FontWeight.w700,
                  color: allFed ? MoewColors.success : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasUnfed) ...[
              SizedBox(width: 4),
              Container(width: 6, height: 6, decoration: BoxDecoration(color: MoewColors.danger, shape: BoxShape.circle)),
            ],
            if (allFed) ...[
              SizedBox(width: 4),
              Icon(Icons.check_circle, size: 14, color: MoewColors.success),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMealList(List<Map<String,dynamic>> meals, String title, String iconStr) {
    if (meals.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(iconStr, style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('Trống lịch ăn $title', style: TextStyle(color: MoewColors.textSub, fontSize: 13)),
          ],
        )
      );
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: meals.length + 2, // 1 cho Header, 1 cho Quick Links ghim ở đáy
      itemBuilder: (ctx, i) {
        if (i == 0) {
           return Padding(
             padding: EdgeInsets.only(bottom: 12, left: 4),
             child: Row(
               children: [
                 Text(iconStr, style: TextStyle(fontSize: 16)),
                 SizedBox(width: 6),
                 Expanded(
                   child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: MoewColors.textMain), overflow: TextOverflow.ellipsis),
                 ),
               ],
             )
           );
        }
        if (i == meals.length + 1) {
           return Padding(
             padding: EdgeInsets.only(top: 16, bottom: 100), // <--- Spacer 100px nhường chỗ cho Tab Bar
             child: Column(
               children: [
                 Row(children: [
                   Expanded(child: _linkBtn('Kho thức ăn', Icons.inventory_2, '/food-products')),
                   SizedBox(width: 10),
                   Expanded(child: _linkBtn('Khẩu phần', Icons.pie_chart, '/feeding-plan')),
                 ]),
                 SizedBox(height: 8),
                 Row(children: [
                   Expanded(child: _linkBtn('Thống kê', Icons.bar_chart, '/nutrition-dashboard')),
                   SizedBox(width: 10),
                   Expanded(child: _linkBtn('Chuyển đổi', Icons.swap_horiz, '/food-transition')),
                 ]),
               ],
             ),
           );
        }
        return _buildMealCard(meals[i - 1]);
      },
    );
  }

  Widget _buildHeader() {
    final total = _data!['totalMeals'] ?? 0;
    final fed = _data!['fedCount'] ?? 0;
    final progress = total > 0 ? fed / total : 0.0;

    return Container(
      padding: EdgeInsets.all(MoewSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [MoewColors.primary.withValues(alpha: 0.08), MoewColors.success.withValues(alpha: 0.08)]),
        borderRadius: BorderRadius.circular(MoewRadius.lg),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          // Streak
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: MoewColors.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(MoewRadius.full)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('🔥', style: TextStyle(fontSize: 18)),
              SizedBox(width: 4),
              Text('$_streak ngày', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: MoewColors.warning)),
            ]),
          ),
          // Progress
          Text('$fed / $total bữa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: MoewColors.textMain)),
        ]),
        SizedBox(height: 12),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: MoewColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? MoewColors.success : MoewColors.primary),
          ),
        ),
        if (progress >= 1.0)
          Padding(padding: EdgeInsets.only(top: 8), child: Text('Tuyệt vời! Đã cho ăn đủ!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MoewColors.success))),
      ]),
    );
  }



  Widget _buildMealCard(Map<String, dynamic> meal) {
    final isFed = meal['isFed'] == true;
    final time = meal['time']?.toString() ?? '';
    final label = meal['label']?.toString() ?? '';
    final petName = meal['petName']?.toString() ?? '';
    final foodName = meal['foodName']?.toString() ?? '';
    final grams = meal['portionGrams'] ?? 0;
    final eatStatus = isFed ? meal['eatStatus']?.toString() : null;

    // Border color theo eatStatus
    Color borderColor = isFed ? MoewColors.success : MoewColors.warning;
    if (isFed && eatStatus != null) {
      borderColor = EatStatus.fromValue(eatStatus).color;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(MoewRadius.lg),
        boxShadow: MoewShadows.soft,
        border: Border(left: BorderSide(color: borderColor, width: 3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Row(children: [
          // Time badge
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: (isFed ? MoewColors.success : MoewColors.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(MoewRadius.md),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(time, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isFed ? MoewColors.success : MoewColors.primary)),
              Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: isFed ? MoewColors.success : MoewColors.textSub)),
            ]),
          ),
          SizedBox(width: 12),

          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.pets, size: 14, color: isFed ? MoewColors.success : MoewColors.textMain),
              SizedBox(width: 4),
              Expanded(
                child: Text(petName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isFed ? MoewColors.success : MoewColors.textMain), overflow: TextOverflow.ellipsis),
              ),
            ]),
            SizedBox(height: 2),
            Text('${grams}g $foodName', style: TextStyle(fontSize: 12, color: MoewColors.textSub)),
            if (isFed && meal['feedingNote'] != null)
              Padding(padding: EdgeInsets.only(top: 2), child: Text('"${meal['feedingNote']}"', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: MoewColors.textSub))),
          ])),

          // Status / Action
          if (isFed)
            Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: borderColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, size: 20, color: borderColor),
              ),
              if (eatStatus != null) ...[  
                SizedBox(height: 4),
                EatStatusBadge(eatStatus: eatStatus),
              ],
            ])
          else
            ElevatedButton(
              onPressed: () => _confirmMeal(meal),
              style: ElevatedButton.styleFrom(backgroundColor: MoewColors.primary, padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8), minimumSize: Size.zero),
              child: Text('Cho ăn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
        ]),
      ),
    );
  }

  Widget _linkBtn(String label, IconData icon, String route) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(MoewRadius.md), boxShadow: MoewShadows.soft),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: MoewColors.primary),
          SizedBox(width: 6),
          Flexible(
            child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MoewColors.textMain), overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
    );
  }
}
