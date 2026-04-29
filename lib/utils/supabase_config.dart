import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Helper to safely read dotenv values (returns null if dotenv isn't loaded)
String? _env(String key) {
  try {
    return dotenv.env[key];
  } catch (_) {
    return null;
  }
}

class SupabaseConfig {
  // Cloud Kitchen Database (cooks table, signup data)
  static String get url =>
      _env('SUPABASE_URL') ?? 'https://yvbjnuobnxekgibfqsmq.supabase.co';
  static String get anonKey =>
      _env('SUPABASE_ANON_KEY') ??
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl2YmpudW9ibnhla2dpYmZxc21xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUzOTY1NzIsImV4cCI6MjA5MDk3MjU3Mn0.Hf5zPb8urWQq155fUxF7kQIGFb0NyWphdMyeRI83vgk';

  // Kitchen Applications Database (admin approval status) - Using Admin DB
  static String get kitchenAppsUrl =>
      _env('ADMIN_SUPABASE_URL') ?? 'https://jqqzkazdjmiieyidnldm.supabase.co';
  static String get kitchenAppsAnonKey =>
      _env('ADMIN_SUPABASE_ANON_KEY') ??
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpxcXprYXpkam1paWV5aWRubGRtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc3MjIxMDgsImV4cCI6MjA4MzI5ODEwOH0.0uHK5y35YgpL3UXTuqPnWQiEb20PlzsituNf95SOvkA';

  // User Database (sync target - user app reads from here)
  static String get userDbUrl =>
      _env('USER_SUPABASE_URL') ?? 'https://mwnpwuxrbaousgwgoyco.supabase.co';
  static String get userDbAnonKey =>
      _env('USER_SUPABASE_ANON_KEY') ??
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im13bnB3dXhyYmFvdXNnd2dveWNvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc5ODU2MzYsImV4cCI6MjA4MzU2MTYzNn0.dTM9rguaiuHbrr59iPUsM5znDzXhOdRXbPQ11yOfZpM';

  static SupabaseClient get client => Supabase.instance.client;

  // Separate client for kitchen applications DB
  static SupabaseClient? _kitchenAppsClient;
  static SupabaseClient get kitchenAppsClient {
    _kitchenAppsClient ??= SupabaseClient(kitchenAppsUrl, kitchenAppsAnonKey);
    return _kitchenAppsClient!;
  }

  // Separate client for user DB (sync target)
  static SupabaseClient? _userDbClient;
  static SupabaseClient get userDbClient {
    _userDbClient ??= SupabaseClient(userDbUrl, userDbAnonKey);
    return _userDbClient!;
  }
}
