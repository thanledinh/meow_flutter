import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/public_profile_screen.dart';
import '../screens/profile/ekyc_screen.dart';
import '../screens/pet/pet_profile_screen.dart';
import '../screens/pet/pet_detail_screen.dart';
import '../screens/pet/add_pet_screen.dart';
import '../screens/medical/medical_screen.dart';
import '../screens/medical/add_medical_screen.dart';
import '../screens/medical/cost_breakdown_screen.dart';
import '../screens/medical/medical_detail_screen.dart';
import '../screens/ai/food_analysis_screen.dart';
import '../screens/ai/food_history_screen.dart';
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
import '../widgets/main_shell.dart';

/// Route generator — MaterialApp.onGenerateRoute
Route<dynamic>? generateRoute(RouteSettings settings) {
  switch (settings.name) {
    // Auth
    case '/login':
      return _fade(const LoginScreen(), settings);
    case '/register':
      return _slide(const RegisterScreen(), settings);

    // Home — wraps with persistent nav bar
    case '/home':
      return _fade(const MainShell(), settings);

    // Profile
    case '/profile':
      return _slide(const ProfileScreen(), settings);
    case '/public-profile':
      return _slide(const PublicProfileScreen(), settings);
    case '/ekyc':
      return _slide(const EkycScreen(), settings);

    // Pet
    case '/pet-profile':
      return _slide(const PetProfileScreen(), settings);
    case '/pet-detail':
      return _slide(PetDetailScreen(petId: settings.arguments), settings);
    case '/add-pet':
      return _slide(const AddPetScreen(), settings);

    // Medical
    case '/medical':
      return _slide(MedicalScreen(petId: settings.arguments), settings);
    case '/add-medical':
      final args = settings.arguments as Map<String, dynamic>;
      return _slide(AddMedicalScreen(petId: args['petId'], type: args['type']), settings);
    case '/cost-breakdown':
      final args = settings.arguments as Map<String, dynamic>;
      return _slide(CostBreakdownScreen(petId: args['petId'], recordId: args['recordId'], type: args['type']), settings);
    case '/medical-detail':
      return _slide(MedicalDetailScreen(record: settings.arguments as Map<String, dynamic>), settings);

    // AI / Food
    case '/food-analysis':
      final args = settings.arguments;
      if (args is Map) {
        return _slide(FoodAnalysisScreen(petId: args['petId'], petName: args['petName']), settings);
      }
      return _slide(const FoodAnalysisScreen(), settings);
    case '/food-history':
      return _slide(FoodHistoryScreen(petId: settings.arguments), settings);
    case '/ai-chat':
      final args = settings.arguments;
      if (args is Map) {
        return _slide(AiChatScreen(petId: args['petId'], foodLogId: args['foodLogId']), settings);
      }
      return _slide(const AiChatScreen(), settings);
    case '/camera':
      return _slide(const CameraScreen(), settings);

    // Clinic
    case '/clinic-list':
      return _slide(const ClinicListScreen(), settings);
    case '/clinic-detail':
      return _slide(ClinicDetailScreen(clinicId: settings.arguments), settings);
    case '/book-appointment':
      final args = settings.arguments as Map<String, dynamic>;
      return _slide(BookAppointmentScreen(clinicId: args['clinicId'], clinicName: args['clinicName']), settings);
    case '/booking-history':
      return _slide(const BookingHistoryScreen(), settings);

    // SOS
    case '/sos':
      return _slide(const SosScreen(), settings);
    case '/sos-history':
      return _slide(const SosHistoryScreen(), settings);

    // Map
    case '/guardian-map':
      final mapArgs = settings.arguments as Map<String, dynamic>?;
      return _slide(GuardianMapScreen(destination: mapArgs?['destination'] as Map<String, dynamic>?), settings);

    // Wallet
    case '/wallet':
      return _slide(const WalletScreen(), settings);

    // Notification
    case '/notifications':
      return _slide(const NotificationScreen(), settings);

    default:
      return _fade(const LoginScreen(), settings);
  }
}

// ─── Transitions ─────────────────────
PageRouteBuilder _fade(Widget page, RouteSettings settings) {
  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, anim, secondaryAnimation, child) => FadeTransition(opacity: anim, child: child),
    transitionDuration: const Duration(milliseconds: 300),
  );
}

PageRouteBuilder _slide(Widget page, RouteSettings settings) {
  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, anim, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}
