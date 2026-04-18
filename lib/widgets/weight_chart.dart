import 'package:flutter/material.dart';
import 'dart:math';
import '../config/theme.dart';

class WeightChartBox extends StatelessWidget {
  final List<dynamic> chartData;
  final double height;
  final bool showTitle;
  final EdgeInsetsGeometry? padding;

  const WeightChartBox({
    super.key,
    required this.chartData,
    this.height = 120,
    this.showTitle = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (chartData.isEmpty) return const SizedBox.shrink();

    final weights = chartData
        .map((c) {
          final w = c['weight'];
          if (w == null) return null;
          if (w is num) return w.toDouble();
          if (w is String) return double.tryParse(w);
          return null;
        })
        .whereType<double>()
        .toList();
        
    if (weights.isEmpty) return const SizedBox.shrink();

    final minW = weights.reduce(min) - 0.3;
    final maxW = weights.reduce(max) + 0.3;
    final range = maxW - minW;

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MoewColors.white,
        borderRadius: BorderRadius.circular(MoewRadius.lg),
        boxShadow: padding != null ? [] : MoewShadows.soft, // only shadow if using default outer boxing padding
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[
            const Text('Biểu đồ cân nặng', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
          ],
          SizedBox(
            height: height,
            child: CustomPaint(
              painter: WeightChartPainter(weights, minW, range),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_safeFormatDate(chartData.first['date']), style: TextStyle(fontSize: 9, color: MoewColors.textSub)),
              Text(_safeFormatDate(chartData.last['date']), style: TextStyle(fontSize: 9, color: MoewColors.textSub)),
            ],
          ),
        ],
      ),
    );
  }

  String _safeFormatDate(dynamic dateVal) {
    if (dateVal == null) return '';
    final s = dateVal.toString();
    if (s.length >= 10) return s.substring(5, 10);
    return s;
  }
}

class WeightChartPainter extends CustomPainter {
  final List<double> weights;
  final double minW;
  final double range;

  WeightChartPainter(this.weights, this.minW, this.range);

  @override
  void paint(Canvas canvas, Size size) {
    if (weights.length < 2 || range <= 0) return;
    
    final paint = Paint()
      ..color = MoewColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
      
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [MoewColors.primary.withValues(alpha: 0.2), MoewColors.primary.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      
    final dotPaint = Paint()
      ..color = MoewColors.primary
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    
    for (int i = 0; i < weights.length; i++) {
      final x = weights.length == 1 ? size.width / 2 : i / (weights.length - 1) * size.width;
      final y = size.height - ((weights[i] - minW) / range * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3, dotPaint);
    }
    
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
