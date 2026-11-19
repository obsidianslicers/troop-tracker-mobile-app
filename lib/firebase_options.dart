// File generated from google-services.json and GoogleService-Info.plist.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web is not supported.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDhoxKW7ZrIsP77aSqC8MZu2yOklme-ex0',
    appId: '1:629954663757:android:5b3ec93d6f3ce917009304',
    messagingSenderId: '629954663757',
    projectId: 'troop-tracker-dfd22',
    storageBucket: 'troop-tracker-dfd22.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCHpt2p7rX012AoUzvhJDaXcDaU1bPAwGg',
    appId: '1:629954663757:ios:0fd3d6e650db5015009304',
    messagingSenderId: '629954663757',
    projectId: 'troop-tracker-dfd22',
    storageBucket: 'troop-tracker-dfd22.firebasestorage.app',
    iosBundleId: 'com.drennansoftware.ttMobileApp',
  );
}
