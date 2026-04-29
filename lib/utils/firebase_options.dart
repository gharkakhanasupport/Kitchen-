import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return iOS;
      case TargetPlatform.macOS:
        return macOs;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'check that you have added values for each platform.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyAgYbIr98kebexcqgmXqlkLdnscVs8l2WI",
    appId: "1:471367005406:web:kitchen",
    messagingSenderId: "471367005406",
    projectId: "gharkakhana-6f013",
    authDomain: "gharkakhana-6f013.firebaseapp.com",
    storageBucket: "gharkakhana-6f013.firebasestorage.app",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyAgYbIr98kebexcqgmXqlkLdnscVs8l2WI",
    appId: "1:471367005406:android:8e16bf6b1ab71365ce3e4f",
    messagingSenderId: "471367005406",
    projectId: "gharkakhana-6f013",
    storageBucket: "gharkakhana-6f013.firebasestorage.app",
  );

  static const FirebaseOptions iOS = FirebaseOptions(
    apiKey: "AIzaSyAgYbIr98kebexcqgmXqlkLdnscVs8l2WI",
    appId: "1:471367005406:ios:kitchen",
    messagingSenderId: "471367005406",
    projectId: "gharkakhana-6f013",
    storageBucket: "gharkakhana-6f013.firebasestorage.app",
    iosBundleId: "com.gharkakhana.kitchen",
  );

  static const FirebaseOptions macOs = FirebaseOptions(
    apiKey: "AIzaSyAgYbIr98kebexcqgmXqlkLdnscVs8l2WI",
    appId: "1:471367005406:ios:kitchen",
    messagingSenderId: "471367005406",
    projectId: "gharkakhana-6f013",
    storageBucket: "gharkakhana-6f013.firebasestorage.app",
    iosBundleId: "com.gharkakhana.kitchen",
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: "AIzaSyAgYbIr98kebexcqgmXqlkLdnscVs8l2WI",
    appId: "1:471367005406:web:kitchen",
    messagingSenderId: "471367005406",
    projectId: "gharkakhana-6f013",
    storageBucket: "gharkakhana-6f013.firebasestorage.app",
  );
}
