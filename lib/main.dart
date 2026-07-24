import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'config/app_config.dart';
import 'firebase_options.dart';
import 'services/push_notification_service.dart';
import 'views/splash_view.dart';

void main() async {
  // Hold the native splash on screen until SplashView calls remove().
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Fire-and-forget: push notification setup (in particular, awaiting the
  // APNS/FCM token on iOS) can stall well past app launch. It must never
  // block reaching runApp(), or the app hangs on the splash screen.
  unawaited(
    PushNotificationService.initialize().catchError((e) {
      debugPrint('[FCM] initialize failed: $e');
    }),
  );

  runApp(const TroopTrackerApp());
}

class TroopTrackerApp extends StatelessWidget {
  const TroopTrackerApp({super.key});

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
      home: const SplashView(),
    );
  }
}
