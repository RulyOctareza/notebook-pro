// File generated manually from Firebase CLI sdkconfig for project notebook-pro-app.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      case TargetPlatform.iOS:
        return macos;
      case TargetPlatform.android:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for android — '
          'run flutterfire configure to add support.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCGOfDnfyQWGTDZ6P9DSxfmifir4sv0-SY',
    appId: '1:273656560091:web:d91cbaf0d9dc412009cffe',
    messagingSenderId: '273656560091',
    projectId: 'notebook-pro-app',
    authDomain: 'notebook-pro-app.firebaseapp.com',
    storageBucket: 'notebook-pro-app.firebasestorage.app',
  );

  /// Apple / macOS app registered as iOS in Firebase Console.
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB9p53_3L6AsGTU0dPZpktILUsKqaJGPtA',
    appId: '1:273656560091:ios:ef05783ff454d4bf09cffe',
    messagingSenderId: '273656560091',
    projectId: 'notebook-pro-app',
    storageBucket: 'notebook-pro-app.firebasestorage.app',
    iosBundleId: 'com.notebookpro.notebookPro',
    iosClientId:
        '273656560091-35sbjjsjpp5r6vglpsld1002migoegd7.apps.googleusercontent.com',
  );

  /// Desktop fallbacks use the web app config until platform apps are added.
  static const FirebaseOptions windows = web;
  static const FirebaseOptions linux = web;
}
