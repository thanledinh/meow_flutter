import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../main.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/public_profile_screen.dart';
import '../screens/profile/ekyc_screen.dart';
import '../screens/pet/pet_profile_screen.dart';
import '../screens/pet/pet_detail_screen.dart';
import '../screens/pet/pet_weight_screen.dart';
import '../screens/pet/pet_vaccine_screen.dart';
import '../screens/pet/add_pet_screen.dart';
import '../screens/medical/medical_screen.dart';
import '../screens/medical/add_medical_screen.dart';
import '../screens/medical/cost_breakdown_screen.dart';
import '../screens/medical/medical_detail_screen.dart';
import '../screens/ai/food_analysis_screen.dart';
import '../screens/feeding/food_history_screen.dart';
import '../screens/ai/ai_chat_screen.dart';
import '../screens/ai/camera_screen.dart';
import '../screens/clinic/clinic_list_screen.dart';
import '../screens/clinic/clinic_detail_screen.dart';
import '../screens/clinic/booking_history_screen.dart';
import '../screens/clinic/book_appointment_screen.dart';
import '../screens/sos/sos_screen.dart';
import '../screens/sos/sos_history_screen.dart';
import '../screens/map/guardian_map_screen.dart';
import '../screens/wallet/wallet_screen.dart';
import '../screens/notification/notification_screen.dart';
import '../screens/notification/health_alerts_screen.dart';
import '../screens/feeding/feeding_today_screen.dart';
import '../screens/feeding/food_products_screen.dart';
import '../screens/feeding/feeding_plan_screen.dart';
import '../screens/feeding/food_transition_screen.dart';
import '../screens/feeding/nutrition_dashboard_screen.dart';
import '../screens/ai/chat_sessions_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/post/feed_screen.dart';
import '../screens/post/create_post_screen.dart';
import '../screens/post/edit_post_screen.dart';
import '../screens/expense/expense_list_screen.dart';
import '../screens/expense/expense_capture_screen.dart';
import '../screens/expense/expense_calendar_screen.dart';
import '../screens/expense/expense_day_detail_screen.dart';

import '../widgets/moew_not_found.dart';
import '../widgets/main_shell.dart';

import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

Page<dynamic> _fade(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, anim, secAnim, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeOutCirc).animate(anim),
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.95,
            end: 1.0,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCirc)),
          child: child,
        ),
      );
    },
  );
}

Page<dynamic> _slide(Widget child, GoRouterState state) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (context, anim, secAnim, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutQuart)),
        child: FadeTransition(
          opacity: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      );
    },
  );
}

class AppEntry extends StatelessWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F4F0),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pets, size: 64, color: Color(0xFF2196F3)),
              SizedBox(height: 16),
              Text(
                'Moew',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              SizedBox(height: 8),
              CircularProgressIndicator(
                color: Color(0xFF2196F3),
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      );
    }

    if (auth.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/home');
      });
      return const Scaffold(backgroundColor: Color(0xFFF8F4F0));
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/welcome');
      });
      return const Scaffold(backgroundColor: Color(0xFFF8F4F0));
    }
  }
}

