import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../config/app_config.dart';
import '../controllers/splash_controller.dart';
import 'main_shell_view.dart';

/// Flutter-rendered splash screen shown immediately after the native splash.
///
/// Flow:
///   1. FlutterNativeSplash.remove() hands off from the native splash to this view.
///   2. The logo and app name fade in.
///   3. After the minimum display duration, navigation pushes MainShellView.
class SplashView extends StatefulWidget {
  /// [next] builds the screen that replaces the splash; tests pass a stand-in.
  const SplashView({super.key, this.next, this.splashController});

  final WidgetBuilder? next;
  final SplashController? splashController;

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final SplashController _splashController = widget.splashController ?? SplashController();

  @override
  void initState() {
    super.initState();

    // Hand off from native splash — Flutter now owns the screen.
    FlutterNativeSplash.remove();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    unawaited(_animController.forward());

    unawaited(_showNextWhenReady());
  }

  Future<void> _showNextWhenReady() async {
    await _splashController.waitForReady();
    if (!mounted) return;
    final next = widget.next ?? (_) => const MainShellView();
    unawaited(
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (context, animation, _) => next(context),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.splashBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/logo.png',
                width: 140,
                height: 140,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(height: 28),
              const Text(
                AppConfig.appName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
