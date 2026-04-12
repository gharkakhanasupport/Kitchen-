import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../utils/constants.dart';

/// Order Ready Confirmation Screen
/// Beautiful animated confirmation screen shown after marking order as ready
class OrderReadyConfirmationScreen extends StatefulWidget {
  final String orderId;

  const OrderReadyConfirmationScreen({super.key, required this.orderId});

  @override
  State<OrderReadyConfirmationScreen> createState() =>
      _OrderReadyConfirmationScreenState();
}

class _OrderReadyConfirmationScreenState
    extends State<OrderReadyConfirmationScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkmarkController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  late Animation<double> _checkmarkScale;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Checkmark pop-in animation
    _checkmarkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _checkmarkScale = CurvedAnimation(
      parent: _checkmarkController,
      curve: Curves.elasticOut,
    );

    // Fade up animation for text
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Pulse animation for checkmark
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start animations
    _checkmarkController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _pulseController.repeat(reverse: true);
    });

    // Auto redirect after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _checkmarkController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F6),
      body: Stack(
        children: [
          // Floating confetti shapes
          ..._buildConfettiShapes(),

          // Main content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated checkmark circle
                  ScaleTransition(
                    scale: _checkmarkScale,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulsing background
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.success.withValues(alpha: 0.2),
                                      AppColors.primary.withValues(alpha: 0.2),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        // Main circle
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.1),
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.check_circle,
                            size: 100,
                            color: AppColors.success,
                          ),
                        ),

                        // Floating confetti around checkmark
                        ..._buildCheckmarkConfetti(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Title with fade animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(_fadeAnimation),
                      child: Column(
                        children: [
                          Text(
                            'Order ${widget.orderId} is Ready!',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your homemade meal is marked as ready.\nWe\'ve notified the customer to pick it up.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black.withValues(alpha: 0.6),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Button with fade animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(_fadeAnimation),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 280,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 8,
                                shadowColor: AppColors.primary.withValues(
                                  alpha: 0.3,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    'Back to Orders',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Loading indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.success.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Redirecting to order list...',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
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
        ],
      ),
    );
  }

  List<Widget> _buildConfettiShapes() {
    final random = math.Random(42); // Fixed seed for consistent positions
    final shapes = <Widget>[];

    for (int i = 0; i < 10; i++) {
      final size = 40.0 + random.nextDouble() * 40;
      final left = random.nextDouble() * 100;
      final top = random.nextDouble() * 100;
      final color = i % 2 == 0
          ? AppColors.primary.withValues(
              alpha: 0.15 + random.nextDouble() * 0.15,
            )
          : AppColors.success.withValues(
              alpha: 0.15 + random.nextDouble() * 0.15,
            );

      shapes.add(
        _ConfettiShape(
          size: size,
          color: color,
          left: left,
          top: top,
          delay: i * 0.5,
          shapeType: i % 3,
        ),
      );
    }

    return shapes;
  }

  List<Widget> _buildCheckmarkConfetti() {
    return [
      _FloatingConfetti(
        size: 32,
        color: AppColors.primary.withValues(alpha: 0.6),
        top: -16,
        right: -16,
        delay: 0.1,
        shapeType: 1, // Star
      ),
      _FloatingConfetti(
        size: 24,
        color: AppColors.success.withValues(alpha: 0.6),
        bottom: 16,
        left: -24,
        delay: 0.4,
        shapeType: 0, // Circle
      ),
      _FloatingConfetti(
        size: 40,
        color: AppColors.primary.withValues(alpha: 0.5),
        top: 40,
        right: -32,
        delay: 0.8,
        shapeType: 2, // Squiggle
      ),
    ];
  }
}

class _ConfettiShape extends StatefulWidget {
  final double size;
  final Color color;
  final double left;
  final double top;
  final double delay;
  final int shapeType;

  const _ConfettiShape({
    required this.size,
    required this.color,
    required this.left,
    required this.top,
    required this.delay,
    required this.shapeType,
  });

  @override
  State<_ConfettiShape> createState() => _ConfettiShapeState();
}

class _ConfettiShapeState extends State<_ConfettiShape>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 6000 + (widget.delay * 1000).toInt()),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: MediaQuery.of(context).size.width * (widget.left / 100),
      top: MediaQuery.of(context).size.height * (widget.top / 100),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final value = _controller.value;
          return Transform.translate(
            offset: Offset(
              math.sin(value * 2 * math.pi) * 20,
              math.cos(value * 2 * math.pi) * 20,
            ),
            child: Transform.rotate(
              angle: value * 2 * math.pi,
              child: Opacity(
                opacity: 0.4 + (math.sin(value * math.pi) * 0.2),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: widget.shapeType == 0
                        ? BoxShape.circle
                        : BoxShape.rectangle,
                    borderRadius: widget.shapeType == 2
                        ? BorderRadius.circular(widget.size * 0.3)
                        : null,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FloatingConfetti extends StatefulWidget {
  final double size;
  final Color color;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double delay;
  final int shapeType;

  const _FloatingConfetti({
    required this.size,
    required this.color,
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.delay,
    required this.shapeType,
  });

  @override
  State<_FloatingConfetti> createState() => _FloatingConfettiState();
}

class _FloatingConfettiState extends State<_FloatingConfetti>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.top,
      bottom: widget.bottom,
      left: widget.left,
      right: widget.right,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              math.sin(_controller.value * 2 * math.pi) * 10,
              math.cos(_controller.value * 2 * math.pi) * 10,
            ),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color,
                shape: widget.shapeType == 0
                    ? BoxShape.circle
                    : BoxShape.rectangle,
                borderRadius: widget.shapeType == 2
                    ? BorderRadius.circular(widget.size * 0.3)
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
