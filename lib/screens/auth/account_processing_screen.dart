import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../utils/constants.dart';
import 'admin_account_setup_screen.dart';
import '../home/home_screen.dart';

/// Account Processing Screen
/// Shows animated confetti burst and "Verified by Admin" message
class AccountProcessingScreen extends StatefulWidget {
  final bool
  navigateToHome; // If true, go to home screen; if false, go to admin setup

  const AccountProcessingScreen({super.key, this.navigateToHome = false});

  @override
  State<AccountProcessingScreen> createState() =>
      _AccountProcessingScreenState();
}

class _AccountProcessingScreenState extends State<AccountProcessingScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final List<ConfettiParticle> _particles = [];
  final int _particleCount = 40;

  @override
  void initState() {
    super.initState();

    // Confetti animation controller
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Fade animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Scale animation controller
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Generate confetti particles
    _generateParticles();

    // Start animations
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _confettiController.forward();
        _fadeController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _scaleController.forward();
      }
    });

    // Navigate to Home Screen or Admin Account Setup Screen after animation
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        if (widget.navigateToHome) {
          // After admin setup completion - go to home screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          // After account review - go to admin setup
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const AdminAccountSetupScreen(
                adminAssignedEmail: 'cook.123@gharkakhana.com',
              ),
            ),
          );
        }
      }
    });
  }

  void _generateParticles() {
    final random = math.Random();
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      Colors.white,
      const Color(0xFFFF9800), // Orange
      const Color(0xFFFFEB3B), // Yellow
    ];

    for (int i = 0; i < _particleCount; i++) {
      final angle = (i / _particleCount) * 2 * math.pi;
      final velocity = 150 + random.nextDouble() * 100;
      final size = 8 + random.nextDouble() * 8;
      final color = colors[random.nextInt(colors.length)];
      final rotationSpeed = -2 + random.nextDouble() * 4;

      _particles.add(
        ConfettiParticle(
          angle: angle,
          velocity: velocity,
          size: size,
          color: color,
          rotationSpeed: rotationSpeed,
        ),
      );
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF211c11)
        : const Color(0xFFF8F7F6);
    final textColor = isDark ? Colors.white : const Color(0xFF171611);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Confetti Particles
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ConfettiPainter(
                    particles: _particles,
                    progress: _confettiController.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),

            // Main Content
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Chef Hat Icon with Scale Animation
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.1),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.restaurant_menu,
                          size: 80,
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Verified Badge
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              color: AppColors.secondary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Verified by Admin',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Welcome Message
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Setting up your kitchen...',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Loading Indicator
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confetti Particle Data Model
class ConfettiParticle {
  final double angle;
  final double velocity;
  final double size;
  final Color color;
  final double rotationSpeed;

  ConfettiParticle({
    required this.angle,
    required this.velocity,
    required this.size,
    required this.color,
    required this.rotationSpeed,
  });
}

/// Custom Painter for Confetti Animation
class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    for (final particle in particles) {
      // Calculate particle position with easing
      final easedProgress = _easeOutQuad(progress);
      final distance = particle.velocity * easedProgress;

      // Add gravity effect
      final gravity = 200 * progress * progress;

      final x = centerX + math.cos(particle.angle) * distance;
      final y = centerY + math.sin(particle.angle) * distance + gravity;

      // Calculate opacity (fade out at the end)
      final opacity = progress < 0.8 ? 1.0 : (1.0 - (progress - 0.8) / 0.2);

      // Calculate rotation
      final rotation = particle.rotationSpeed * progress * 2 * math.pi;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      // Draw particle as a rounded rectangle
      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 1.5,
        ),
        Radius.circular(particle.size / 4),
      );

      canvas.drawRRect(rect, paint);
      canvas.restore();
    }
  }

  double _easeOutQuad(double t) {
    return t * (2 - t);
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
