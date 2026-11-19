import 'package:flutter/material.dart';

/// Lightsaber-style loading bar shown while the WebView loads a page.
///
/// Renders a glowing blue beam that grows left-to-right with a pulsing
/// tip glow. Positioned at the bottom of the content area (not the top
/// like a browser bar) to feel native rather than web-like.
class LoadingOverlay extends StatefulWidget {
  final double progress;
  final bool isVisible;

  const LoadingOverlay({
    super.key,
    required this.progress,
    required this.isVisible,
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    // Use a minimum visual width so the bar is always visible even at 0%
    final fillFraction = widget.progress > 0.02 ? widget.progress : 0.02;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) {
        // Pulse the outer glow radius between 6 and 14
        final outerGlow = 6.0 + (_pulseAnim.value * 8.0);
        // Pulse the inner glow radius between 2 and 5
        final innerGlow = 2.0 + (_pulseAnim.value * 3.0);

        return SizedBox(
          height: 4,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final fillWidth = totalWidth * fillFraction;

              return Stack(
                children: [
                  // Dim track
                  Container(
                    height: 4,
                    color: const Color(0xFF001F33),
                  ),

                  // Lightsaber beam
                  Container(
                    width: fillWidth,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF003A66), // hilt — deep navy blue
                          Color(0xFF0077CC), // mid blade
                          Color(0xFF00AAFF), // bright blade
                          Color(0xFFCCEEFF), // tip — near white
                        ],
                        stops: [0.0, 0.55, 0.85, 1.0],
                      ),
                      boxShadow: [
                        // Core tight glow at the tip
                        BoxShadow(
                          color: const Color(0xFF66CCFF).withValues(alpha: 0.95),
                          blurRadius: innerGlow,
                          spreadRadius: 0,
                        ),
                        // Wide ambient glow
                        BoxShadow(
                          color: const Color(0xFF0099FF).withValues(alpha: 0.55),
                          blurRadius: outerGlow,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),

                  // Bright flare at the leading tip
                  Positioned(
                    left: fillWidth - 6,
                    top: 0,
                    child: Container(
                      width: 6,
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.6 + _pulseAnim.value * 0.4),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.6),
                            blurRadius: innerGlow * 1.5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
