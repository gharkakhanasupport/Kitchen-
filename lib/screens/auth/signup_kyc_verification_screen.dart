import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/constants.dart';
import 'signup_kitchen_details_screen.dart';

/// Sign Up: KYC Verification Screen (Step 2 of 3)
/// Allows users to upload Aadhar and PAN card documents for verification
class SignUpKycVerificationScreen extends StatefulWidget {
  final Map<String, dynamic> personalDetails;

  const SignUpKycVerificationScreen({super.key, required this.personalDetails});

  @override
  State<SignUpKycVerificationScreen> createState() =>
      _SignUpKycVerificationScreenState();
}

class _SignUpKycVerificationScreenState
    extends State<SignUpKycVerificationScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();

  File? _aadharFront;
  File? _aadharBack;
  File? _panCard;

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

    _progressAnimation = Tween<double>(begin: 0.33, end: 0.66).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String documentType) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          switch (documentType) {
            case 'aadhar_front':
              _aadharFront = File(image.path);
              break;
            case 'aadhar_back':
              _aadharBack = File(image.path);
              break;
            case 'pan':
              _panCard = File(image.path);
              break;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleNext() {
    // Collect KYC details
    final kycDetails = {
      'aadharFront': _aadharFront?.path,
      'aadharBack': _aadharBack?.path,
      'panCard': _panCard?.path,
      'skipped': false,
    };

    // Navigate to Step 3: Kitchen Details
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignUpKitchenDetailsScreen(
          personalDetails: widget.personalDetails,
          kycDetails: kycDetails,
        ),
      ),
    );
  }

  void _handleSkip() {
    // Skip KYC - navigate to Step 3 with skipped status
    final kycDetails = {
      'aadharFront': null,
      'aadharBack': null,
      'panCard': null,
      'skipped': true,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignUpKitchenDetailsScreen(
          personalDetails: widget.personalDetails,
          kycDetails: kycDetails,
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor.withValues(alpha: 0.8),
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: Icon(Icons.arrow_back, color: textColor, size: 20),
                    ),
                  ),
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
                  const SizedBox(width: 40),
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
                          'KYC Verification',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Step 2 of 3',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: subtextColor,
                          ),
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

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),

                          // Headline
                          Text(
                            'Verify your identity',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This step is optional but helps build trust with your customers and ensures a safer marketplace.',
                            style: TextStyle(
                              fontSize: 16,
                              color: subtextColor,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Aadhar Card Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Aadhar Card',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'OPTIONAL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: subtextColor,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: _buildUploadCard(
                                  'Front Side',
                                  'aadhar_front',
                                  _aadharFront,
                                  cardColor,
                                  borderColor,
                                  textColor,
                                  subtextColor,
                                  aspectRatio: 3 / 2,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildUploadCard(
                                  'Back Side',
                                  'aadhar_back',
                                  _aadharBack,
                                  cardColor,
                                  borderColor,
                                  textColor,
                                  subtextColor,
                                  aspectRatio: 3 / 2,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),

                          // PAN Card Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'PAN Card',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'OPTIONAL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: subtextColor,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildUploadCard(
                            'Upload Front Side of PAN Card',
                            'pan',
                            _panCard,
                            cardColor,
                            borderColor,
                            textColor,
                            subtextColor,
                            aspectRatio: 16 / 9,
                            subtitle: 'JPEG or PNG up to 5MB',
                          ),

                          const SizedBox(height: 24),

                          // Pro Tip
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pro Tip',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Home cooks with verified identities receive up to 40% more orders as customers feel more secure.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textColor.withValues(
                                            alpha: 0.8,
                                          ),
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 120),
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

      // Bottom Actions
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(top: BorderSide(color: borderColor, width: 1)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Skip Button
              Expanded(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: OutlinedButton(
                    onPressed: _handleSkip,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: subtextColor,
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Next Button
              Expanded(
                flex: 2,
                child: Container(
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
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCard(
    String label,
    String documentType,
    File? uploadedFile,
    Color cardColor,
    Color borderColor,
    Color textColor,
    Color subtextColor, {
    double aspectRatio = 3 / 2,
    String? subtitle,
  }) {
    final hasFile = uploadedFile != null;

    return GestureDetector(
      onTap: () => _pickImage(documentType),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: hasFile ? cardColor : cardColor.withValues(alpha: 0.5),
            border: Border.all(
              color: hasFile ? AppColors.secondary : borderColor,
              width: hasFile ? 2 : 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: hasFile
                ? [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: hasFile
              ? Stack(
                  children: [
                    // Uploaded Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        uploadedFile,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Success Overlay
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppColors.secondary,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Document Uploaded',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      aspectRatio > 2 ? Icons.file_upload : Icons.add_a_photo,
                      color: subtextColor,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: subtextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10,
                          color: subtextColor.withValues(alpha: 0.7),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
