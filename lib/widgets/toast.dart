import 'dart:async';
import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Toast overlay — replaces Alert.alert
/// Usage: MoewToast.show(context, message: 'Success!', type: ToastType.success);
enum ToastType { success, error, warning, info }

class MoewToast {
  static OverlayEntry? _currentEntry;
  static Timer? _timer;

  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    _currentEntry?.remove();
    _timer?.cancel();

    final overlay = Overlay.of(context);

    Color bgColor;
    IconData icon;
    switch (type) {
      case ToastType.success:
        bgColor = MoewColors.success;
        icon = Icons.check_circle;
        break;
      case ToastType.error:
        bgColor = MoewColors.danger;
        icon = Icons.error;
        break;
      case ToastType.warning:
        bgColor = MoewColors.warning;
        icon = Icons.warning;
        break;
      case ToastType.info:
        bgColor = MoewColors.primary;
        icon = Icons.info;
        break;
    }

    _currentEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        bgColor: bgColor,
        icon: icon,
      ),
    );

    overlay.insert(_currentEntry!);

    _timer = Timer(duration, () {
      _currentEntry?.remove();
      _currentEntry = null;
    });
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final Color bgColor;
  final IconData icon;

  const _ToastWidget({
    required this.message,
    required this.bgColor,
    required this.icon,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offset;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _offset = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
    _opacity = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: MoewSpacing.lg,
      right: MoewSpacing.lg,
      child: SlideTransition(
        position: _offset,
        child: FadeTransition(
          opacity: _opacity,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: widget.bgColor,
                borderRadius: BorderRadius.circular(MoewRadius.md),
                boxShadow: [
                  BoxShadow(
                    color: widget.bgColor.withValues(alpha: 0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(widget.icon, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