final GoRouter moewRouter = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/',
  errorBuilder: (context, state) => Scaffold(
    backgroundColor: const Color(0xFFF8F8FC),
    appBar: AppBar(
      title: const Text('404'),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
    body: MoewNotFound(message: 'Trang "${state.uri}" không tồn tại'),
  ),
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AppEntry()),
    GoRoute(
      path: '/welcome',
      pageBuilder: (context, state) => _fade(const WelcomeScreen(), state),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _fade(const LoginScreen(), state),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) => _slide(const RegisterScreen(), state),
    ),

    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => _fade(const MainShell(), state),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => _slide(const SettingsScreen(), state),
    ),

    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) => _slide(const ProfileScreen(), state),
    ),
    GoRoute(
      path: '/public-profile',
      pageBuilder: (context, state) =>
          _slide(PublicProfileScreen(userId: state.extra), state),
    ),
    GoRoute(
      path: '/ekyc',
      pageBuilder: (context, state) => _slide(const EkycScreen(), state),
    ),

    GoRoute(
      path: '/pet-profile',
      pageBuilder: (context, state) => _slide(const PetProfileScreen(), state),
    ),
    GoRoute(
      path: '/pet-detail',
      pageBuilder: (context, state) =>
          _slide(PetDetailScreen(petId: state.extra), state),
    ),
    GoRoute(
      path: '/add-pet',
      pageBuilder: (context, state) => _slide(const AddPetScreen(), state),
    ),
    GoRoute(
      path: '/pet-weight',
      pageBuilder: (context, state) =>
          _slide(PetWeightScreen(petId: state.extra), state),
    ),
    GoRoute(
      path: '/pet-vaccines',
      pageBuilder: (context, state) =>
          _slide(PetVaccineScreen(petId: state.extra), state),
    ),

    GoRoute(
      path: '/medical',
      pageBuilder: (context, state) =>
          _slide(MedicalScreen(petId: state.extra), state),
    ),
    GoRoute(
      path: '/add-medical',
      pageBuilder: (context, state) {
        final args = (state.extra as Map<String, dynamic>?) ?? {};
        return _slide(
          AddMedicalScreen(petId: args['petId'], type: args['type']),
          state,
        );
      },
    ),
    GoRoute(
      path: '/cost-breakdown',
      pageBuilder: (context, state) {
        final args = (state.extra as Map<String, dynamic>?) ?? {};
        return _slide(
          CostBreakdownScreen(
            petId: args['petId'],
            recordId: args['recordId'],
            type: args['type'],
          ),
          state,
        );
      },
    ),
    GoRoute(
      path: '/medical-detail',
      pageBuilder: (context, state) {
        final args = (state.extra as Map<String, dynamic>?) ?? {};
        return _slide(MedicalDetailScreen(record: args), state);
      },
    ),

    GoRoute(
      path: '/food-analysis',
      pageBuilder: (context, state) {
        if (state.extra is Map) {
          final args = state.extra as Map;
          return _slide(
            FoodAnalysisScreen(petId: args['petId'], petName: args['petName']),
            state,
          );
        }
        return _slide(const FoodAnalysisScreen(), state);
      },
    ),
    GoRoute(
      path: '/food-history',
      pageBuilder: (context, state) =>
          _slide(FoodHistoryScreen(petId: state.extra), state),
    ),
    GoRoute(
      path: '/ai-chat',
      pageBuilder: (context, state) {
        if (state.extra is Map) {
          final args = state.extra as Map;
          return _slide(
            AiChatScreen(petId: args['petId'], foodLogId: args['foodLogId']),
            state,
          );
        }
        return _slide(const AiChatScreen(), state);
      },
    ),
    GoRoute(
      path: '/camera',
      pageBuilder: (context, state) => _slide(const CameraScreen(), state),
    ),

    GoRoute(
      path: '/clinic-list',
      pageBuilder: (context, state) => _slide(const ClinicListScreen(), state),
    ),
    GoRoute(
      path: '/clinic-detail',
      pageBuilder: (context, state) =>
          _slide(ClinicDetailScreen(clinicId: state.extra), state),
    ),
    GoRoute(
      path: '/book-appointment',
      pageBuilder: (context, state) {
        final args = (state.extra as Map<String, dynamic>?) ?? {};
        return _slide(
          BookAppointmentScreen(
            clinicId: args['clinicId'],
            clinicName: args['clinicName'],
          ),
          state,
        );
      },
    ),
    GoRoute(
      path: '/booking-history',
      pageBuilder: (context, state) =>
          _slide(const BookingHistoryScreen(), state),
    ),

    GoRoute(
      path: '/feeding-today',
      pageBuilder: (context, state) =>
          _slide(const FeedingTodayScreen(), state),
    ),
    GoRoute(
      path: '/food-products',
      pageBuilder: (context, state) =>
          _slide(const FoodProductsScreen(), state),
    ),
    GoRoute(
      path: '/feeding-plan',
      pageBuilder: (context, state) => _slide(const FeedingPlanScreen(), state),
    ),
    GoRoute(
      path: '/food-transition',
      pageBuilder: (context, state) =>
          _slide(const FoodTransitionScreen(), state),
    ),
    GoRoute(
      path: '/nutrition-dashboard',
      pageBuilder: (context, state) =>
          _slide(const NutritionDashboardScreen(), state),
    ),
    GoRoute(
      path: '/chat-sessions',
      pageBuilder: (context, state) =>
          _slide(const ChatSessionsScreen(), state),
    ),

    GoRoute(
      path: '/sos',
      pageBuilder: (context, state) => _slide(const SosScreen(), state),
    ),
    GoRoute(
      path: '/sos-history',
      pageBuilder: (context, state) => _slide(const SosHistoryScreen(), state),
    ),

    GoRoute(
      path: '/guardian-map',
      pageBuilder: (context, state) {
        final mapArgs = state.extra as Map<String, dynamic>?;
        return _slide(
          GuardianMapScreen(
            destination: mapArgs?['destination'] as Map<String, dynamic>?,
          ),
          state,
        );
      },
    ),

    GoRoute(
      path: '/wallet',
      pageBuilder: (context, state) => _slide(const WalletScreen(), state),
    ),

    GoRoute(
      path: '/notifications',
      pageBuilder: (context, state) =>
          _slide(const NotificationScreen(), state),
    ),
    GoRoute(
      path: '/health-alerts',
      pageBuilder: (context, state) {
        final alertArgs = state.extra as Map<String, dynamic>?;
        return _slide(HealthAlertsScreen(petId: alertArgs?['petId']), state);
      },
    ),

    GoRoute(
      path: '/feed',
      pageBuilder: (context, state) => _slide(const FeedScreen(), state),
    ),
    GoRoute(
      path: '/create-post',
      pageBuilder: (context, state) => _slide(const CreatePostScreen(), state),
    ),
    GoRoute(
      path: '/edit-post',
      pageBuilder: (context, state) {
        final args = (state.extra as Map<String, dynamic>?) ?? {};
        return _slide(EditPostScreen(post: args), state);
      },
    ),

    // Expenses
    GoRoute(
      path: '/expenses',
      pageBuilder: (context, state) => _slide(const ExpenseListScreen(), state),
    ),
    GoRoute(
      path: '/expense-capture',
      pageBuilder: (context, state) {
        final dyn = state.extra;
        final expense = dyn is Map<dynamic, dynamic> ? dyn : null;
        return _slide(ExpenseCaptureScreen(expense: expense), state);
      },
    ),
    GoRoute(
      path: '/expense-calendar',
      pageBuilder: (context, state) =>
          _slide(const ExpenseCalendarScreen(), state),
    ),
    GoRoute(
      path: '/expense-day',
      pageBuilder: (context, state) {
        final date = state.uri.queryParameters['date'] ?? '';
        return _slide(ExpenseDayDetailScreen(date: date), state);
      },
    ),
  ],
);
