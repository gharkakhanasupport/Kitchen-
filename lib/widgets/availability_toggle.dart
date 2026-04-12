import 'package:flutter/material.dart';
import '../../services/profile_service.dart';
import '../../utils/constants.dart';

/// Availability Toggle Widget
/// Allows cooks to toggle their online/offline status
class AvailabilityToggle extends StatefulWidget {
  const AvailabilityToggle({super.key});

  @override
  State<AvailabilityToggle> createState() => _AvailabilityToggleState();
}

class _AvailabilityToggleState extends State<AvailabilityToggle> {
  final _profileService = ProfileService();
  bool _isAvailable = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final status = await _profileService.getAvailabilityStatus();
    setState(() {
      _isAvailable = status;
      _isLoading = false;
    });
  }

  Future<void> _toggleAvailability(bool value) async {
    setState(() {
      _isLoading = true;
    });

    final success = await _profileService.toggleAvailability();

    if (success) {
      setState(() {
        _isAvailable = value;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'You are now online' : 'You are now offline'),
            backgroundColor: value ? AppColors.success : AppColors.warning,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: _isAvailable
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: _isAvailable ? AppColors.success : AppColors.warning,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isAvailable ? Icons.check_circle : Icons.cancel,
            color: _isAvailable ? AppColors.success : AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            _isAvailable ? 'Online' : 'Offline',
            style: AppTextStyles.labelLarge.copyWith(
              color: _isAvailable ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Switch(
            value: _isAvailable,
            onChanged: _toggleAvailability,
            activeThumbColor: AppColors.success,
          ),
        ],
      ),
    );
  }
}
