import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/app_config.dart';
import 'firebase_options.dart';
import 'services/push_notification_service.dart';
import 'views/splash_view.dart';

/// Loads .env, starts Firebase and sets up push notifications, before runApp().
/// The defaults are the real services; tests pass stand-ins.
Future<void> initializeServices({
  Future<void> Function()? loadEnv,
  Future<void> Function()? initializeFirebase,
  Future<void> Function()? initializePush,
}) async {
  await (loadEnv ?? () => dotenv.load())();
  await (initializeFirebase ?? _initializeFirebase)();
  // Fire-and-forget: push notification setup (in particular, awaiting the
  // APNS/FCM token on iOS) can stall well past app launch. It must never
  // block reaching runApp(), or the app hangs on the splash screen.
  unawaited(
    (initializePush ?? PushNotificationService.initialize)().catchError((Object e) {
      debugPrint('[FCM] initialize failed: $e');
    }),
  );
}

Future<void> _initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class TroopTrackerApp extends StatelessWidget {
  /// [home] defaults to the splash screen; tests pass a stand-in.
  const TroopTrackerApp({super.key, this.home});

  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConfig.primaryColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: home ?? const SplashView(),
    );
  }
}
