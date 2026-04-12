import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'phone_login_screen.dart';
import 'signup_personal_details_screen.dart';

/// Welcome Screen
/// Animated entry screen with branding and auth options
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _contentController;

  late Animation<double> _backgroundScaleAnimation;
  late Animation<double> _backgroundOpacityAnimation;
  late Animation<double> _overlayOpacityAnimation;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _logoSlideAnimation;

  late Animation<double> _taglineOpacityAnimation;
  late Animation<double> _taglineSlideAnimation;

  late Animation<double> _descriptionOpacityAnimation;
  late Animation<double> _descriptionSlideAnimation;

  late Animation<double> _signupButtonScaleAnimation;
  late Animation<double> _signupButtonOpacityAnimation;

  late Animation<double> _loginButtonScaleAnimation;
  late Animation<double> _loginButtonOpacityAnimation;

  late Animation<double> _footerOpacityAnimation;

  @override
  void initState() {
    super.initState();

    // Background animation controller (slower, dramatic)
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Content animation controller (staggered popup effects)
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    // Background animations - zoom in and fade
    _backgroundScaleAnimation = Tween<double>(begin: 1.3, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeOut),
    );

    _backgroundOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _overlayOpacityAnimation = Tween<double>(begin: 0.0, end: 0.4).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
    );

    // Logo animations - pop up with bounce
    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );

    _logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _logoSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    // Tagline animations
    _taglineOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
      ),
    );

    _taglineSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    // Description animations
    _descriptionOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOut),
      ),
    );

    _descriptionSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // Sign Up button - pop up with bounce
    _signupButtonScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.5, 0.8, curve: Curves.elasticOut),
      ),
    );

    _signupButtonOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.5, 0.7, curve: Curves.easeOut),
      ),
    );

    // Login button - pop up with bounce (slightly delayed)
    _loginButtonScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.6, 0.9, curve: Curves.elasticOut),
      ),
    );

    _loginButtonOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.6, 0.8, curve: Curves.easeOut),
      ),
    );

    // Footer fade in
    _footerOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    // Start animations
    _backgroundController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _contentController.forward();
      }
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _navigateToSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SignUpPersonalDetailsScreen(),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const PhoneLoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Background Image
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Opacity(
                opacity: _backgroundOpacityAnimation.value,
                child: Transform.scale(
                  scale: _backgroundScaleAnimation.value,
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=1200&h=1600&fit=crop',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Animated Gradient Overlay
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(
                        alpha: 0.3 * _overlayOpacityAnimation.value,
                      ),
                      Colors.black.withValues(
                        alpha: 0.4 * _overlayOpacityAnimation.value,
                      ),
                      Colors.black.withValues(
                        alpha: 0.9 * _overlayOpacityAnimation.value,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),

                  // Restaurant Icon with Animation
                  AnimatedBuilder(
                    animation: _contentController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _logoSlideAnimation.value),
                        child: Transform.scale(
                          scale: _logoScaleAnimation.value,
                          child: Opacity(
                            opacity: _logoOpacityAnimation.value,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.restaurant_menu,
                                size: 32,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Logo and Title Section
                  AnimatedBuilder(
                    animation: _contentController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _logoSlideAnimation.value),
                        child: Opacity(
                          opacity: _logoOpacityAnimation.value,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // App Title with Editorial Font
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 56,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -1.5,
                                    height: 1.0,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Ghar Ka\n',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'serif',
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.4,
                                            ),
                                            blurRadius: 12,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Khana',
                                      style: TextStyle(
                                        color: AppColors.secondary,
                                        fontFamily: 'serif',
                                        fontStyle: FontStyle.italic,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.4,
                                            ),
                                            blurRadius: 12,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  // Tagline
                  AnimatedBuilder(
                    animation: _contentController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _taglineSlideAnimation.value),
                        child: Opacity(
                          opacity: _taglineOpacityAnimation.value,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              'KITCHEN APP',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 3.2,
                                color: AppColors.primary,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Quote/Description
                  AnimatedBuilder(
                    animation: _contentController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _descriptionSlideAnimation.value),
                        child: Opacity(
                          opacity: _descriptionOpacityAnimation.value,
                          child: Container(
                            padding: const EdgeInsets.only(left: 16),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: AppColors.secondary,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              '"Where every meal tells a story of home, heritage, and heart."',
                              style: TextStyle(
                                fontSize: 20,
                                fontFamily: 'serif',
                                fontStyle: FontStyle.italic,
                                color: Colors.white.withValues(alpha: 0.9),
                                height: 1.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const Spacer(),

                  // Buttons Section
                  Column(
                    children: [
                      // Get Started Button
                      AnimatedBuilder(
                        animation: _contentController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _signupButtonScaleAnimation.value,
                            child: Opacity(
                              opacity: _signupButtonOpacityAnimation.value,
                              child: child,
                            ),
                          );
                        },
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _navigateToSignUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor: Colors.black.withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'Get Started',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 22),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // I Have an Account Button
                      AnimatedBuilder(
                        animation: _contentController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _loginButtonScaleAnimation.value,
                            child: Opacity(
                              opacity: _loginButtonOpacityAnimation.value,
                              child: child,
                            ),
                          );
                        },
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: _navigateToLogin,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: const Text(
                              'I have an account',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Footer
                  AnimatedBuilder(
                    animation: _contentController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _footerOpacityAnimation.value,
                        child: child,
                      );
                    },
                    child: Center(
                      child: Text(
                        'JOIN OUR COMMUNITY OF HOME CHEFS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 2,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
