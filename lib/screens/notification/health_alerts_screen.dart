import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../widgets/common_widgets.dart';

/// Màn hình Health Alerts — navigate tới khi nhận push notification health_alert
class HealthAlertsScreen extends StatelessWidget {
  final dynamic petId;
  const HealthAlertsScreen({super.key, this.petId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MoewColors.background,
      appBar: AppHeader(title: 'Cảnh báo sức khỏe 🐾'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: MoewColors.danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.health_and_safety, size: 40, color: MoewColors.danger),
              ),
              const SizedBox(height: 20),
              Text(
                'Cảnh báo từ Admin',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: MoewColors.textMain),
              ),
              const SizedBox(height: 8),
              Text(
                petId != null
                    ? 'Có thông báo sức khỏe cho thú cưng #$petId.\nVui lòng kiểm tra ngay.'
                    : 'Có thông báo sức khỏe mới từ hệ thống.\nVui lòng kiểm tra thú cưng của bạn.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: MoewColors.textSub, height: 1.5),
              ),
              const SizedBox(height: 28),
              if (petId != null)
                ElevatedButton.icon(
                  onPressed: () => context.push('/pet-detail', extra: petId),
                  icon: const Icon(Icons.pets, size: 18),
                  label: const Text('Xem hồ sơ thú cưng'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MoewColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoewRadius.md)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
