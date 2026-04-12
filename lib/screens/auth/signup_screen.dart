import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import 'otp_verification_screen.dart';
import 'phone_login_screen.dart';

/// Sign Up Screen
/// Modern design for new users creating an account
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  final String _countryCode = '+91';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// Validate phone number
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }

    final cleaned = value.replaceAll(' ', '');
    if (cleaned.length != 10) {
      return 'Phone number must be 10 digits';
    }

    if (!RegExp(r'^[6-9]').hasMatch(cleaned)) {
      return 'Phone number must start with 6, 7, 8, or 9';
    }

    return null;
  }

  /// Send OTP to phone number
  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final phoneNumber =
          '$_countryCode${_phoneController.text.replaceAll(' ', '')}';
      final success = await _authService.sendOtp(phoneNumber);

      if (success && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                OtpVerificationScreen(phoneNumber: phoneNumber, isSignUp: true),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send OTP. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PhoneLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF211c11)
        : const Color(0xFFF8F7F6);
    final textColor = isDark ? Colors.white : const Color(0xFF171611);
    final subtextColor = isDark
        ? const Color(0xFFcdc6b6)
        : const Color(0xFF877d64);
    final borderColor = isDark
        ? const Color(0xFF423d33)
        : const Color(0xFFe5e2dc);
    final cardColor = isDark ? const Color(0xFF2a2415) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Back Button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: textColor,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  // Title
                  Expanded(
                    child: Center(
                      child: Text(
                        'SIGN UP',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  // Spacer for centering
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Image
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Background Image
                                Image.network(
                                  'https://lh3.googleusercontent.com/aida-public/AB6AXuBWmM1h8qRj2ReCkDaBim-myYQHeOP60b_kDqT1S7E33rasfdEPAUWj5MpZ8wGYhaezbHbX7XmInI0De2HwRK1J3YhSaTmYPGiGb5rG_LncpfNgVyvRTXRN9rKKse0Y5qGaH7xYMgWejNG1d0_p50sd2TCll9Go4dBPwZJtNXiHXynfhMD4mYokfZlhloXJm0DVQ8nIlUmRg77408pmB1gdAXRZ9XijI1I0L3_IsEVPH6wyREISvRo_AQawTTb28v9KF7YvPeCodW0N',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            AppColors.primary.withValues(
                                              alpha: 0.3,
                                            ),
                                            AppColors.secondary.withValues(
                                              alpha: 0.3,
                                            ),
                                          ],
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.restaurant_menu,
                                        size: 80,
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // Gradient Overlay
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.2),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Headline Text
                        Text(
                          'Let\'s get cooking!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Body Text
                        Text(
                          'Enter your mobile number to create your seller account and start selling homemade food.',
                          style: TextStyle(
                            fontSize: 16,
                            color: subtextColor,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Phone Input
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                bottom: 8,
                              ),
                              child: Text(
                                'Mobile Number',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                // Country Code
                                Container(
                                  width: 80,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    border: Border.all(color: borderColor),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '+91',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.expand_more,
                                        color: subtextColor,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                                // Phone Input
                                Expanded(
                                  child: Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      border: Border.all(color: borderColor),
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      maxLength: 10,
                                      validator: _validatePhone,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(10),
                                      ],
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: textColor,
                                        letterSpacing: 1,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '98765 43210',
                                        hintStyle: TextStyle(
                                          color: subtextColor,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 16,
                                            ),
                                        counterText: '',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Get OTP Button
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                const Color(0xFFb08619),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _sendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Get OTP',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Terms & Footer
                        Text.rich(
                          TextSpan(
                            style: TextStyle(
                              fontSize: 12,
                              color: subtextColor,
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(
                                text:
                                    'By clicking "Get OTP", you agree to our ',
                              ),
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                  color: const Color(0xFF2da832),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: const Color(0xFF2da832),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Alternative Login
                        Center(
                          child: GestureDetector(
                            onTap: _navigateToLogin,
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'Already have a kitchen? ',
                                  ),
                                  TextSpan(
                                    text: 'Log in',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
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
