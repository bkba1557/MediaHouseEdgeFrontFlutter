import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config/app_navigator.dart';
import 'firebase_options.dart';
import 'localization/app_localizations.dart';
import 'providers/auth_provider.dart';
import 'providers/about_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/media_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/response_provider.dart';
import 'providers/team_provider.dart';
import 'providers/user_management_provider.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/splash_screen.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (AppFirebaseOptions.isConfigured && Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: AppFirebaseOptions.currentPlatform);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppFirebaseOptions.isConfigured) {
    await Firebase.initializeApp(options: AppFirebaseOptions.currentPlatform);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MediaProvider()),
        ChangeNotifierProvider(create: (_) => ResponseProvider()),
        ChangeNotifierProvider(create: (_) => TeamProvider()),
        ChangeNotifierProvider(create: (_) => AboutProvider()),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (_) => NotificationProvider(),
          update: (_, authProvider, notificationProvider) {
            final provider = notificationProvider ?? NotificationProvider();
            provider.syncAuth(authProvider);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, UserManagementProvider>(
          create: (_) => UserManagementProvider(),
          update: (_, authProvider, userManagementProvider) {
            final provider = userManagementProvider ?? UserManagementProvider();
            provider.syncAuth(authProvider);
            return provider;
          },
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, _) {
          return MaterialApp(
            navigatorKey: rootNavigatorKey,
            onGenerateTitle: (context) => context.tr('Media House Edge'),
            debugShowCheckedModeBanner: false,
            locale: localeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) => Directionality(
              textDirection: localeProvider.isRtl
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: child ?? const SizedBox.shrink(),
            ),
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFE50914),
                brightness: Brightness.dark,
              ),
              fontFamily: 'Petrichor',
              fontFamilyFallback: const [
                'Cairo',
                'Tajawal',
                'Arial',
                'Roboto',
                'sans-serif',
              ],
              scaffoldBackgroundColor: Colors.black,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              appBarTheme: const AppBarTheme(
                elevation: 0,
                centerTitle: true,
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE50914),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            onGenerateInitialRoutes: (_) => [
              MaterialPageRoute(
                settings: const RouteSettings(name: '/'),
                builder: (_) => const SplashScreen(),
              ),
            ],
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
              '/admin': (context) => const AdminDashboard(),
              '/notifications': (context) => const NotificationsScreen(),
            },
          );
        },
      ),
    );
  }
}
