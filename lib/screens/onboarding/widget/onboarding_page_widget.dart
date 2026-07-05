import 'package:flutter/material.dart';
import 'package:soundstatus/core/widget/theme.dart';

/// One onboarding page: a playfully tilted image card sitting on a soft
/// accent-colored blob, with two floating emoji badges. Fully theme-aware.
class OnboardPageWidget extends StatelessWidget {
  final Color accent;
  final String urlImage;
  final String title;
  final String subtitle;
  final String emojiTop;
  final String emojiBottom;

  const OnboardPageWidget({
    super.key,
    required this.accent,
    required this.urlImage,
    required this.title,
    required this.subtitle,
    this.emojiTop = '🎵',
    this.emojiBottom = '😂',
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Illustration ────────────────────────────────
          SizedBox(
            width: 260,
            height: 260,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Soft tilted blob behind the card
                Transform.rotate(
                  angle: -0.10,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(context.isDark ? 0.22 : 0.14),
                      borderRadius: BorderRadius.circular(56),
                    ),
                  ),
                ),
                // Image card, slightly tilted the other way
                Transform.rotate(
                  angle: 0.04,
                  child: Container(
                    width: 216,
                    height: 216,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: c.border, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.18),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Image.asset(urlImage, fit: BoxFit.contain),
                  ),
                ),
                // Floating emoji badges
                Positioned(
                  top: -14,
                  left: -6,
                  child: Transform.rotate(
                    angle: -0.25,
                    child: _EmojiBadge(emoji: emojiTop),
                  ),
                ),
                Positioned(
                  bottom: -10,
                  right: -4,
                  child: Transform.rotate(
                    angle: 0.20,
                    child: _EmojiBadge(emoji: emojiBottom),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 44),

          // ── Copy ────────────────────────────────────────
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.5, color: c.textSub),
          ),
        ],
      ),
    );
  }
}

class _EmojiBadge extends StatelessWidget {
  final String emoji;
  const _EmojiBadge({required this.emoji});

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.cardElevated,
        shape: BoxShape.circle,
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(context.isDark ? 0.4 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 22)),
    );
  }
}
