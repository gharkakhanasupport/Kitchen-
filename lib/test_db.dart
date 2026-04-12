import 'dart:io';

void main() {
  var envFile = File('lib/core/constants/supabase_config.dart');
  if (envFile.existsSync()) {
    print(envFile.readAsStringSync());
  } else {
    print('Not found supabase config');
  }
}
