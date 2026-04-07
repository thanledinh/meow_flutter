import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'config/theme.dart';
import 'config/router.dart';
import 'providers/auth_provider.dart';
import 'providers/preferences_provider.dart';
import 'services/firebase_messaging_service.dart';
import 'config/secrets.dart';
import 'api/api_client.dart';

/// Global navigator key — used by 401 handler to force-navigate to login
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MoewApp());
}

class MoewApp extends StatelessWidget {
  const MoewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final auth = AuthProvider();
            // Wire 401 → auto logout + force navigate to welcome
            ApiClient().setOnUnauthorized(() {
              auth.onLogout();
              navigatorKey.currentState?.pushNamedAndRemoveUntil(
                '/welcome',
                (_) => false,
              );
            });
            return auth;
          },
        ),
        ChangeNotifierProvider(create: (_) => PreferencesProvider()),
      ],
      child: Consumer2<AuthProvider, PreferencesProvider>(
        builder: (context, auth, prefs, _) {
          return MaterialApp(
            title: 'Moew',
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            themeMode: prefs.prefs.themeMode == 'system'
                ? ThemeMode.system
                : (prefs.prefs.themeMode == 'dark'
                      ? ThemeMode.dark
                      : ThemeMode.light),
            theme: MoewTheme.light,
            darkTheme: MoewTheme.dark,
            onGenerateRoute: generateRoute,
            home: auth.isLoading
                ? const _SplashScreen()
                : auth.isLoggedIn
                ? const _AutoRoute(route: '/home')
                : const _AutoRoute(route: '/welcome'),
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
            CircularProgressIndicator(color: Color(0xFF2196F3), strokeWidth: 2),
          ],
        ),
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
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, widget.route, (_) => false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF8F4F0),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2196F3),
          strokeWidth: 2,
        ),
      ),
    );
  }
}
