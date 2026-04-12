import 'package:flutter/material.dart';

/// App-wide constants including colors, text styles, and other configuration

// App Colors - Custom Green and Gold color scheme
class AppColors {
  // Primary colors - Green (#2da832)
  static const Color primary = Color(0xFF2da832);
  static const Color primaryContainer = Color(0xFFc8f0cc);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF0d3310);

  // Secondary colors - Gold (#c2941b)
  static const Color secondary = Color(0xFFc2941b);
  static const Color secondaryContainer = Color(0xFFf5e8c3);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF3d2f08);

  // Tertiary colors - Darker green for accents
  static const Color tertiary = Color(0xFF1f7a25);
  static const Color tertiaryContainer = Color(0xFFb8e5bb);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFF0a2a0c);

  // Surface colors
  static const Color surface = Color(0xFFFFFBFE);
  static const Color surfaceVariant = Color(0xFFe8f5e9);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color onSurfaceVariant = Color(0xFF49454F);

  // Status colors - Using green and gold variations
  static const Color success = Color(0xFF2da832);
  static const Color warning = Color(0xFFc2941b);
  static const Color error = Color(0xFFd32f2f);
  static const Color info = Color(0xFF2da832);

  // Order status colors - Using green and gold variations
  static const Color pending = Color(0xFFc2941b);
  static const Color accepted = Color(0xFF2da832);
  static const Color preparing = Color(0xFF1f7a25);
  static const Color ready = Color(0xFF2da832);
  static const Color completed = Color(0xFF2da832);
  static const Color rejected = Color(0xFFd32f2f);

  // Background colors
  static const Color background = Color(0xFFFFFBFE);
  static const Color cardBackground = Color(0xFFFFFFFF);
}

// Text Styles
class AppTextStyles {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );
}

// Spacing constants
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

// Border radius constants
class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 999.0;
}

// App Theme
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryContainer,
        onPrimary: AppColors.onPrimary,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondary: AppColors.onSecondary,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiary: AppColors.onTertiary,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        surface: AppColors.surface,
        surfaceContainerHighest: AppColors.surfaceVariant,
        onSurface: AppColors.onSurface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        ),
      ),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }
}

// Food categories
class FoodCategories {
  static const List<String> all = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snacks',
    'Desserts',
    'Beverages',
  ];
}

// Cuisine specialties
class CuisineSpecialties {
  static const List<String> all = [
    'North Indian',
    'South Indian',
    'Chinese',
    'Continental',
    'Bengali',
    'Punjabi',
    'Gujarati',
    'Maharashtrian',
    'Street Food',
    'Bakery',
  ];
}

// App strings
class AppStrings {
  static const String appName = 'Ghar Ka Khana';
  static const String tagline = 'Kitchen Partner App';

  // Auth
  static const String phoneLogin = 'Login with Phone';
  static const String enterPhone = 'Enter your phone number';
  static const String sendOtp = 'Send OTP';
  static const String verifyOtp = 'Verify OTP';
  static const String enterOtp = 'Enter 6-digit OTP';
  static const String resendOtp = 'Resend OTP';

  // Profile
  static const String createProfile = 'Create Kitchen Profile';
  static const String editProfile = 'Edit Profile';
  static const String kitchenName = 'Kitchen Name';
  static const String ownerName = 'Owner Name';
  static const String address = 'Address';
  static const String specialty = 'Specialty';

  // Menu
  static const String myMenu = 'My Menu';
  static const String addMenuItem = 'Add Menu Item';
  static const String editMenuItem = 'Edit Menu Item';
  static const String itemName = 'Item Name';
  static const String description = 'Description';
  static const String price = 'Price';
  static const String quantity = 'Quantity Available';
  static const String category = 'Category';

  // Orders
  static const String orders = 'Orders';
  static const String orderDetails = 'Order Details';
  static const String acceptOrder = 'Accept Order';
  static const String rejectOrder = 'Reject Order';
  static const String updateStatus = 'Update Status';

  // Earnings
  static const String earnings = 'Earnings';
  static const String dailyEarnings = 'Daily Earnings';
  static const String totalRevenue = 'Total Revenue';
  static const String totalOrders = 'Total Orders';

  // Common
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String online = 'Online';
  static const String offline = 'Offline';
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String success = 'Success';
}
