import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../config/theme.dart';

/// 404 Not Found widget with sleeping cat animation.
/// Use this for any page/content that doesn't exist.
class MoewNotFound extends StatelessWidget {
  final String message;

  const MoewNotFound({super.key, this.message = 'Không tìm thấy trang này'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: Lottie.asset('assets/animations/404_error_cat.json'),
          ),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: MoewColors.textSub)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Quay lại'),
            style: TextButton.styleFrom(foregroundColor: MoewColors.primary),
          ),
        ],
      ),
    );
  }
}
