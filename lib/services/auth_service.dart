import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/supabase_config.dart';

/// Authentication Service
/// Handles phone-based authentication with OTP (mock implementation)
class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Stream controller for auth state changes
  final _authStateController = StreamController<bool>.broadcast();
  Stream<bool> get authStateChanges => _authStateController.stream;

  // Current authenticated phone number
  String? _currentPhone;
  String? get currentPhone => _currentPhone;

  // Mock OTP for testing (in real app, this would come from backend)
  String _generatedOtp = '';

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;

    // If rememberMe is false, we don't auto-login even if data exists
    if (!rememberMe) return false;

    _currentPhone = prefs.getString('phone_number');
    return _currentPhone != null;
  }

  /// Validate phone number format
  bool isValidPhoneNumber(String phone) {
    // Remove any spaces or special characters
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Check if it's a valid Indian phone number
    // Should be +91 followed by 10 digits
    final regex = RegExp(r'^\+91[6-9]\d{9}$');
    return regex.hasMatch(cleaned);
  }

  /// Send OTP to phone number (mock implementation)
  /// In a real app, this would call a backend API
  Future<bool> sendOtp(String phoneNumber) async {
    try {
      // Validate phone number
      if (!isValidPhoneNumber(phoneNumber)) {
        throw Exception('Invalid phone number format');
      }

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Generate a random 6-digit OTP
      _generatedOtp = '123456'; // For demo, using fixed OTP

      // In a real app, this OTP would be sent via SMS
      debugPrint('OTP sent to $phoneNumber: $_generatedOtp');

      return true;
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      return false;
    }
  }

  /// Verify OTP (mock implementation)
  /// In a real app, this would verify with backend
  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Check if OTP matches
      if (otp == _generatedOtp) {
        // Save phone number to local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('phone_number', phoneNumber);

        _currentPhone = phoneNumber;
        _authStateController.add(true);

        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      return false;
    }
  }

  /// Check if user has completed profile setup
  Future<bool> hasCompletedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('profile_completed') ?? false;
  }

  /// Mark profile as completed
  Future<void> markProfileCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('profile_completed', true);
  }

  /// Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _currentPhone = null;
    _authStateController.add(false);
  }

  /// Login with email and password against cooks table
  /// Returns (success, message, cookData) tuple
  Future<({bool success, String message, Map<String, dynamic>? cookData})> loginWithEmail(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      // Query cooks table for matching email
      final result = await supabase
          .from('cooks')
          .select()
          .eq('email', email.trim().toLowerCase())
          .maybeSingle();

      if (result == null) {
        return (success: false, message: 'No account found with this email', cookData: null);
      }

      // Check password
      if (result['password'] != password) {
        return (success: false, message: 'Incorrect password', cookData: null);
      }

      // Check approval status from kitchen_applications table (admin DB)
      final kitchenAppsClient = SupabaseConfig.kitchenAppsClient;
      final appResult = await kitchenAppsClient
          .from('kitchen_applications')
          .select('status')
          .eq('email', email.trim().toLowerCase())
          .maybeSingle();

      final status = (appResult?['status'] ?? 'PENDING').toString().toUpperCase();
      if (status == 'PENDING') {
        return (success: false, message: 'Your account is still under review. Please wait for admin approval.', cookData: null);
      }
      if (status == 'REJECTED') {
        return (success: false, message: 'Your application was rejected. Please contact support.', cookData: null);
      }
      if (status != 'APPROVED') {
        return (success: false, message: 'Account status: $status. Please contact support.', cookData: null);
      }

      // Save login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('phone_number', result['phone'] ?? '');
      await prefs.setString('cook_email', email.trim().toLowerCase());
      await prefs.setString('cook_data', jsonEncode(result));
      await prefs.setBool('profile_completed', true);
      await prefs.setBool('remember_me', rememberMe);

      _currentPhone = result['phone'];
      _authStateController.add(true);

      return (success: true, message: 'Login successful', cookData: result);
    } catch (e) {
      debugPrint('Login error: $e');
      return (success: false, message: 'Login failed: ${e.toString()}', cookData: null);
    }
  }

  /// Get saved cook data
  Future<Map<String, dynamic>?> getSavedCookData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('cook_data');
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}
