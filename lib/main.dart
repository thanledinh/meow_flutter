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
import 'repositories/pet_repository.dart';
import 'repositories/feed_repository.dart';

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
            ApiClient().setOnUnauthorized(() {
              auth.onLogout();
              moewRouter.go('/welcome');
            });
            return auth;
          },
        ),
        ChangeNotifierProvider(create: (_) => PreferencesProvider()),
        ChangeNotifierProvider(create: (_) => PetRepository()),
        ChangeNotifierProvider(create: (_) => FeedRepository()),
      ],
      child: Consumer4<AuthProvider, PreferencesProvider, PetRepository, FeedRepository>(
        builder: (context, auth, prefs, petRepo, feedRepo, _) {
          return MaterialApp.router(
            title: 'Moew',
            debugShowCheckedModeBanner: false,
            themeMode: prefs.prefs.themeMode == 'dark' ? ThemeMode.dark : ThemeMode.light,
            theme: MoewTheme.light,
            darkTheme: MoewTheme.dark,
            routerConfig: moewRouter,
          );
        },
      ),
    );
  }
}

