import 'dart:io';
import 'package:flutter/foundation.dart';

void main() {
  var envFile = File('lib/core/constants/supabase_config.dart');
  if (envFile.existsSync()) {
    debugPrint(envFile.readAsStringSync());
  } else {
    debugPrint('Not found supabase config');
  }
}
