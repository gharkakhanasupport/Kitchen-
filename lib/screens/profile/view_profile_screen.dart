import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/cook.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';
import '../../utils/supabase_config.dart';

import '../auth/phone_login_screen.dart';
import 'availability_settings_screen.dart';
import 'reviews_screen.dart';
import 'profile_wallet_screen.dart';
import '../issues/issues_screen.dart';

/// View Profile Screen
/// Modern profile screen with counting animations
class ViewProfileScreen extends StatefulWidget {
  const ViewProfileScreen({super.key});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  final _profileService = ProfileService();
  final _authService = AuthService();

  Cook? _cook;
  bool _isLoading = true;
  bool _isUploadingLogo = false;

  // Colors from HTML
  static const Color primaryColor = Color(0xFFc1921a);
  static const Color secondaryColor = Color(0xFF2da832);
  static const Color backgroundLight = Color(0xFFfdf8ef);
  static const Color surfaceLight = Color(0xFFffffff);
  static const Color textMain = Color(0xFF171611);
  static const Color textSub = Color(0xFF877d64);
  static const Color borderLight = Color(0xFFe5e2dc);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    final profile = await _profileService.refreshProfile();

    setState(() {
      _cook = profile;
      _isLoading = false;
    });
  }

  Future<void> _pickAndUploadLogo() async {
    if (_cook == null) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image == null) return;

    setState(() {
      _isUploadingLogo = true;
    });

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${_cook!.id}/logo/kitchen_logo_$timestamp.jpg';
      final bytes = await image.readAsBytes();

      debugPrint('Uploading logo to storage: path=$path, bytes=${bytes.length}');

      // Use upsert to handle re-uploads gracefully
      await SupabaseConfig.client.storage
          .from('kitchen-photos')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = SupabaseConfig.client.storage
          .from('kitchen-photos')
          .getPublicUrl(path);
      
      debugPrint('Generated Logo URL: $url');

      // Update profile in cooks table + sync to both kitchens tables
      final success = await _profileService.updateProfile(profileImageUrl: url);
      
      if (success) {
        // Get updated profile from local cache (already saved by updateProfile)
        // Don't call refreshProfile() here — it would re-query DB and may get
        // stale data before the write propagates.
        final updatedProfile = await _profileService.getCurrentProfile();
        if (mounted) {
          setState(() {
            _cook = updatedProfile;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logo updated successfully!'),
              backgroundColor: secondaryColor,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update profile. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error in _pickAndUploadLogo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading logo: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingLogo = false;
        });
      }
    }
  }

  Future<void> _toggleVegetarian(bool value) async {
    if (_cook == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _profileService.updateProfile(isVegetarian: value);
      if (success) {
        await _loadProfile();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(value ? 'Kitchen is now PURE VEG' : 'Kitchen is now MULTI-CUISINE'),
              backgroundColor: value ? secondaryColor : primaryColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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

  Future<void> _toggleAvailability() async {
    if (_cook == null) return;

    final newStatus = !_cook!.isAvailable;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _profileService.updateProfile(isAvailable: newStatus);
      if (success) {
        final updatedCook = await _profileService.refreshProfile();
        if (updatedCook != null) {
          setState(() {
            _cook = updatedCook;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    newStatus ? 'You are now ONLINE' : 'You are now OFFLINE'),
                backgroundColor: newStatus ? secondaryColor : Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _authService.logout();
      await _profileService.clearProfile();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const PhoneLoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundLight,
        body: const Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    if (_cook == null) {
      return Scaffold(
        backgroundColor: backgroundLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No profile found'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadProfile,
                style: FilledButton.styleFrom(backgroundColor: primaryColor),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with back and settings
            Container(
              color: surfaceLight.withValues(alpha: 0.95),
              padding: const EdgeInsets.only(
                top: 40,
                left: 16,
                right: 16,
                bottom: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: textMain),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'My Kitchen',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textMain,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings, color: textMain),
                    onPressed: _logout,
                  ),
                ],
              ),
            ),

            // Header Image with Profile Photo
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Header Image
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.2,
                          child: Image.network(
                            'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=800',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              backgroundLight.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Profile Photo
                Positioned(
                  bottom: -50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Stack(
                      children: [
                        // Pulse animation
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withValues(alpha: 0.2),
                          ),
                        ),
                        // Profile image
                        InkWell(
                          onTap: _isUploadingLogo ? null : _pickAndUploadLogo,
                          child: Container(
                            width: 128,
                            height: 128,
                            margin: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: surfaceLight, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              color: Colors.grey.shade100,
                            ),
                            child: ClipOval(
                              child: _isUploadingLogo 
                                ? const Center(child: CircularProgressIndicator(color: primaryColor))
                                : _cook!.profileImageUrl != null
                                  ? Image.network(
                                      _cook!.profileImageUrl!,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const Center(child: CircularProgressIndicator(color: primaryColor));
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        debugPrint('Logo Image Error: $error');
                                        return Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.error_outline, color: Colors.red),
                                            Text('Error', style: TextStyle(fontSize: 10, color: Colors.red)),
                                          ],
                                        );
                                      },
                                    )
                                  : const Icon(Icons.add_a_photo, size: 40, color: primaryColor),
                            ),
                          ),
                        ),
                        // Online badge
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: secondaryColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: secondaryColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'OPEN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
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

            const SizedBox(height: 60),

            // Kitchen Name and Details
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _cook!.kitchenName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textMain,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.verified, color: Colors.blue, size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                // Pure Veg Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.eco, 
                      size: 16, 
                      color: _cook!.isVegetarian ? Colors.green : Colors.grey
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Pure Vegetarian',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _cook!.isVegetarian ? Colors.green : textSub,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 24,
                      child: Switch(
                        value: _cook!.isVegetarian,
                        activeColor: Colors.green,
                        onChanged: _isLoading ? null : (value) => _toggleVegetarian(value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Head Chef: ${_cook!.ownerName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textSub,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _cook!.specialty,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            // Online Status Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _cook!.isAvailable 
                      ? [secondaryColor, const Color(0xFF228526)]
                      : [Colors.grey.shade600, Colors.grey.shade700],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (_cook!.isAvailable ? secondaryColor : Colors.grey).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _toggleAvailability,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _cook!.isAvailable ? Icons.toggle_on : Icons.toggle_off, 
                        color: Colors.white, 
                        size: 28
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _cook!.isAvailable ? 'You are Online' : 'You are Offline',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap to stop accepting new orders',
              style: TextStyle(fontSize: 12, color: textSub),
            ),

            const SizedBox(height: 24),

            // Stats Cards with Counting Animation
            if (_cook != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        Icons.star,
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: _cook!.rating),
                          duration: const Duration(seconds: 2),
                          builder: (context, value, child) {
                            return Text(
                              value.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: primaryColor,
                              ),
                            );
                          },
                        ),
                        'Overall Rating',
                        primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        Icons.receipt_long,
                        TweenAnimationBuilder<int>(
                          tween: IntTween(begin: 0, end: _cook!.totalOrders),
                          duration: const Duration(seconds: 2),
                          builder: (context, value, child) {
                            return Text(
                              '$value+',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: textMain,
                              ),
                            );
                          },
                        ),
                        'Total Orders',
                        textMain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        Icons.payments,
                        TweenAnimationBuilder<int>(
                          tween: IntTween(begin: 0, end: _cook!.earnings),
                          duration: const Duration(seconds: 2),
                          builder: (context, value, child) {
                            return Text(
                              '\$$value',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: secondaryColor,
                              ),
                            );
                          },
                        ),
                        'Lifetime Earnings',
                        secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textMain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          Icons.schedule,
                          'Availability',
                          'Set kitchen hours',
                          Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AvailabilitySettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          Icons.account_balance_wallet,
                          'Wallet',
                          'View balance & withdraw',
                          Colors.teal,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ProfileWalletScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickAction(
                          Icons.reviews,
                          'Reviews',
                          'View customer feedback',
                          Colors.purple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ReviewsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          Icons.report_problem,
                          'Issues',
                          'View user complaints',
                          Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const IssuesScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(), // Empty space for symmetry
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Contact Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Contact Info',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textMain,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Edit',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: surfaceLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildContactRow(
                          Icons.call,
                          'Phone Number',
                          _cook!.phoneNumber,
                        ),
                        const Divider(height: 1),
                        _buildContactRow(
                          Icons.mail,
                          'Email Address',
                          _cook!.email,
                        ),
                        const Divider(height: 1),
                        _buildContactRow(
                          Icons.location_on,
                          'Pickup Address',
                          _cook!.address,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Member Since
            const Text(
              'Member since August 2023',
              style: TextStyle(fontSize: 12, color: textSub),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ghar Ka Khana v1.0.4',
              style: TextStyle(fontSize: 10, color: textSub),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    IconData icon,
    Widget valueWidget,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(width: 4),
                valueWidget,
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textSub,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
    IconData icon,
    String title,
    String subtitle,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textMain,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: textSub),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: backgroundLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: textSub, size: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: textSub),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textMain,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
