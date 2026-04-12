import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import 'account_processing_screen.dart';

/// Admin Account Setup Screen
/// For cooks who receive admin-assigned email credentials
class AdminAccountSetupScreen extends StatefulWidget {
  final String adminAssignedEmail;

  const AdminAccountSetupScreen({super.key, required this.adminAssignedEmail});

  @override
  State<AdminAccountSetupScreen> createState() =>
      _AdminAccountSetupScreenState();
}

class _AdminAccountSetupScreenState extends State<AdminAccountSetupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _hasSymbolOrNumber = false;
  bool _isSubmitting = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
          ),
        );

    _animationController.forward();

    _passwordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final password = _passwordController.text;
    final hasSymbolOrNumber = RegExp(
      r'[0-9!@#$%^&*(),.?":{}|<>]',
    ).hasMatch(password);

    if (hasSymbolOrNumber != _hasSymbolOrNumber) {
      setState(() {
        _hasSymbolOrNumber = hasSymbolOrNumber;
      });
    }
  }

  String? _validatePasswordField(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!_hasSymbolOrNumber) {
      return 'Password must include a symbol or number';
    }
    return null;
  }

  Future<void> _handleCompleteSetup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      // Navigate to processing screen with navigateToHome flag
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AccountProcessingScreen(
            navigateToHome: true, // Navigate to home screen after animation
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFF211c11); // Always dark like HTML
    final textColor = Colors.white; // Always white text on dark background
    final subtextColor = const Color(0xFFa39d8e); // Dark theme subtext
    final borderColor = const Color(0xFF3d3829); // Dark theme border
    final cardColor = const Color(0xFF1a1510); // Darker for better visibility
    final readOnlyBgColor = const Color(
      0xFF1e293b,
    ).withValues(alpha: 0.5); // slate-800/50

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Center(
                  child: Text(
                    'Account Setup',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // Header Image Section
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: Container(
                            height: 220,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.1),
                                  AppColors.primary.withValues(alpha: 0.3),
                                ],
                              ),
                              image: const DecorationImage(
                                image: NetworkImage(
                                  'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=800',
                                ),
                                fit: BoxFit.cover,
                                opacity: 0.3,
                              ),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.4),
                                    Colors.black.withValues(alpha: 0.9),
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.all(24),
                              alignment: Alignment.bottomLeft,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.verified,
                                    color: AppColors.secondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'IDENTITY VERIFIED',
                                    style: TextStyle(
                                      color: AppColors.secondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Headline Section
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              Text(
                                'Welcome to the Family!',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Your professional kitchen profile is ready. Finalize your credentials to start cooking with Ghar Ka Khana.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: subtextColor,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Form Section
                        Form(
                          key: _formKey,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Read-only Email Field
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                    bottom: 8,
                                  ),
                                  child: Text(
                                    'ADMIN ASSIGNED EMAIL',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: subtextColor,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: readOnlyBgColor,
                                    border: Border.all(
                                      color: borderColor.withValues(alpha: 0.5),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Text(
                                            widget.adminAssignedEmail,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: textColor.withValues(
                                                alpha: 0.8,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 16,
                                        ),
                                        child: Icon(
                                          Icons.lock_person,
                                          color: AppColors.primary,
                                          size: 24,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                    top: 8,
                                  ),
                                  child: Text(
                                    'This official email was generated by your administrator for professional management.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: subtextColor.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Password Field
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                    bottom: 8,
                                  ),
                                  child: Text(
                                    'SET YOUR PASSWORD',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: subtextColor,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    border: Border.all(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _passwordController,
                                          validator: _validatePasswordField,
                                          obscureText: _obscurePassword,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: textColor,
                                          ),
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: cardColor,
                                            hintText: 'Minimum 8 characters',
                                            hintStyle: TextStyle(
                                              color: subtextColor.withValues(
                                                alpha: 0.5,
                                              ),
                                            ),
                                            border: InputBorder.none,
                                            contentPadding:
                                                const EdgeInsets.all(16),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            right: 16,
                                          ),
                                          child: Icon(
                                            _obscurePassword
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            color: AppColors.primary,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                    top: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: _hasSymbolOrNumber
                                            ? AppColors.secondary
                                            : subtextColor.withValues(
                                                alpha: 0.3,
                                              ),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Must include a symbol or number',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: _hasSymbolOrNumber
                                              ? AppColors.secondary
                                              : subtextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Action Section
            FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Complete Setup Button
                    Container(
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
                        onPressed: _isSubmitting ? null : _handleCompleteSetup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Complete Setup',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.restaurant_menu,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Terms Text
                    Text(
                      'By completing setup, you agree to our Culinary Partner Terms and Kitchen Safety Standards.',
                      style: TextStyle(
                        fontSize: 11,
                        color: subtextColor.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
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
