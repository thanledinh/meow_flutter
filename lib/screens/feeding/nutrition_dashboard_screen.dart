import 'package:flutter/material.dart';

import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';
import '../../config/theme.dart';
import '../../api/feeding_api.dart';
import '../../api/pet_api.dart';
import '../../api/api_client.dart';
import '../../widgets/common_widgets.dart';

// ─── Food Type Enum ────────────────────────────────────────────────────────
enum FoodType { dry, wet, home, none, future }

// ─── Day Cell Data ─────────────────────────────────────────────────────────
class _DayData {
  final int day;
  final FoodType type;
  final int calories;
  _DayData({required this.day, required this.type, this.calories = 0});
}

class NutritionDashboardScreen extends StatefulWidget {
  const NutritionDashboardScreen({super.key});
  @override
  State<NutritionDashboardScreen> createState() => _NutritionDashboardScreenState();
}

class _NutritionDashboardScreenState extends State<NutritionDashboardScreen>
    with TickerProviderStateMixin {
  List<dynamic> _pets = [];
  dynamic _selectedPetId;
  Map<String, dynamic>? _stats;
  List<_DayData> _days = [];
  bool _loading = true;
  DateTime _currentMonth = DateTime.now();

  // staggered animation controllers per cell
  late List<AnimationController> _cellControllers;
  late List<Animation<double>> _cellAnims;

  @override
  void initState() {
    super.initState();
    _cellControllers = [];
    _cellAnims = [];
    _init();
  }

  @override
  void dispose() {
    for (final c in _cellControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _buildCellAnimations(int count) {
    for (final c in _cellControllers) {
      c.dispose();
    }
    _cellControllers = List.generate(count, (_) {
      return AnimationController(
          vsync: this, duration: const Duration(milliseconds: 380));
    });
    _cellAnims = _cellControllers.map((c) {
      return CurvedAnimation(parent: c, curve: Curves.elasticOut);
    }).toList();
    // stagger
    for (int i = 0; i < _cellControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 30 * i), () {
        if (mounted) _cellControllers[i].forward();
      });
    }
  }

  Future<void> _init() async {
    final petRes = await PetApi.getAll();
    if (!mounted) return;
    final pets = ((petRes.data is Map ? petRes.data['data'] : petRes.data) as List?) ?? [];
    setState(() {
      _pets = pets;
      if (pets.isNotEmpty) _selectedPetId = pets.first['id'];
    });
    if (_selectedPetId != null) await _fetchData();
    else setState(() => _loading = false);
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      FeedingApi.getNutritionStats(_selectedPetId),
      FeedingApi.getFeedingHistory(petId: _selectedPetId, limit: 100),
    ]);
    if (!mounted) return;
    final rawStats = results[0].data;
    final rawHistory = results[1].data;

    final statsMap = (rawStats is Map<String, dynamic>)
        ? (rawStats['data'] is Map ? rawStats['data'] as Map<String, dynamic> : rawStats)
        : <String, dynamic>{};

    final historyList = _extractList(rawHistory);
    final dayDataList = _buildDayGrid(historyList);

    setState(() {
      _stats = statsMap;
      _days = dayDataList;
      _loading = false;
    });
    _buildCellAnimations(dayDataList.length);
  }

  List<dynamic> _extractList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      // Format: {"data": {"history": [...]}}
      final data = raw['data'];
      if (data is Map && data['history'] is List) return data['history'] as List;
      if (data is List) return data;
      if (raw['history'] is List) return raw['history'] as List;
      if (raw['records'] is List) return raw['records'] as List;
    }
    return [];
  }

  List<_DayData> _buildDayGrid(List<dynamic> history) {
    final now = DateTime.now();
    final totalDays = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final isCurrentMonth =
        _currentMonth.year == now.year && _currentMonth.month == now.month;
    final currentDay = isCurrentMonth ? now.day : totalDays;

    // Map date string → FoodType từ API history
    // Format: [{date: "2026-04-01", items: [{productType, calories, ...}]}]
    final Map<String, FoodType> fedMap = {};
    final Map<String, int> calsMap = {};
    for (final item in history) {
      if (item is! Map) continue;
      final dateStr = item['date']?.toString() ?? '';
      if (dateStr.isEmpty) continue;
      try {
        final d = DateTime.parse(dateStr);
        if (d.year == _currentMonth.year && d.month == _currentMonth.month) {
          final key = '${d.day}';
          // Lấy từ items array nếu có
          final items = item['items'];
          if (items is List && items.isNotEmpty) {
            fedMap[key] = _detectType(items.first as Map);
            for (final sub in items) {
              if (sub is Map) {
                calsMap[key] = (calsMap[key] ?? 0) + ((sub['calories'] as num?)?.toInt() ?? 0);
              }
            }
          } else {
            fedMap[key] = _detectType(item);
            calsMap[key] = (calsMap[key] ?? 0) + ((item['calories'] as num?)?.toInt() ?? 0);
          }
        }
      } catch (_) {}
    }

    // ── MOCK DATA TEST (xóa khi lên production) ─────────────────
    {
      const mockPattern = [
        FoodType.dry,  FoodType.wet,  FoodType.home, FoodType.dry,  FoodType.wet,
        FoodType.dry,  FoodType.none, FoodType.home, FoodType.dry,  FoodType.wet,
        FoodType.wet,  FoodType.dry,  FoodType.home, FoodType.dry,  FoodType.wet,
      ];
      for (var i = 0; i < mockPattern.length && i < totalDays; i++) {
        fedMap['${i + 1}'] = mockPattern[i];
        calsMap['${i + 1}'] = 200 + (i * 23 % 150);
      }
    }
    // ─────────────────────────────────────────────────────────────

    return List.generate(totalDays, (i) {
      final day = i + 1;
      final key = '$day';
      if (day > currentDay) {
        return _DayData(day: day, type: FoodType.future);
      }
      return _DayData(
        day: day,
        type: fedMap[key] ?? FoodType.none,
        calories: calsMap[key] ?? 0,
      );
    });
  }

  FoodType _detectType(Map item) {
    final name = (item['productName'] ?? item['food'] ?? item['type'] ?? '').toString().toLowerCase();
    if (name.contains('pate') || name.contains('wet') || name.contains('ướt')) return FoodType.wet;
    if (name.contains('hạt') || name.contains('dry') || name.contains('kibble')) return FoodType.dry;
    if (name.contains('nấu') || name.contains('home') || name.contains('tự')) return FoodType.home;
    // fallback by calories
    return FoodType.dry;
  }



  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buổi sáng,\n☀️ Good morning,';
    if (h < 14) return 'Buổi trưa,\n🌤 Good afternoon,';
    if (h < 18) return 'Buổi chiều,\n🌥 Good afternoon,';
    return 'Tối rồi nè,\n🌙 Good evening,';
  }

  Map<String, dynamic>? get _selectedPet =>
      _pets.isEmpty ? null : _pets.firstWhere(
        (p) => p['id'] == _selectedPetId,
        orElse: () => _pets.first,
      ) as Map<String, dynamic>?;

  String _petAge(Map<String, dynamic> pet) {
    var dob = pet['dateOfBirth'] ?? pet['dob'] ?? pet['birthDate'] ?? pet['birthday'] ?? pet['date_of_birth'];
    if (dob == null) return '';
    try {
      final birth = DateTime.parse(dob.toString());
      final now = DateTime.now();
      final months = (now.year - birth.year) * 12 + now.month - birth.month;
      if (months < 12) return '$months tháng tuổi';
      final years = (months / 12).toStringAsFixed(1);
      return '$years năm tuổi';
    } catch (_) { return ''; }
  }

  void _showPetPicker() {
    if (_pets.length <= 1) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const Text('Chọn thú cưng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            ..._pets.map<Widget>((p) {
              final active = _selectedPetId == p['id'];
              var avatarRawStr = (p['avatar'] ?? p['avatarUrl'] ?? p['photoUrl'])?.toString() ?? '';
              final avatarUrl = ApiConfig.parseImageUrl(avatarRawStr);
              final avatar = avatarUrl.isNotEmpty ? avatarUrl : null;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedPetId = p['id']);
                  _fetchData();
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: active ? MoewColors.primary.withValues(alpha: 0.08) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: active ? MoewColors.primary : Colors.transparent, width: 1.5),
                  ),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: MoewColors.primary.withValues(alpha: 0.15),
                      backgroundImage: avatar != null ? NetworkImage(avatar.toString()) : null,
                      child: avatar == null ? const Text('🐱', style: TextStyle(fontSize: 18)) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(p['name'] ?? '',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                            color: active ? MoewColors.primary : MoewColors.textBody))),
                    if (active) Icon(Icons.check_circle_rounded, color: MoewColors.primary),
                  ]),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF4F0),
      appBar: _buildAppBar(),
      body: _pets.isEmpty && !_loading
          ? EmptyState(icon: Icons.bar_chart, color: MoewColors.primary, message: 'Chưa có thú cưng')
          : _loading ? _buildShimmer() : _buildBentoBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final pet = _selectedPet;
    final petName = pet?['name'] ?? '...';
    var avatarRawStr = (pet?['avatar'] ?? pet?['avatarUrl'] ?? pet?['photoUrl'])?.toString() ?? '';
    final avatarUrl = ApiConfig.parseImageUrl(avatarRawStr);
    final avatar = avatarUrl.isNotEmpty ? avatarUrl : null;
    final age = pet != null ? _petAge(pet) : '';

    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF0E8), Color(0xFFFFEBF5), Color(0xFFEBF3FF)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // ── Bên trái: icon paw + greeting ──
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pets_rounded, color: Color(0xFFFF8A65), size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_greeting.split('\n').last,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                      Text(petName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
                              color: Color(0xFF2D2D2D))),
                    ],
                  ),
                ),
                // ── Bên phải: avatar + tên + tuổi + Menu ──
                Row(mainAxisSize: MainAxisSize.min, children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: MoewColors.primary.withValues(alpha: 0.15),
                    backgroundImage: avatar != null ? NetworkImage(avatar.toString()) : null,
                    child: avatar == null ? const Text('🐱', style: TextStyle(fontSize: 18)) : null,
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(petName,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF2D2D2D))),
                      if (age.isNotEmpty)
                        Text(age, style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // ── Nút Menu ──
                  GestureDetector(
                    onTap: _showPetPicker,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_rounded, size: 20,
                            color: _pets.length > 1 ? MoewColors.primary : Colors.grey.shade400),
                        Text('Menu', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                            color: _pets.length > 1 ? MoewColors.primary : Colors.grey.shade400)),
                      ],
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Container(margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24))),
    );
  }

  Widget _buildBentoBody() {
    final streak = (_stats?['streak'] ?? _stats?['streakDays'] ?? 0) as num;
    final today = (_stats?['today'] as Map<String, dynamic>?) ?? {};
    final cals = (today['calories'] ?? 0) as num;
    final target = (_stats?['target'] as Map<String, dynamic>?) ?? {};
    final targetCals = (target['dailyCalories'] ?? 300) as num;

    // Count fed days this month
    final fedDays = _days.where((d) => d.type != FoodType.none && d.type != FoodType.future).length;
    final totalPast = _days.where((d) => d.type != FoodType.future).length;
    final completionPct = totalPast > 0 ? (fedDays / totalPast * 100).round() : 0;

    final dryCount = _days.where((d) => d.type == FoodType.dry).length;
    final wetCount = _days.where((d) => d.type == FoodType.wet).length;
    final homeCount = _days.where((d) => d.type == FoodType.home).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      child: Column(
        children: [
          // Mèo Mascot
          _buildCatHeader(streak.toInt(), cals.toInt()),
          const SizedBox(height: 8),

          // Nội dung chính: Grid, Legend, Stats
          _buildBentoGrid(),
          const SizedBox(height: 16),
          _buildLegend(),
          const SizedBox(height: 16),
          _buildStatsRow(streak.toInt(), cals.toInt(), targetCals.toInt(), completionPct,
              fedDays, dryCount, wetCount, homeCount),
        ],
      ),
    );
  }

  Widget _buildCatHeader(int streak, int cals) {
    final isHappy = streak >= 3 && cals > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (streak > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.deepOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('🔥', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text('$streak ngày',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.deepOrange)),
            ]),
          ),
          const SizedBox(width: 12),
        ],
        ColorFiltered(
          colorFilter: const ColorFilter.mode(Color(0xFFF4F7F6), BlendMode.multiply),
          child: Lottie.asset(
            'assets/animations/Cat-is-sleeping-and-rolling.json',
            width: 120, // Giảm bớt chút xíu để không quá dội
            height: 120,
            fit: BoxFit.contain,
          ),
        ),
        if (streak > 0) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: MoewColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('✨', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(isHappy ? 'Hạnh phúc' : 'Ổn định',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: MoewColors.primary)),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _buildBentoGrid() {
    const columns = 5;
    final rows = (_days.length / columns).ceil();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // 4 góc 4 màu gradient
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE5D0), // cam nhạt góc trên trái
            Color(0xFFFFF5D6), // vàng nhạt góc trên phải
            Color(0xFFFFE8F0), // hồng nhạt góc dưới trái
            Color(0xFFE8F5E8), // xanh lá nhạt góc dưới phải
          ],
          stops: [0.0, 0.35, 0.65, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFD4A9A0).withValues(alpha: 0.35),
              blurRadius: 24, offset: const Offset(0, 8)),
          const BoxShadow(
              color: Colors.white,
              blurRadius: 8, offset: Offset(-4, -4)),
        ],
      ),
      child: Column(
        children: List.generate(rows, (row) {
          return Row(
            children: List.generate(columns, (col) {
              final index = row * columns + col;
              if (index >= _days.length) {
                return const Expanded(child: SizedBox());
              }
              final dayData = _days[index];
              final anim = index < _cellAnims.length
                  ? _cellAnims[index]
                  : const AlwaysStoppedAnimation(1.0);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: ScaleTransition(
                    scale: anim,
                    child: _BentoCell(data: dayData),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: const Color(0xFFB5835A), label: 'Hạt'),
        const SizedBox(width: 14),
        _LegendDot(color: const Color(0xFFEFB429), label: 'Pate'),
        const SizedBox(width: 14),
        _LegendDot(color: const Color(0xFFE98A8A), label: 'Tự nấu'),
        const SizedBox(width: 14),
        _LegendDot(color: Colors.grey.shade300, label: 'Chưa ăn'),
      ],
    );
  }

  Widget _buildStatsRow(int streak, int cals, int targetCals, int pct,
      int fedDays, int dry, int wet, int home) {
    return Row(children: [
      Expanded(child: _StatCard(
        emoji: '🗓️',
        value: '$fedDays/${_days.length}',
        label: 'Ngày đã ăn',
        color: MoewColors.primary,
      )),
      const SizedBox(width: 10),
      Expanded(child: _StatCard(
        emoji: '⚡',
        value: '${pct}%',
        label: 'Hoàn thành',
        color: Colors.amber.shade700,
      )),
      const SizedBox(width: 10),
      Expanded(child: _StatCard(
        emoji: '🌾',
        value: '$dry ng · $wet pa · $home nấu',
        label: 'Phân loại',
        color: Colors.green.shade600,
        small: true,
      )),
    ]);
  }
}

// ════════════════════════════════════════════════════════
//  Bento Cell Widget
// ════════════════════════════════════════════════════════
class _BentoCell extends StatelessWidget {
  final _DayData data;
  const _BentoCell({required this.data});

  static const _assetMap = {
    FoodType.dry: 'assets/room/icon_dry_food.png',
    FoodType.wet: 'assets/room/icon_wet_food.png',
    FoodType.home: 'assets/room/icon_home_food.png',
  };

  static const _dotMap = {
    FoodType.dry: Color(0xFFB5835A),
    FoodType.wet: Color(0xFFEFB429),
    FoodType.home: Color(0xFFE98A8A),
    FoodType.none: Color(0xFFD0D0D0),
    FoodType.future: Color(0xFFE8E8E8),
  };

  @override
  Widget build(BuildContext context) {
    final dot = _dotMap[data.type]!;
    final isFuture = data.type == FoodType.future;
    final isEmpty = data.type == FoodType.none;
    final assetPath = _assetMap[data.type];
    final isFed = !isFuture && !isEmpty;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          // Ô trống thêm border tạo cảm giác lõm (viền trong)
          border: isFed
              ? null
              : Border.all(
                  color: Colors.black.withValues(alpha: 0.08),
                  width: 1.5,
                ),
          boxShadow: isFed
              // NỔI: shadow màu theo loại đồ ăn
              ? [
                  BoxShadow(
                      color: dot.withValues(alpha: 0.35),
                      blurRadius: 8, offset: const Offset(0, 5)),
                  const BoxShadow(
                      color: Colors.white,
                      blurRadius: 3, offset: Offset(-2, -2)),
                ]
              // LÕM: shadow tối góc phải/dưới, sáng góc trái/đầu
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 5, spreadRadius: -2,
                      offset: const Offset(3, 3)),
                  const BoxShadow(
                      color: Colors.white,
                      blurRadius: 5, spreadRadius: -2,
                      offset: Offset(-2, -2)),
                ],
        ),
        child: isFed
            // ── ÔI ĐÃ ĂN: ảnh full ô, số ngày overlay góc trên trái ──
            ? Stack(children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Image.asset(
                        assetPath!,
                        fit: BoxFit.contain,
                        colorBlendMode: BlendMode.multiply,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 4, left: 5,
                  child: Text(
                    '${data.day}',
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: dot.withValues(alpha: 0.75),
                        shadows: [
                          Shadow(color: Colors.white.withValues(alpha: 0.9),
                              blurRadius: 4),
                        ]),
                  ),
                ),
              ])
            // ── Ô TRỐNG/TƯƠNG LAI: icon mờ + số ngày ở dưới ──
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Icon(
                        Icons.set_meal_outlined,
                        size: 20,
                        color: isFuture
                            ? Colors.grey.shade300
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${data.day}',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade400),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════
//  Helper Widgets
// ════════════════════════════════════════════════════════
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: MoewColors.textSub)),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;
  final bool small;
  const _StatCard({required this.emoji, required this.value, required this.label, required this.color, this.small = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: MoewShadows.soft,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: small ? 10 : 16,
                fontWeight: FontWeight.w900,
                color: color)),
        Text(label,
            style: TextStyle(fontSize: 10, color: MoewColors.textSub, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
