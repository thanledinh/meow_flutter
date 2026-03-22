import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'config/theme.dart';
import 'config/router.dart';
import 'providers/auth_provider.dart';
import 'services/firebase_messaging_service.dart';
import 'config/secrets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mapbox token
  MapboxOptions.setAccessToken(mapboxSecretToken);

  // Firebase init
  await Firebase.initializeApp();

  // Background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // FCM setup (permissions, token, listeners)
  await FirebaseMessagingService().initialize();

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const MoewApp());
}

class MoewApp extends StatelessWidget {
  const MoewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'Moew',
            debugShowCheckedModeBanner: false,
            theme: MoewTheme.light,
            onGenerateRoute: generateRoute,
            // Dùng home thay vì initialRoute để reactive khi auth state thay đổi
            home: auth.isLoading
                ? const _SplashScreen()
                : auth.isLoggedIn
                    ? const _AutoRoute(route: '/home')
                    : const _AutoRoute(route: '/login'),
          );
        },
      ),
    );
  }
}

/// Splash screen hiển thị khi đang check auth
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8F4F0),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.pets, size: 64, color: Color(0xFF2196F3)),
          SizedBox(height: 16),
          Text('Moew', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 2)),
          SizedBox(height: 8),
          CircularProgressIndicator(color: Color(0xFF2196F3), strokeWidth: 2),
        ]),
      ),
    );
  }
}

/// Widget tự navigate đến route chỉ định sau khi build
class _AutoRoute extends StatefulWidget {
  final String route;
  const _AutoRoute({required this.route});
  @override
  State<_AutoRoute> createState() => _AutoRouteState();
}

class _AutoRouteState extends State<_AutoRoute> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamedAndRemoveUntil(context, widget.route, (_) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8F4F0),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF2196F3), strokeWidth: 2)),
    );
  }
}
