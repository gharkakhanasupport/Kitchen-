import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/constants.dart';
import 'signup_set_password_screen.dart';

/// Sign Up: Kitchen Details Screen (Step 3 of 3)
/// Final step where users provide kitchen information and complete registration
class SignUpKitchenDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> personalDetails;
  final Map<String, dynamic> kycDetails;

  const SignUpKitchenDetailsScreen({
    super.key,
    required this.personalDetails,
    required this.kycDetails,
  });

  @override
  State<SignUpKitchenDetailsScreen> createState() =>
      _SignUpKitchenDetailsScreenState();
}

class _SignUpKitchenDetailsScreenState extends State<SignUpKitchenDetailsScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _kitchenNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _nomineePartnerController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isVegetarian = true;
  bool _termsAccepted = false;
  final List<File> _kitchenPhotos = [];
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

    _progressAnimation = Tween<double>(begin: 0.66, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _kitchenNameController.dispose();
    _descriptionController.dispose();
    _nomineePartnerController.dispose();
    super.dispose();
  }

  String? _validateKitchenName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your kitchen name';
    }
    if (value.trim().length < 3) {
      return 'Kitchen name must be at least 3 characters';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please describe your kitchen';
    }
    if (value.trim().length < 20) {
      return 'Description must be at least 20 characters';
    }
    return null;
  }

  Future<void> _pickKitchenPhotos() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          // Limit to 5 photos
          final remainingSlots = 5 - _kitchenPhotos.length;
          final photosToAdd = images
              .take(remainingSlots)
              .map((e) => File(e.path))
              .toList();
          _kitchenPhotos.addAll(photosToAdd);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _kitchenPhotos.removeAt(index);
    });
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please accept the terms and conditions'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // Collect kitchen details and navigate to Step 4: Set Password
    final kitchenDetails = {
      'kitchenName': _kitchenNameController.text.trim(),
      'kitchenDescription': _descriptionController.text.trim(),
      'nomineePartner': _nomineePartnerController.text.trim(),
      'isVegetarian': _isVegetarian,
      'kitchenPhotos': List<File>.from(_kitchenPhotos),
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignUpSetPasswordScreen(
          personalDetails: widget.personalDetails,
          kycDetails: widget.kycDetails,
          kitchenDetails: kitchenDetails,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Always use dark theme colors
    final backgroundColor = const Color(0xFF211c11);
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
                      'Kitchen Details',
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

            // Progress Section
            FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Final Step: Your Culinary Space',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                        Text(
                          '3 of 3',
                          style: TextStyle(fontSize: 14, color: subtextColor),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _progressAnimation.value,
                            minHeight: 8,
                            backgroundColor: borderColor,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        );
                      },
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
                    child: Form(
                      key: _formKey,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section Header
                            Text(
                              'General Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Kitchen Name
                            _buildLabel('Kitchen Name', textColor),
                            _buildTextField(
                              controller: _kitchenNameController,
                              hint: 'e.g., Mom\'s Magic Spices',
                              validator: _validateKitchenName,
                              cardColor: cardColor,
                              borderColor: borderColor,
                              textColor: textColor,
                              subtextColor: subtextColor,
                            ),
                            const SizedBox(height: 16),

                            // Description
                            _buildLabel('Description', textColor),
                            Container(
                              decoration: BoxDecoration(
                                color: cardColor,
                                border: Border.all(color: borderColor),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextFormField(
                                controller: _descriptionController,
                                validator: _validateDescription,
                                maxLines: 5,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: textColor,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: cardColor,
                                  hintText:
                                      'Tell customers about your cooking style, specialties, and hygiene practices...',
                                  hintStyle: TextStyle(color: subtextColor),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Nominee Partner
                            Row(
                              children: [
                                Text(
                                  'Nominee Partner ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  '(Optional)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subtextColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _nomineePartnerController,
                              hint: 'Name of your assistant or partner',
                              cardColor: cardColor,
                              borderColor: borderColor,
                              textColor: textColor,
                              subtextColor: subtextColor,
                            ),
                            const SizedBox(height: 24),

                            // Kitchen Type Toggle
                            Text(
                              'Kitchen Type',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.eco,
                                        color: AppColors.secondary,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Strictly Vegetarian',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: _isVegetarian,
                                    onChanged: (value) {
                                      setState(() {
                                        _isVegetarian = value;
                                      });
                                    },
                                    activeThumbColor: AppColors.secondary,
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 4, top: 8),
                              child: Text(
                                'Enabling this adds a certified "Veg Only" badge to your profile.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: subtextColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Photo Upload Section
                            Row(
                              children: [
                                Text(
                                  'Kitchen & Hygiene Photos ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                  ),
                                ),
                                Text(
                                  '(Optional)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subtextColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Photo Grid
                            if (_kitchenPhotos.isNotEmpty) ...[
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                itemCount: _kitchenPhotos.length,
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.file(
                                          _kitchenPhotos[index],
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () => _removePhoto(index),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.6,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Upload Button
                            if (_kitchenPhotos.length < 5)
                              GestureDetector(
                                onTap: _pickKitchenPhotos,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 32,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    border: Border.all(
                                      color: borderColor,
                                      width: 2,
                                      strokeAlign: BorderSide.strokeAlignInside,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.add_a_photo,
                                          color: AppColors.primary,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Click to upload photos',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Upload up to 5 photos of your kitchen and storage area',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: subtextColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          'Upload Now',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            const SizedBox(height: 24),

                            // Terms and Conditions
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _termsAccepted,
                                  onChanged: (value) {
                                    setState(() {
                                      _termsAccepted = value!;
                                    });
                                  },
                                  activeColor: const Color(0xFFc1921a), // Gold
                                  checkColor: Colors.black,
                                  side: BorderSide(
                                    color: borderColor,
                                    width: 2,
                                  ),
                                  fillColor: MaterialStateProperty.resolveWith((
                                    states,
                                  ) {
                                    if (states.contains(
                                      MaterialState.selected,
                                    )) {
                                      return const Color(0xFFc1921a);
                                    }
                                    return Colors.transparent;
                                  }),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text.rich(
                                      TextSpan(
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: subtextColor,
                                          height: 1.5,
                                        ),
                                        children: [
                                          const TextSpan(
                                            text: 'I agree to the ',
                                          ),
                                          TextSpan(
                                            text: 'Terms and Conditions',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                          const TextSpan(text: ' and '),
                                          TextSpan(
                                            text: 'Food Safety Guidelines',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                          const TextSpan(
                                            text:
                                                '. I certify that my kitchen maintains high hygiene standards.',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Submit Button
                            Container(
                              width: double.infinity,
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
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _handleSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: const [
                                          Text(
                                            'Submit Kitchen Details',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(
                                            Icons.chevron_right,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Review Notice
                            Text(
                              'Your application will be reviewed within 24-48 hours.',
                              style: TextStyle(
                                fontSize: 12,
                                color: subtextColor.withValues(alpha: 0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 40),
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
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subtextColor,
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
        style: TextStyle(fontSize: 16, color: textColor),
        decoration: InputDecoration(
          filled: true,
          fillColor: cardColor,
          hintText: hint,
          hintStyle: TextStyle(color: subtextColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
