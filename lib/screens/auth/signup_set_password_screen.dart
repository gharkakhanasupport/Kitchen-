import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../utils/constants.dart';
import '../../utils/supabase_config.dart';
import 'account_review_screen.dart';

/// Sign Up: Set Password Screen (Step 4 of 4)
/// Allows user to create a password for their account
class SignUpSetPasswordScreen extends StatefulWidget {
  final Map<String, dynamic> personalDetails;
  final Map<String, dynamic> kycDetails;
  final Map<String, dynamic> kitchenDetails;

  const SignUpSetPasswordScreen({
    super.key,
    required this.personalDetails,
    required this.kycDetails,
    required this.kitchenDetails,
  });

  @override
  State<SignUpSetPasswordScreen> createState() =>
      _SignUpSetPasswordScreenState();
}

class _SignUpSetPasswordScreenState extends State<SignUpSetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;

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

    _progressAnimation = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final supabase = Supabase.instance.client;
      final phone = widget.personalDetails['phone'] as String;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Upload KYC documents to storage
      String? aadharFrontUrl;
      String? aadharBackUrl;
      String? panCardUrl;

      if (widget.kycDetails['aadharFront'] != null) {
        final file = File(widget.kycDetails['aadharFront']);
        final path = '$phone/aadhar_front_$timestamp';
        await supabase.storage.from('kyc-documents').upload(path, file);
        aadharFrontUrl =
            supabase.storage.from('kyc-documents').getPublicUrl(path);
      }

      if (widget.kycDetails['aadharBack'] != null) {
        final file = File(widget.kycDetails['aadharBack']);
        final path = '$phone/aadhar_back_$timestamp';
        await supabase.storage.from('kyc-documents').upload(path, file);
        aadharBackUrl =
            supabase.storage.from('kyc-documents').getPublicUrl(path);
      }

      if (widget.kycDetails['panCard'] != null) {
        final file = File(widget.kycDetails['panCard']);
        final path = '$phone/pan_card_$timestamp';
        await supabase.storage.from('kyc-documents').upload(path, file);
        panCardUrl =
            supabase.storage.from('kyc-documents').getPublicUrl(path);
      }

      // Upload kitchen photos to storage
      final kitchenPhotos =
          widget.kitchenDetails['kitchenPhotos'] as List<File>;
      final List<String> kitchenPhotoUrls = [];
      for (int i = 0; i < kitchenPhotos.length; i++) {
        final path = '$phone/kitchen_${timestamp}_$i';
        await supabase.storage
            .from('kitchen-photos')
            .upload(path, kitchenPhotos[i]);
        final url =
            supabase.storage.from('kitchen-photos').getPublicUrl(path);
        kitchenPhotoUrls.add(url);
      }

      // Insert all form data into cooks table
      await supabase.from('cooks').insert({
        // Step 1: Personal Details
        'full_name': widget.personalDetails['fullName'],
        'age': widget.personalDetails['age'],
        'gender': widget.personalDetails['gender'],
        'location': widget.personalDetails['location'],
        'phone': phone,
        'email': widget.personalDetails['email'],

        // Step 2: KYC
        'aadhar_front_url': aadharFrontUrl,
        'aadhar_back_url': aadharBackUrl,
        'pan_card_url': panCardUrl,

        // Step 3: Kitchen Details
        'kitchen_name': widget.kitchenDetails['kitchenName'],
        'kitchen_description': widget.kitchenDetails['kitchenDescription'],
        'nominee_partner': widget.kitchenDetails['nomineePartner'],
        'is_vegetarian': widget.kitchenDetails['isVegetarian'],
        'kitchen_photos': kitchenPhotoUrls,

        // Step 4: Password
        'password': _passwordController.text,
      });

      // Also insert into kitchen_applications table (admin DB) for admin review
      await SupabaseConfig.kitchenAppsClient.from('kitchen_applications').insert({
        'owner_name': widget.personalDetails['fullName'],
        'age': widget.personalDetails['age'],
        'gender': widget.personalDetails['gender'],
        'location': widget.personalDetails['location'],
        'phone': phone,
        'email': widget.personalDetails['email'],
        'aadhar_front_url': aadharFrontUrl,
        'aadhar_back_url': aadharBackUrl,
        'pan_card_url': panCardUrl,
        'kyc_skipped': widget.kycDetails['aadharFront'] == null && widget.kycDetails['aadharBack'] == null && widget.kycDetails['panCard'] == null,
        'kitchen_name': widget.kitchenDetails['kitchenName'],
        'description': widget.kitchenDetails['kitchenDescription'] ?? '',
        'nominee_partner': widget.kitchenDetails['nomineePartner'],
        'is_vegetarian': widget.kitchenDetails['isVegetarian'] ?? true,
        'kitchen_photos': kitchenPhotoUrls,
        'status': 'PENDING',
      });

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AccountReviewScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Signup failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFF211c11);
    final textColor = Colors.white;
    final subtextColor = const Color(0xFFa39d8e);
    final borderColor = const Color(0xFF635636);
    final cardColor = const Color(0xFF1a1510);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.centerLeft,
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: textColor,
                        size: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Set Password',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Progress Bar
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Container(
                  margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _progressAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Step indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(
                children: [
                  Text(
                    'Step 4 of 4',
                    style: TextStyle(
                      fontSize: 12,
                      color: subtextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.lock_outline, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Security',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Form content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'Create a Password',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Set a secure password to protect your account.',
                            style: TextStyle(
                              fontSize: 14,
                              color: subtextColor,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // New Password
                          Text(
                            'New Password',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            validator: _validatePassword,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              hintText: 'Enter password',
                              hintStyle: TextStyle(color: subtextColor),
                              filled: true,
                              fillColor: cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.primary, width: 2),
                              ),
                              prefixIcon: Icon(Icons.lock_outline,
                                  color: subtextColor),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: subtextColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Confirm Password
                          Text(
                            'Confirm Password',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            validator: _validateConfirmPassword,
                            style: TextStyle(color: textColor),
                            decoration: InputDecoration(
                              hintText: 'Re-enter password',
                              hintStyle: TextStyle(color: subtextColor),
                              filled: true,
                              fillColor: cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.primary, width: 2),
                              ),
                              prefixIcon: Icon(Icons.lock_outline,
                                  color: subtextColor),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: subtextColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Password hints
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Password must:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: subtextColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildHint('Be at least 6 characters',
                                    subtextColor),
                                _buildHint('Match in both fields',
                                    subtextColor),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed:
                                  _isSubmitting ? null : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Create Account',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildHint(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 14, color: color),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}
