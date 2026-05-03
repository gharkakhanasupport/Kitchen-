import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'utils/constants.dart';
import 'utils/firebase_options.dart';
import 'services/auth_service.dart';
import 'services/daily_menu_service.dart';
import 'services/fcm_service.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash/splash_screen.dart';

/// Main entry point of the Ghar Ka Khana Kitchen App
Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Forward all Flutter errors to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Load environment variables
  bool envLoaded = false;
  try {
    await dotenv.load(fileName: '.env');
    envLoaded = true;
    debugPrint('✅ Kitchen .env loaded');
  } catch (e) {
    debugPrint('⚠️ Kitchen .env load failed: $e (using fallback values)');
  }

  // Initialize Supabase with hardcoded fallbacks for web reliability
  const fallbackUrl = 'https://yvbjnuobnxekgibfqsmq.supabase.co';
  const fallbackAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl2YmpudW9ibnhla2dpYmZxc21xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUzOTY1NzIsImV4cCI6MjA5MDk3MjU3Mn0.Hf5zPb8urWQq155fUxF7kQIGFb0NyWphdMyeRI83vgk';

  final supabaseUrl = envLoaded
      ? (dotenv.env['SUPABASE_URL'] ?? fallbackUrl)
      : fallbackUrl;
  final supabaseAnonKey = envLoaded
      ? (dotenv.env['SUPABASE_ANON_KEY'] ?? fallbackAnonKey)
      : fallbackAnonKey;

  try {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    debugPrint('✅ Supabase initialized');
  } catch (e) {
    debugPrint('❌ Supabase init failed: $e');
  }

  // Initialize Firebase for push notifications
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized');
  } catch (e) {
    debugPrint('⚠️ Firebase init failed: $e');
  }

  // Initialize FCM push notifications (non-blocking)
  FCMService().initialize();

  // Auto-cleanup menus older than 3 days (fire-and-forget)
  DailyMenuService().cleanupOldMenus();

  // Set preferred orientations (portrait only for better UX)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const GharKaKhanaApp());
}

/// Root widget of the application
class GharKaKhanaApp extends StatelessWidget {
  const GharKaKhanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,

      // Apply Material Design 3 theme
      theme: AppTheme.lightTheme,

      // Set initial route to splash screen
      home: const SplashWrapper(),
    );
  }
}

/// Splash Wrapper
/// Shows animated splash screen then navigates to auth wrapper
class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

/// Auth Wrapper
/// Checks if user is logged in and navigates accordingly
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = AuthService();
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  /// Check if user is already logged in
  Future<void> _checkAuthStatus() async {
    final isLoggedIn = await _authService.isLoggedIn();

    setState(() {
      _isLoggedIn = isLoggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen while checking auth status
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    // Navigate to appropriate screen based on auth status
    return _isLoggedIn ? const HomeScreen() : const WelcomeScreen();
  }
}
