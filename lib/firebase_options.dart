import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AppFirebaseOptions {
  // Defaults are safe to embed for web apps (Firebase web config is not a secret).
  // You can still override any value via `--dart-define`.
  static const apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyAxdejfGHRngtgBZsI3TZLu2PB7FRYWwm0',
  );
  static const appId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '1:843078322062:web:13eeda6eeb3e36dcb686df',
  );
  static const webAppId = String.fromEnvironment(
    'FIREBASE_WEB_APP_ID',
    defaultValue: appId,
  );
  static const androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
    defaultValue: appId,
  );
  static const iosAppId = String.fromEnvironment(
    'FIREBASE_IOS_APP_ID',
    defaultValue: appId,
  );
  static const messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '843078322062',
  );
  static const projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'albuhairaalarabia2026',
  );
  static const storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'albuhairaalarabia2026.firebasestorage.app',
  );
  static const authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: 'albuhairaalarabia2026.firebaseapp.com',
  );
  static const measurementId = String.fromEnvironment(
    'FIREBASE_MEASUREMENT_ID',
    defaultValue: 'G-PXKW92DMB2',
  );
  static const iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');
  static const webVapidKey = String.fromEnvironment('FIREBASE_WEB_VAPID_KEY');

  static bool get isConfigured {
    return apiKey.isNotEmpty &&
        webAppId.isNotEmpty &&
        messagingSenderId.isNotEmpty &&
        projectId.isNotEmpty &&
        storageBucket.isNotEmpty;
  }

  static FirebaseOptions get currentPlatform {
    if (!isConfigured) {
      throw StateError(
        'Firebase is not configured. Pass FIREBASE_API_KEY, FIREBASE_APP_ID, '
        'FIREBASE_MESSAGING_SENDER_ID, FIREBASE_PROJECT_ID, and '
        'FIREBASE_STORAGE_BUCKET using --dart-define.',
      );
    }

    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: apiKey,
        appId: webAppId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        storageBucket: storageBucket,
        authDomain: authDomain,
        measurementId: measurementId,
      );
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: defaultTargetPlatform == TargetPlatform.iOS
          ? iosAppId
          : androidAppId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: storageBucket,
      iosBundleId: iosBundleId,
    );
  }
}
