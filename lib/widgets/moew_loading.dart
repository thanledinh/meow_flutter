import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Reusable loading widget with Lottie cat animation.
/// Use this anywhere instead of CircularProgressIndicator.
///
/// Example:
/// ```dart
/// _loading ? const MoewLoading() : YourContent()
/// _loading ? const MoewLoading(size: 80) : YourContent()
/// _loading ? const MoewLoading(message: 'Đang tải...') : YourContent()
/// ```
class MoewLoading extends StatelessWidget {
  final double size;
  final String? message;

  const MoewLoading({super.key, this.size = 160, this.message});

  /// Wrap an async task to ensure MoewLoading shows for at least [minMs] ms.
  ///
  /// Usage:
  /// ```dart
  /// final res = await MoewLoading.ensure(() => SomeApi.fetch());
  /// setState(() { _data = res.data; _loading = false; });
  /// ```
  static Future<T> ensure<T>(Future<T> Function() task, {int minMs = 1000}) async {
    final start = DateTime.now();
    final result = await task();
    final elapsed = DateTime.now().difference(start).inMilliseconds;
    if (elapsed < minMs) {
      await Future.delayed(Duration(milliseconds: minMs - elapsed));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Lottie.asset('assets/animations/loading_cat.json'),
          ),
          if (message != null) ...[
            SizedBox(height: 12),
            Text(
              message!,
              style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
            ),
          ],
        ],
      ),
    );
  }
}
