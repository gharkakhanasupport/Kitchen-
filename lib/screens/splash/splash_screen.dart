import 'package:flutter/material.dart';
import 'dart:async';
import '../auth/welcome_screen.dart';

/// Splash Screen
/// Animated splash screen with pot, ladle, and progress indicator
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _steamController;
  late AnimationController _ladleController;
  late AnimationController _progressController;
  late AnimationController _fadeController;

  late Animation<double> _steamAnimation;
  late Animation<double> _ladleAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;

  double _progress = 0.0;

  @override
  void initState() {
    super.initState();

    // Steam animation (continuous floating)
    _steamController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _steamAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _steamController, curve: Curves.easeInOut),
    );

    // Ladle animation (gentle stirring motion)
    _ladleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _ladleAnimation = Tween<double>(begin: -12.0, end: -8.0).animate(
      CurvedAnimation(parent: _ladleController, curve: Curves.easeInOut),
    );

    // Progress animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 0.68).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    // Start animations
    _fadeController.forward();
    _progressController.forward();

    // Update progress periodically
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          _progress = _progressAnimation.value;
        });
      }
    });

    // Navigate after delay
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _steamController.dispose();
    _ladleController.dispose();
    _progressController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            colors: [Color(0xFF2c2514), Color(0xFF12100b)],
          ),
        ),
        child: Stack(
          children: [
            // Background texture
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1556910103-1c02745aae4d?auto=format&fit=crop&q=80&w=1000',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),

            // Main content
            FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),

                    // Animated pot and ladle section
                    SizedBox(
                      width: 300,
                      height: 300,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Steam particles
                          AnimatedBuilder(
                            animation: _steamAnimation,
                            builder: (context, child) {
                              return Positioned(
                                top: 20 - (_steamAnimation.value * 20),
                                child: Opacity(
                                  opacity: 0.6 - (_steamAnimation.value * 0.3),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: 96,
                                        height: 96,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFc1921a,
                                          ).withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          // Pot and ladle
                          Positioned(
                            bottom: 80,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Golden pot
                                Container(
                                  width: 192,
                                  height: 128,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFc1921a),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                      bottomLeft: Radius.circular(64),
                                      bottomRight: Radius.circular(64),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFc1921a,
                                        ).withValues(alpha: 0.4),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      // Pot rim
                                      Container(
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFa67c16),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(8),
                                            topRight: Radius.circular(8),
                                          ),
                                        ),
                                      ),
                                      // Inner glow
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              const Color(
                                                0xFF8a6611,
                                              ).withValues(alpha: 0.5),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Left handle
                                Positioned(
                                  left: -16,
                                  top: 32,
                                  child: Container(
                                    width: 24,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFFc1921a),
                                        width: 4,
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        bottomLeft: Radius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),

                                // Right handle
                                Positioned(
                                  right: -16,
                                  top: 32,
                                  child: Container(
                                    width: 24,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFFc1921a),
                                        width: 4,
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),

                                // Green ladle (animated)
                                AnimatedBuilder(
                                  animation: _ladleAnimation,
                                  builder: (context, child) {
                                    return Positioned(
                                      top: -64,
                                      right: 16,
                                      child: Transform.rotate(
                                        angle:
                                            _ladleAnimation.value * 0.0174533,
                                        child: Container(
                                          width: 16,
                                          height: 128,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2da832),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF2da832,
                                                ).withValues(alpha: 0.3),
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                          child: Stack(
                                            children: [
                                              // Ladle head
                                              Positioned(
                                                bottom: -16,
                                                left: -16,
                                                child: Container(
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFF2da832,
                                                    ),
                                                    shape: BoxShape.circle,
                                                    border: Border(
                                                      bottom: BorderSide(
                                                        color: Colors.black
                                                            .withValues(
                                                              alpha: 0.1,
                                                            ),
                                                        width: 4,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Branding
                    const Text(
                      'Ghar Ka Khana',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(color: Colors.black26, blurRadius: 10),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'KITCHEN MAGIC',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFc1921a).withValues(alpha: 0.8),
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Culinary magic in progress...',
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),

                    const Spacer(flex: 2),

                    // Progress section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Perfecting your recipes',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              Text(
                                '${(_progress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFc1921a),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Progress bar
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _progress,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFc1921a),
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFc1921a,
                                      ).withValues(alpha: 0.6),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.restaurant,
                                color: Color(0xFFc1921a),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'WARMING UP THE STOVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFc7b894),
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 80),

                    // iOS indicator bar
                    Container(
                      width: 128,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),

                    const SizedBox(height: 8),
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
