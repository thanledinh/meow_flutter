import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Enum trạng thái ăn của thú cưng
enum EatStatus {
  ateAll('ate_all', '✅ Ăn hết', Color(0xFF10b981)),
  ateHalf('ate_half', '🟡 Ăn khoảng 50%', Color(0xFFf59e0b)),
  ateLittle('ate_little', '⚠️ Ăn rất ít', Color(0xFFf97316)),
  ateNone('ate_none', '🔴 Bỏ ăn hoàn toàn', Color(0xFFef4444));

  const EatStatus(this.value, this.label, this.color);
  final String value;
  final String label;
  final Color color;

  static EatStatus fromValue(String value) {
    return EatStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EatStatus.ateAll,
    );
  }

  bool get showHint => this == ateLittle || this == ateNone;
}

/// Widget bộ chọn trạng thái ăn — dùng trong confirm feeding dialog
class EatStatusPicker extends StatefulWidget {
  final EatStatus initialStatus;
  final ValueChanged<EatStatus> onChanged;

  const EatStatusPicker({
    super.key,
    this.initialStatus = EatStatus.ateAll,
    required this.onChanged,
  });

  @override
  State<EatStatusPicker> createState() => _EatStatusPickerState();
}

class _EatStatusPickerState extends State<EatStatusPicker> {
  late EatStatus _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trạng thái ăn',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: MoewColors.textSub,
          ),
        ),
        const SizedBox(height: 8),
        ...EatStatus.values.map((status) => _buildOption(status)),
        if (_selected.showHint) ...[
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFf97316).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFf97316).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Bé ăn ít? Ghi chú thêm để thống kê chính xác hơn.',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFFf97316),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOption(EatStatus status) {
    final isSelected = _selected == status;
    return GestureDetector(
      onTap: () {
        setState(() => _selected = status);
        widget.onChanged(status);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? status.color.withValues(alpha: 0.1)
              : MoewColors.surface,
          borderRadius: BorderRadius.circular(MoewRadius.md),
          border: Border.all(
            color: isSelected ? status.color : MoewColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? status.color : Colors.transparent,
                border: Border.all(
                  color: isSelected ? status.color : MoewColors.textSub,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.circle, size: 8, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                status.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? status.color : MoewColors.textMain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper — icon nhỏ hiển thị trong danh sách bữa ăn bên cạnh dấu tick
class EatStatusBadge extends StatelessWidget {
  final String? eatStatus;

  const EatStatusBadge({super.key, this.eatStatus});

  @override
  Widget build(BuildContext context) {
    if (eatStatus == null) return const SizedBox.shrink();

    final status = EatStatus.fromValue(eatStatus!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _iconOnly(status),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  String _iconOnly(EatStatus s) {
    switch (s) {
      case EatStatus.ateAll:
        return '✅';
      case EatStatus.ateHalf:
        return '🟡';
      case EatStatus.ateLittle:
        return '⚠️';
      case EatStatus.ateNone:
        return '🔴';
    }
  }
}
