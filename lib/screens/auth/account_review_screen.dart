import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../utils/constants.dart';
import 'account_processing_screen.dart';

/// Account Review Screen
/// Displays after successful signup submission while account is being verified
class AccountReviewScreen extends StatefulWidget {
  const AccountReviewScreen({super.key});

  @override
  State<AccountReviewScreen> createState() => _AccountReviewScreenState();
}

class _AccountReviewScreenState extends State<AccountReviewScreen>
    with TickerProviderStateMixin {
  bool _notificationsEnabled = true;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _checkmarkController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _checkmarkScale;
  late Animation<double> _checkmarkRotation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for rings
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    // Fade in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Slide up animation
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Checkmark animation
    _checkmarkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _checkmarkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkmarkController, curve: Curves.elasticOut),
    );

    _checkmarkRotation = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(parent: _checkmarkController, curve: Curves.easeOut),
    );

    // Start animations
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _checkmarkController.forward();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _checkmarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF221d10)
        : const Color(0xFFF8F7F6);
    final textColor = isDark ? Colors.white : const Color(0xFF181611);
    final subtextColor = isDark
        ? const Color(0xFFc4bfb2)
        : const Color(0xFF5e5a4f);
    final borderColor = isDark
        ? const Color(0xFF423d31)
        : const Color(0xFFe6e3db);
    final cardColor = isDark ? const Color(0xFF2d2719) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Center(
                child: Text(
                  'Account Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ),

            // Main Content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Hero Animation Section with Pulse Rings
                          SizedBox(
                            width: 280,
                            height: 280,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Pulse Rings
                                ...List.generate(3, (index) {
                                  return AnimatedBuilder(
                                    animation: _pulseController,
                                    builder: (context, child) {
                                      final delay = index * 0.33;
                                      final progress =
                                          (_pulseController.value + delay) %
                                          1.0;
                                      final scale = 0.8 + (progress * 0.7);
                                      final opacity = progress < 0.5
                                          ? progress * 0.6
                                          : (1.0 - progress) * 0.6;

                                      return Transform.scale(
                                        scale: scale,
                                        child: Container(
                                          width: 192,
                                          height: 192,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.primary
                                                  .withValues(alpha: opacity),
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }),

                                // Main Circle
                                Container(
                                  width: 192,
                                  height: 192,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: cardColor,
                                    border: Border.all(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.2,
                                      ),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.restaurant,
                                    size: 80,
                                    color: AppColors.primary,
                                  ),
                                ),

                                // Checkmark Badge
                                Positioned(
                                  bottom: 80,
                                  right: 40,
                                  child: AnimatedBuilder(
                                    animation: _checkmarkController,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _checkmarkScale.value,
                                        child: Transform.rotate(
                                          angle:
                                              _checkmarkRotation.value *
                                              math.pi,
                                          child: Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.secondary,
                                              border: Border.all(
                                                color: backgroundColor,
                                                width: 4,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.secondary
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.check_circle,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Headline
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'Your Kitchen is being Verified',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Body Text
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  fontSize: 16,
                                  color: subtextColor,
                                  height: 1.5,
                                ),
                                children: [
                                  const TextSpan(
                                    text:
                                        'Our team is checking your details to ensure the best hygiene standards. This usually takes ',
                                  ),
                                  TextSpan(
                                    text: '24-48 hours',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Status Tracker Card
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Container(
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  // Verification Status
                                  Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.secondary.withValues(
                                            alpha: 0.1,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.verified_user,
                                          color: AppColors.secondary,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Hygiene Standards Check',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Verification in progress',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: subtextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),
                                  Divider(color: borderColor, height: 1),
                                  const SizedBox(height: 16),

                                  // Notification Toggle
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Stay Updated',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Notify me when my kitchen is approved',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: subtextColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Custom Toggle Switch
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _notificationsEnabled =
                                                !_notificationsEnabled;
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          width: 51,
                                          height: 31,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            color: _notificationsEnabled
                                                ? AppColors.primary
                                                : borderColor,
                                          ),
                                          padding: const EdgeInsets.all(2),
                                          child: AnimatedAlign(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            alignment: _notificationsEnabled
                                                ? Alignment.centerRight
                                                : Alignment.centerLeft,
                                            child: Container(
                                              width: 27,
                                              height: 27,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.2),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // OK Button at Bottom
            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, const Color(0xFFb08619)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to processing screen with confetti animation
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const AccountProcessingScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
