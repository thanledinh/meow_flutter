import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../config/theme.dart';
import '../../widgets/moew_custom_icons.dart';
import '../../widgets/today_schedule_box.dart';
import '../../widgets/weight_chart.dart';
import '../../api/feeding_api.dart';
import '../../api/pet_api.dart';
import '../../api/api_client.dart';
import '../../models/pet_model.dart';
import '../../repositories/pet_repository.dart';
import '../../services/mqtt_service.dart';
import '../../widgets/toast.dart';

// ─────────────────────────────────────────────────────────────
// HomeScreen — Pet Dashboard (Pet-care first)
// ─────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedPetIdx = 0;
  StreamSubscription? _mqttSub;

  // Key để trigger refresh TodayScheduleBox từ pull-to-refresh
  final _scheduleKey = GlobalKey<TodayScheduleBoxState>();

  // Today's feeding data
  int _totalMeals = 0;
  int _fedCount = 0;
  List<Map<String, dynamic>> _timeline = [];
  bool _feedingLoading = true;
  bool _hasError = false;

  // Weekly insights
  int _streak = 0;
  List<dynamic> _weightChartHistory = [];
  String? _currentPetId;

  // Weekly stats
  List<double> _weeklyCompletion = [];
  int _weeklyFedTotal = 0;
  int _weeklyMealsTotal = 0;
  int _weeklyLateTotal = 0;
  bool _weeklyLoading = true;
  bool _weeklyError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PetRepository>().fetchPets();
      }
    });
    _listenMqtt();
    _loadFeedingData();
    _loadWeeklyData();
  }

  @override
  void dispose() {
    _mqttSub?.cancel();
    super.dispose();
  }

  void _listenMqtt() {
    _mqttSub = MqttService().messageStream.listen((data) {
      if (!mounted) return;
      final type = data['type'] as String?;
      if (type == 'feeding_reminder') {
        MoewToast.show(
          context,
          message: data['title']?.toString() ?? 'Đến giờ cho ăn rồi!',
          type: ToastType.info,
        );
        _loadFeedingData();
      }
    });
  }

  Future<void> _loadFeedingData() async {
    if (!mounted) return;
    setState(() {
      _feedingLoading = true;
      _hasError = false;
    });
    try {
      final results = await Future.wait([
        FeedingApi.getToday(),
        FeedingApi.getStreak(),
      ]);

      if (!mounted) return;

      final todayRes = results[0];
      final streakRes = results[1];

      if (todayRes.success) {
        final d = (todayRes.data as Map?)?['data'] as Map<String, dynamic>?;
        _totalMeals = d?['totalMeals'] as int? ?? 0;
        _fedCount = d?['fedCount'] as int? ?? 0;
        final tl = d?['timeline'] as List? ?? [];
        _timeline = tl.cast<Map<String, dynamic>>();
      } else {
        _hasError = true;
      }

      if (streakRes.success) {
        _streak = (streakRes.data as Map?)?['data']?['streak'] as int? ?? 0;
      }
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
    if (mounted) setState(() => _feedingLoading = false);
  }

  Future<void> _loadWeightData(String petId) async {
    try {
      final res = await PetApi.getWeightHistory(petId);
      if (!mounted) return;
      if (res.success) {
        final raw = res.data;
        final dataMap = (raw is Map)
            ? (raw['data'] is Map
                  ? raw['data'] as Map<String, dynamic>
                  : raw as Map<String, dynamic>)
            : null;
        if (mounted) {
          setState(() {
            _weightChartHistory = dataMap?['chart'] as List? ?? [];
          });
        }
      }
    } catch (e) {
      print('Failed to load weight on Home: $e');
    }
  }

  Future<void> _loadWeeklyData({String? petId}) async {
    if (!mounted) return;
    setState(() {
      _weeklyLoading = true;
      _weeklyError = false;
    });
    try {
      final res = await FeedingApi.getWeekly(petId: petId);
      if (!mounted) return;
      if (res.success) {
        final d = (res.data as Map?)?['data'] as Map<String, dynamic>?;
        final days = d?['days'] as List? ?? [];
        final summary = d?['summary'] as Map? ?? {};
        final completion = days.map<double>((day) {
          final total = (day['totalMeals'] as int? ?? 0);
          final fed = (day['fedCount'] as int? ?? 0);
          return total > 0 ? (fed / total).clamp(0.0, 1.0) : 0.0;
        }).toList();
        setState(() {
          _weeklyCompletion = completion;
          _weeklyFedTotal = summary['totalFed'] as int? ?? 0;
          _weeklyMealsTotal = summary['totalMeals'] as int? ?? 0;
          _weeklyLateTotal = summary['totalLate'] as int? ?? 0;
        });
      } else {
        if (mounted) setState(() => _weeklyError = true);
      }
    } catch (_) {
      if (mounted) setState(() => _weeklyError = true);
    }
    if (mounted) setState(() => _weeklyLoading = false);
  }

  void scrollToTop() {}

  @override
  Widget build(BuildContext context) {
    final petRepo = context.watch<PetRepository>();
    final pets = petRepo.pets;
    final hasPets = pets.isNotEmpty;

    if (hasPets && _selectedPetIdx >= pets.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedPetIdx = 0);
      });
    }

    final selectedPet = hasPets && _selectedPetIdx < pets.length
        ? pets[_selectedPetIdx]
        : null;

    if (selectedPet != null && selectedPet.id != _currentPetId) {
      _currentPetId = selectedPet.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadWeightData(selectedPet.id);
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          color: MoewColors.primary,
          onRefresh: () async {
            await Future.wait([
              context.read<PetRepository>().refreshPets(),
              _loadFeedingData(),
              _loadWeeklyData(petId: selectedPet?.id),
              _scheduleKey.currentState?.refresh() ?? Future.value(),
            ]);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Header ────────────────────────────────────────
              SliverToBoxAdapter(
                child: _buildHeader(context, pets, selectedPet),
              ),
              // ── Body ──────────────────────────────────────────
              SliverToBoxAdapter(
                child: hasPets
                    ? _buildDashboard(context, selectedPet)
                    : _buildEmptyState(context),
              ),
              // Padding cuối cho bottom nav
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header: Pet Switcher ──────────────────────────────────────
  Widget _buildHeader(
    BuildContext context,
    List<PetModel> pets,
    PetModel? selected,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          // Avatar — circular clip, no background
          _buildPetAvatarPlain(selected, radius: 28),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selected?.name ?? 'Moew',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: MoewColors.textMain,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _petSubtitle(selected),
                  style: TextStyle(
                    fontSize: 12,
                    color: MoewColors.textSub,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Switch / Add pet chip
          if (pets.length > 1)
            GestureDetector(
              onTap: () => _showPetSwitcher(context, pets),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: MoewColors.surface,
                  borderRadius: BorderRadius.circular(MoewRadius.full),
                  border: Border.all(color: MoewColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Đổi pet',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: MoewColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.swap_horiz_rounded,
                      size: 16,
                      color: MoewColors.primary,
                    ),
                  ],
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => context.push('/add-pet'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: MoewColors.surface,
                  borderRadius: BorderRadius.circular(MoewRadius.full),
                  border: Border.all(color: MoewColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: MoewColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Thêm pet',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: MoewColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Dashboard (has pets) ─────────────────────────────────────
  Widget _buildDashboard(BuildContext context, PetModel? pet) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          TodayScheduleBox(key: _scheduleKey),
          const SizedBox(height: 16),
          _buildQuickActions(context, pet),
          const SizedBox(height: 16),
          _buildTodayInsights(context, pet),
          const SizedBox(height: 16),
          _buildWeeklyStats(context, pet),
        ],
      ),
    );
  }

  // ── Quick Actions 2x3 ────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context, PetModel? pet) {
    final actions = [
      _QuickAction(
        svgData: MoewCustomIcons.feed,
        label: 'Cho ăn',
        color: const Color(0xFF10B981),
        route: '/feeding-today',
      ),
      _QuickAction(
        svgData: MoewCustomIcons.weight,
        label: 'Cân nặng',
        color: const Color(0xFF3B82F6),
        route: '/pet-weight',
        extra: pet?.id,
      ),
      _QuickAction(
        svgData: MoewCustomIcons.medical,
        label: 'Y tế',
        color: const Color(0xFFF59E0B),
        route: '/medical',
        extra: pet?.id,
      ),
      _QuickAction(
        svgData: MoewCustomIcons.vet,
        label: 'Lịch khám',
        color: const Color(0xFF8B5CF6),
        route: '/clinic-list',
      ),
      _QuickAction(
        svgData: MoewCustomIcons.ai,
        label: 'AI',
        color: const Color(0xFF06B6D4),
        route: '/food-analysis',
      ),
      _QuickAction(
        svgData: MoewCustomIcons.sos,
        label: 'SOS',
        color: MoewColors.danger,
        route: '/sos',
        isDanger: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thao tác nhanh',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: MoewColors.textMain,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          itemCount: actions.length,
          itemBuilder: (ctx, i) => _buildActionCell(ctx, actions[i], pet),
        ),
      ],
    );
  }

  Widget _buildActionCell(
    BuildContext context,
    _QuickAction action,
    PetModel? pet,
  ) {
    return GestureDetector(
      onTap: () {
        // Cần petId
        if (action.route == '/pet-weight' || action.route == '/medical') {
          if (pet != null) {
            context.push(action.route, extra: pet.id);
          } else {
            MoewToast.show(
              context,
              message: 'Vui lòng chọn thú cưng',
              type: ToastType.warning,
            );
          }
        } else if (action.route == '/food-analysis' && pet != null) {
          context.push(
            action.route,
            extra: {'petId': pet.id, 'petName': pet.name},
          );
        } else {
          context.push(action.route);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: MoewColors.white,
          borderRadius: BorderRadius.circular(MoewRadius.lg),
          boxShadow: MoewShadows.card,
          border: action.isDanger
              ? Border.all(
                  color: MoewColors.danger.withValues(alpha: 0.25),
                  width: 1.5,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.string(action.svgData, width: 24, height: 24),
            ),
            const SizedBox(height: 7),
            Text(
              action.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: action.isDanger
                    ? MoewColors.danger
                    : MoewColors.textMain,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Thống kê Hôm nay ─────────────────────────────────────────
  Widget _buildTodayInsights(BuildContext context, PetModel? pet) {
    if (_feedingLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hôm nay',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: MoewColors.textMain,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: MoewColors.white,
              borderRadius: BorderRadius.circular(MoewRadius.xl),
              boxShadow: MoewShadows.card,
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_hasError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hôm nay',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: MoewColors.textMain,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: MoewColors.white,
              borderRadius: BorderRadius.circular(MoewRadius.xl),
              boxShadow: MoewShadows.card,
            ),
            child: _buildErrorRow(onRetry: _loadFeedingData),
          ),
        ],
      );
    }

    final pending = max(0, _totalMeals - _fedCount);
    final hasMeals = _totalMeals > 0;
    final pct = hasMeals ? (_fedCount / _totalMeals * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hôm nay',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: MoewColors.textMain,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: MoewColors.white,
            borderRadius: BorderRadius.circular(MoewRadius.xl),
            boxShadow: MoewShadows.card,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildInsightStat(
                      Icons.local_fire_department_rounded,
                      '$_streak',
                      'Streak',
                      MoewColors.secondary,
                    ),
                  ),
                  _buildDividerV(),
                  Expanded(
                    child: _buildInsightStat(
                      Icons.restaurant_rounded,
                      '$pct%',
                      'Ăn đúng giờ',
                      MoewColors.success,
                    ),
                  ),
                  _buildDividerV(),
                  Expanded(
                    child: _buildInsightStat(
                      Icons.schedule_rounded,
                      '$pending',
                      'Còn thiếu',
                      MoewColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/nutrition-dashboard'),
                      icon: const Icon(Icons.bar_chart_rounded, size: 16),
                      label: const Text(
                        'Xem chi tiết',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MoewColors.primary,
                        side: BorderSide(color: MoewColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(MoewRadius.md),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (pet != null) {
                          context.push('/pet-vaccines', extra: pet.id);
                        } else {
                          MoewToast.show(
                            context,
                            message: 'Vui lòng chọn thú cưng',
                            type: ToastType.warning,
                          );
                        }
                      },
                      icon: const Icon(Icons.vaccines_rounded, size: 16),
                      label: const Text(
                        'Vaccine',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: MoewColors.info,
                        side: BorderSide(
                          color: MoewColors.info.withValues(alpha: 0.35),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(MoewRadius.md),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/expenses'),
                  icon: const Icon(Icons.receipt_long_rounded, size: 18),
                  label: const Text(
                    'Quản lý chi tiêu',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MoewColors.warning,
                    side: BorderSide(
                      color: MoewColors.warning.withValues(alpha: 0.35),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MoewRadius.md),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (_weightChartHistory.isNotEmpty) ...[
                const SizedBox(height: 16),
                WeightChartBox(
                  chartData: _weightChartHistory,
                  height: 60,
                  showTitle: false,
                  padding: const EdgeInsets.all(0),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Tổng quan tuần (data thật từ /feeding/weekly) ─────────────
  Widget _buildWeeklyStats(BuildContext context, PetModel? pet) {
    final dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    if (_weeklyLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng quan tuần',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: MoewColors.textMain,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: MoewColors.white,
              borderRadius: BorderRadius.circular(MoewRadius.xl),
              boxShadow: MoewShadows.card,
            ),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (_weeklyError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tổng quan tuần',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: MoewColors.textMain,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: MoewColors.white,
              borderRadius: BorderRadius.circular(MoewRadius.xl),
              boxShadow: MoewShadows.card,
            ),
            child: _buildErrorRow(
              onRetry: () => _loadWeeklyData(petId: pet?.id),
            ),
          ),
        ],
      );
    }

    final hasData = _weeklyCompletion.isNotEmpty && _weeklyMealsTotal > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tổng quan tuần',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: MoewColors.textMain,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: MoewColors.white,
            borderRadius: BorderRadius.circular(MoewRadius.xl),
            boxShadow: MoewShadows.card,
          ),
          child: !hasData
              ? _buildWeeklyEmpty()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildInsightStat(
                            Icons.check_circle_outline_rounded,
                            '$_weeklyFedTotal/$_weeklyMealsTotal',
                            'Bữa đã ăn',
                            MoewColors.success,
                          ),
                        ),
                        _buildDividerV(),
                        Expanded(
                          child: _buildInsightStat(
                            Icons.timer_off_outlined,
                            '$_weeklyLateTotal',
                            'Trễ giờ',
                            MoewColors.warning,
                          ),
                        ),
                        _buildDividerV(),
                        Expanded(
                          child: _buildInsightStat(
                            Icons.percent_rounded,
                            _weeklyMealsTotal > 0
                                ? '${(_weeklyFedTotal / _weeklyMealsTotal * 100).round()}%'
                                : '0%',
                            'Hoàn thành',
                            MoewColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Bar chart 7 ngày
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (i) {
                        final pct = i < _weeklyCompletion.length
                            ? _weeklyCompletion[i]
                            : 0.0;
                        final isToday = i == (DateTime.now().weekday - 1) % 7;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                AnimatedContainer(
                                  duration: Duration(
                                    milliseconds: 300 + i * 40,
                                  ),
                                  curve: Curves.easeOut,
                                  height: 60 * pct + (pct > 0 ? 4 : 2),
                                  decoration: BoxDecoration(
                                    color: pct >= 1.0
                                        ? MoewColors.success
                                        : pct > 0
                                        ? MoewColors.primary.withValues(
                                            alpha: 0.65,
                                          )
                                        : MoewColors.border,
                                    borderRadius: BorderRadius.circular(4),
                                    border: isToday
                                        ? Border.all(
                                            color: MoewColors.primary,
                                            width: 1.5,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dayLabels[i],
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isToday
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    color: isToday
                                        ? MoewColors.primary
                                        : MoewColors.textSub,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildWeeklyEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.bar_chart_outlined, color: MoewColors.border, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chưa đủ dữ liệu tuần',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: MoewColors.textSub,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hãy thiết lập lịch cho ăn và ghi nhận đều đặn để xem biểu đồ tuần.',
                  style: TextStyle(fontSize: 11, color: MoewColors.textSub),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightStat(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: MoewColors.textMain,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: MoewColors.textSub,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDividerV() {
    return Container(
      width: 1,
      height: 48,
      color: MoewColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  // ── Empty State (No pets) ─────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: MoewColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.pets_rounded, size: 44, color: MoewColors.accent),
          ),
          const SizedBox(height: 20),
          Text(
            'Bắt đầu chăm thú cưng!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: MoewColors.textMain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thêm thú cưng để xem lịch ăn, theo dõi sức khỏe và nhận nhắc nhở mỗi ngày.',
            style: TextStyle(
              fontSize: 14,
              color: MoewColors.textSub,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/add-pet'),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Thêm thú cưng ngay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MoewColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MoewRadius.lg),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Checklist steps
          _buildEmptyChecklist(),
        ],
      ),
    );
  }

  Widget _buildEmptyChecklist() {
    final steps = [
      (Icons.add_circle_outline_rounded, 'Thêm thú cưng đầu tiên', false),
      (Icons.restaurant_outlined, 'Thiết lập lịch cho ăn', true),
      (Icons.monitor_weight_outlined, 'Ghi nhận cân nặng', true),
    ];
    return Column(
      children: steps
          .map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    s.$2.startsWith('Thêm')
                        ? Icons.radio_button_off_rounded
                        : Icons.lock_outline_rounded,
                    size: 20,
                    color: s.$3 ? MoewColors.border : MoewColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      s.$2,
                      style: TextStyle(
                        fontSize: 14,
                        color: s.$3 ? MoewColors.textSub : MoewColors.textMain,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ── Error row ────────────────────────────────────────────────
  Widget _buildErrorRow({required VoidCallback onRetry}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: MoewColors.textSub, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Không tải được dữ liệu',
              style: TextStyle(fontSize: 13, color: MoewColors.textSub),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Thử lại',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: MoewColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Pet Switcher Bottom Sheet ─────────────────────────────────
  void _showPetSwitcher(BuildContext context, List<PetModel> pets) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MoewColors.white,
          borderRadius: BorderRadius.circular(MoewRadius.xl),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MoewColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Chọn thú cưng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: MoewColors.textMain,
                ),
              ),
              const SizedBox(height: 12),
              ...pets.asMap().entries.map((e) {
                final isSelected = e.key == _selectedPetIdx;
                return ListTile(
                  leading: _buildPetAvatar(e.value, radius: 22),
                  title: Text(
                    e.value.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: MoewColors.textMain,
                    ),
                  ),
                  subtitle: Text(
                    _petSubtitle(e.value),
                    style: TextStyle(fontSize: 12, color: MoewColors.textSub),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: MoewColors.primary,
                        )
                      : null,
                  onTap: () {
                    setState(() => _selectedPetIdx = e.key);
                    Navigator.pop(context);
                    _loadFeedingData();
                  },
                );
              }),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/add-pet');
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Thêm thú cưng mới'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: MoewColors.primary,
                      side: BorderSide(color: MoewColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(MoewRadius.lg),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────
  Widget _buildPetAvatar(PetModel? pet, {required double radius}) {
    final url = pet?.avatarUrl;
    final imgUrl = url != null
        ? (url.startsWith('http') ? url : ApiConfig.parseImageUrl(url))
        : null;
    if (imgUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: CachedNetworkImage(
          imageUrl: imgUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorWidget: (_, __, _) => _petAvatarFallback(radius),
        ),
      );
    }
    return _petAvatarFallback(radius);
  }

  Widget _petAvatarFallback(double radius) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: MoewColors.surface,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.pets_rounded,
        size: radius * 0.8,
        color: MoewColors.primary,
      ),
    );
  }

  // Plain avatar for header on white background — primary border ring, no glow
  Widget _buildPetAvatarPlain(PetModel? pet, {required double radius}) {
    final url = pet?.avatarUrl;
    final imgUrl = url != null
        ? (url.startsWith('http') ? url : ApiConfig.parseImageUrl(url))
        : null;

    Widget inner;
    if (imgUrl != null) {
      inner = ClipOval(
        child: CachedNetworkImage(
          imageUrl: imgUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorWidget: (_, __, _) => _petAvatarFallback(radius),
        ),
      );
    } else {
      inner = _petAvatarFallback(radius);
    }

    // Thin primary-colored border ring on white bg
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: MoewColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: MoewColors.primary.withValues(alpha: 0.15),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: inner,
    );
  }

  String _petSubtitle(PetModel? pet) {
    if (pet == null) return '';
    final parts = <String>[];
    if (pet.breed != null && pet.breed!.isNotEmpty) parts.add(pet.breed!);
    if (pet.birthDate != null) {
      final age = DateTime.now().year - pet.birthDate!.year;
      parts.add('$age tuổi');
    }
    if (pet.weight != null) parts.add('${pet.weight!.toStringAsFixed(1)} kg');
    return parts.join(' · ');
  }

  String _formatTime(String raw) {
    try {
      final dt = DateTime.tryParse(raw);
      if (dt != null)
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      if (raw.contains(':')) return raw.substring(0, 5);
    } catch (_) {}
    return raw;
  }
}

// ── Data class ───────────────────────────────────────────────
class _QuickAction {
  final String svgData;
  final String label;
  final Color color;
  final String route;
  final dynamic extra;
  final bool isDanger;

  const _QuickAction({
    required this.svgData,
    required this.label,
    required this.color,
    required this.route,
    this.extra,
    this.isDanger = false,
  });
}
