import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:soundstatus/core/widget/theme.dart';

/// Worm-style page indicator: the active dot stretches into a pill and the
/// stretch smoothly transfers to the next dot as the user swipes.
///
/// Rewritten as a StatelessWidget driven by AnimatedBuilder(controller) —
/// the old version added a listener in initState and never removed it
/// (memory leak + setState-after-dispose crashes), and positioned dots with
/// manual left-margin math that drifted. AnimatedBuilder subscribes and
/// unsubscribes automatically.
class SmoothPageIndicator extends StatelessWidget {
  final PageController controller;
  final int pageCount;

  /// Inactive dot color. Defaults to the theme's strong border color.
  final Color? color;

  /// Active pill color. Defaults to the brand primary.
  final Color? activeColor;

  final double dotSize;
  final double activeWidth;
  final double spacing;

  const SmoothPageIndicator({
    super.key,
    required this.controller,
    required this.pageCount,
    this.color,
    this.activeColor,
    this.dotSize = 8,
    this.activeWidth = 26,
    this.spacing = 5,
  });

  @override
  Widget build(BuildContext context) {
    final inactive = color ?? context.c.borderStrong;
    final active = activeColor ?? AppColors.primaryColor;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // Safe before the first layout / when detached.
        final page = (controller.hasClients && controller.page != null)
            ? controller.page!
            : controller.initialPage.toDouble();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(pageCount, (i) {
            // 1.0 when this dot is the current page, fading to 0.0 at
            // one full page away — drives both width and color.
            final t = (1.0 - (page - i).abs()).clamp(0.0, 1.0);

            return Container(
              margin: EdgeInsets.symmetric(horizontal: spacing / 2),
              width: lerpDouble(dotSize, activeWidth, t)!,
              height: dotSize,
              decoration: BoxDecoration(
                color: Color.lerp(inactive, active, t),
                borderRadius: BorderRadius.circular(dotSize),
              ),
            );
          }),
        );
      },
    );
  }
}
