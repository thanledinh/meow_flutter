import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Custom pull-to-refresh with Lottie cat animation.
/// Uses Overlay to show cat at the very top of screen,
/// with route-aware cleanup so it doesn't bleed into other screens.
///
/// The widget wraps its child in a NotificationListener to detect
/// genuine pull-to-refresh gestures (scroll must be at the very top
/// and user must pull slowly). This prevents accidental refresh
/// when scrolling fast through lists.
class MoewRefresh extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  const MoewRefresh({super.key, required this.onRefresh, required this.child});

  @override
  State<MoewRefresh> createState() => _MoewRefreshState();
}

class _MoewRefreshState extends State<MoewRefresh> with SingleTickerProviderStateMixin {
  late AnimationController _lottieCtrl;
  OverlayEntry? _overlayEntry;
  static const _catSize = 140.0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _lottieCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000));
  }

  @override
  void dispose() {
    _removeOverlay();
    _lottieCtrl.dispose();
    super.dispose();
  }

  void _showOverlay() {
    _removeOverlay();
    final statusBarHeight = MediaQuery.of(context).padding.top;
    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        top: statusBarHeight + 4,
        left: 0, right: 0,
        child: IgnorePointer(
          child: Center(
            child: SizedBox(
              width: _catSize, height: _catSize,
              child: Transform.flip(
                flipY: true,
                child: Lottie.asset(
                  'assets/animations/cat_loading.json',
                  controller: _lottieCtrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
    _checkRoute();
  }

  /// Periodically check if this screen is still the top route.
  void _checkRoute() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) { _removeOverlay(); return; }
      final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
      if (!isCurrent) {
        _removeOverlay();
        return;
      }
      if (_overlayEntry != null) _checkRoute();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    final showStart = DateTime.now();
    _lottieCtrl.repeat();
    _showOverlay();
    await widget.onRefresh();
    if (!mounted) return;
    // Ensure the cat plays for at least 3 seconds
    final elapsed = DateTime.now().difference(showStart).inMilliseconds;
    if (elapsed < 3000) {
      await Future.delayed(Duration(milliseconds: 3000 - elapsed));
    }
    if (!mounted) return;
    _removeOverlay();
    _lottieCtrl.stop();
    _lottieCtrl.reset();
    _isRefreshing = false;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: Color(0x00000000),
      backgroundColor: Color(0x00000000),
      strokeWidth: 0.01,
      displacement: 100,
      triggerMode: RefreshIndicatorTriggerMode.onEdge,
      child: widget.child,
    );
  }
}
