import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/constants.dart';
import 'utils/supabase_config.dart';
import 'services/auth_service.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash/splash_screen.dart';

/// Main entry point of the Ghar Ka Khana Kitchen App
Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

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
