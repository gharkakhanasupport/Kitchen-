import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/constants.dart';
import 'signup_kyc_verification_screen.dart';

/// Sign Up: Personal Details Screen (Step 1 of 3)
/// Collects user's personal information including name, age, gender, location, phone, and email
class SignUpPersonalDetailsScreen extends StatefulWidget {
  const SignUpPersonalDetailsScreen({super.key});

  @override
  State<SignUpPersonalDetailsScreen> createState() =>
      _SignUpPersonalDetailsScreenState();
}

class _SignUpPersonalDetailsScreenState
    extends State<SignUpPersonalDetailsScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedGender = 'MALE';
  bool _isNameValid = false;

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

    // Listen to name changes for validation indicator
    _nameController.addListener(() {
      final isValid = _nameController.text.trim().length >= 3;
      if (isValid != _isNameValid) {
        setState(() {
          _isNameValid = isValid;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (value.trim().length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Required';
    }
    final age = int.tryParse(value);
    if (age == null || age < 18 || age > 100) {
      return 'Age must be between 18-100';
    }
    return null;
  }

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

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      // Collect personal details
      final personalDetails = {
        'fullName': _nameController.text.trim(),
        'age': int.parse(_ageController.text),
        'gender': _selectedGender,
        'location': _locationController.text.trim(),
        'phone': '+91${_phoneController.text.trim()}',
        'email': _emailController.text.trim(),
      };

      // Navigate to Step 2: KYC Verification
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SignUpKycVerificationScreen(personalDetails: personalDetails),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always use dark theme colors
    final backgroundColor = const Color(0xFF211c11); // Dark background
    final textColor = Colors.white;
    final subtextColor = const Color(0xFFa39d8e);
    final borderColor = const Color(0xFF635636); // Gold border
    final cardColor = const Color(
      0xFF1a1510,
    ); // Darker input bg for better visibility

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.centerLeft,
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                  // Title
                  Expanded(
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // Progress Indicator
            FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'STEP 1 OF 3',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'Personal Details',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: subtextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: borderColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: borderColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable Form
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Headline
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create Your Profile',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tell us about yourself. This helps us personalize your kitchen dashboard.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: subtextColor,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Full Name
                            _buildLabel('Full Name', textColor),
                            _buildTextField(
                              controller: _nameController,
                              hint: 'Enter your full name',
                              validator: _validateName,
                              cardColor: cardColor,
                              borderColor: borderColor,
                              textColor: textColor,
                              suffixIcon: _isNameValid
                                  ? Icon(
                                      Icons.check_circle,
                                      color: AppColors.secondary,
                                      size: 20,
                                    )
                                  : null,
                            ),

                            const SizedBox(height: 16),

                            // Age & Gender Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Age
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Age', textColor),
                                      _buildTextField(
                                        controller: _ageController,
                                        hint: 'Age',
                                        validator: _validateAge,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(3),
                                        ],
                                        cardColor: cardColor,
                                        borderColor: borderColor,
                                        textColor: textColor,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Gender
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildLabel('Gender', textColor),
                                      Container(
                                        height: 56,
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF3d3829,
                                          ), // Darker bg for gender selector
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            _buildGenderButton(
                                              'MALE',
                                              cardColor,
                                              textColor,
                                            ),
                                            _buildGenderButton(
                                              'FEMALE',
                                              cardColor,
                                              textColor,
                                            ),
                                            _buildGenderButton(
                                              'OTHER',
                                              cardColor,
                                              textColor,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Location
                            _buildLabel('Location', textColor),
                            _buildTextField(
                              controller: _locationController,
                              hint: 'City, Area',
                              cardColor: cardColor,
                              borderColor: borderColor,
                              textColor: textColor,
                              suffixIcon: Icon(
                                Icons.location_on,
                                color: subtextColor,
                                size: 20,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Contact Number
                            _buildLabel('Contact Number', textColor),
                            Row(
                              children: [
                                Container(
                                  width: 80,
                                  height: 56,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF3d3829,
                                    ), // Darker bg for country code
                                    border: Border.all(color: borderColor),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '+91',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _phoneController,
                                    hint: 'Phone number',
                                    validator: _validatePhone,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(10),
                                    ],
                                    cardColor: cardColor,
                                    borderColor: borderColor,
                                    textColor: textColor,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Email
                            _buildLabel('Email Address', textColor),
                            _buildTextField(
                              controller: _emailController,
                              hint: 'example@mail.com',
                              validator: _validateEmail,
                              keyboardType: TextInputType.emailAddress,
                              cardColor: cardColor,
                              borderColor: borderColor,
                              textColor: textColor,
                            ),

                            const SizedBox(
                              height: 120,
                            ), // Space for bottom button
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Action Area
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor.withValues(alpha: 0.95),
          border: Border(top: BorderSide(color: borderColor, width: 1)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Next Button
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
                  onPressed: _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Login Link
              Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: 14, color: subtextColor),
                  children: [
                    const TextSpan(text: 'Already have an account? '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Text(
                          'Log in',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    Widget? suffixIcon,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: cardColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(fontSize: 16, color: textColor),
        decoration: InputDecoration(
          filled: true,
          fillColor: cardColor,
          hintText: hint,
          hintStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          suffixIcon: suffixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: suffixIcon,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildGenderButton(String gender, Color cardColor, Color textColor) {
    final isSelected = _selectedGender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedGender = gender;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? cardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            gender,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? AppColors.primary
                  : textColor.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
