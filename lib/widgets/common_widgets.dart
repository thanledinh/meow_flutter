import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Reusable header with back button — matches RN header pattern
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBack;

  const AppHeader({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: MoewSpacing.lg, vertical: MoewSpacing.sm),
        child: Row(
          children: [
            if (showBack)
              GestureDetector(
                onTap: onBack ?? () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: MoewColors.surface,
                    borderRadius: BorderRadius.circular(MoewRadius.full),
                  ),
                  child: Icon(Icons.arrow_back,
                      size: 22, color: MoewColors.textMain),
                ),
              )
            else
              SizedBox(width: 40),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: MoewColors.textMain,
                ),
              ),
            ),
            if (actions != null)
              Row(mainAxisSize: MainAxisSize.min, children: actions!)
            else
              SizedBox(width: 40),
          ],
        ),
      ),
    );
  }
}

/// Status badge
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(MoewRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state placeholder
class EmptyState extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.color,
    required this.message,
    this.buttonLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: MoewSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: MoewColors.surface,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(icon, size: 48, color: color.withValues(alpha: 0.4)),
            ),
            SizedBox(height: MoewSpacing.lg),
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
                color: MoewColors.textSub,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null && onAction != null) ...[
              SizedBox(height: MoewSpacing.lg),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: Icon(Icons.add, size: 20),
                label: Text(buttonLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MoewRadius.md),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
