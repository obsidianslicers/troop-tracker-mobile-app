import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tt_mobile_app/app.dart';
import 'package:tt_mobile_app/config/app_config.dart';
import 'package:tt_mobile_app/views/splash_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('initializeServices', () {
    test('loads the environment, then Firebase, then push notifications', () async {
      final steps = <String>[];

      await initializeServices(
        loadEnv: () async => steps.add('env'),
        initializeFirebase: () async => steps.add('firebase'),
        initializePush: () async => steps.add('push'),
      );

      expect(steps, ['env', 'firebase', 'push']);
    });

    test('does not wait for push notifications, and survives their failure', () async {
      var finished = false;

      await initializeServices(
        loadEnv: () async {},
        initializeFirebase: () async {},
        initializePush: () async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          finished = true;
          throw Exception('APNS unavailable');
        },
      );

      expect(finished, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(finished, isTrue);
    });

    test('uses the bundled .env and the real Firebase by default', () async {
      TestFirebaseCoreHostApi.setUp(_FirebaseWithoutNativeApps());

      await initializeServices();

      expect(dotenv.isInitialized, isTrue);
      expect(Firebase.apps.single.options.projectId, 'troop-tracker-dfd22');
      expect(AppConfig.trackerUrl, isNotEmpty);
    });
  });

  group('TroopTrackerApp', () {
    testWidgets('uses the dark brand theme', (tester) async {
      await tester.pumpWidget(const TroopTrackerApp(home: Text('Home')));

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.title, 'Troop Tracker');
      expect(app.debugShowCheckedModeBanner, isFalse);
      expect(app.theme!.colorScheme.brightness, Brightness.dark);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('opens on the splash screen', (tester) async {
      await tester.pumpWidget(const TroopTrackerApp());

      expect(find.byType(SplashView), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });
  });
}

/// Firebase as a fresh install sees it: no app configured natively yet.
class _FirebaseWithoutNativeApps implements TestFirebaseCoreHostApi {
  @override
  Future<CoreInitializeResponse> initializeApp(String appName, CoreFirebaseOptions options) async =>
      CoreInitializeResponse(name: appName, options: options, pluginConstants: {});

  @override
  Future<List<CoreInitializeResponse>> initializeCore() async => [];

  @override
  Future<CoreFirebaseOptions> optionsFromResource() => throw UnimplementedError();
}
