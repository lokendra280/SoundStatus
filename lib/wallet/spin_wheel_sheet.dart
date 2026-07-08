import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/core/widget/theme.dart';
import 'package:soundstatus/wallet/states/wallet_presenter.dart';

class SpinWheelSheet extends ConsumerStatefulWidget {
  const SpinWheelSheet({super.key});

  @override
  ConsumerState<SpinWheelSheet> createState() => _SpinWheelSheetState();
}

class _SpinWheelSheetState extends ConsumerState<SpinWheelSheet>
    with SingleTickerProviderStateMixin {
  static const _segments = [1, 2, 3, 4, 5, 10];
  static const _colors = [
    Color(0xFF534AB7),
    Color(0xFF38BDF8),
    Color(0xFF6C63FF),
    Color(0xFF0F6E56),
    Color(0xFFBA7517),
    Color(0xFFF43F5E),
  ];

  late final AnimationController _ctrl;
  Animation<double>? _anim;
  bool _spinning = false;
  int? _prize;

  // ── Sound ────────────────────────────────────────────
  // Pool of players so rapid ticks can overlap instead of cutting off.
  late final List<AudioPlayer> _tickPool;
  int _tickIndex = 0;
  late final AudioPlayer _winPlayer;
  int _lastBoundary = 0; // how many segment boundaries have passed the pointer

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..addListener(_onWheelTick);

    _tickPool = List.generate(
      4,
      (_) => AudioPlayer()..setPlayerMode(PlayerMode.lowLatency),
    );
    _winPlayer = AudioPlayer();
    // Preload so the very first tick isn't late
    for (final p in _tickPool) {
      p.setSource(AssetSource('sounds/spin_tick.wav'));
    }
    _winPlayer.setSource(AssetSource('sounds/spin_win.wav'));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    for (final p in _tickPool) {
      p.dispose();
    }
    _winPlayer.dispose();
    super.dispose();
  }

  // Fires every animation frame: play a tick each time a segment edge
  // crosses the pointer. Because the curve decelerates, ticks start as a
  // rapid clatter and slow to a final clack — just like a real wheel.
  void _onWheelTick() {
    final angle = _anim?.value ?? 0;
    final segAngle = 2 * math.pi / _segments.length;
    final boundariesPassed = (angle / segAngle).floor();
    if (boundariesPassed > _lastBoundary) {
      _lastBoundary = boundariesPassed;
      _playTick();
    }
  }

  void _playTick() {
    final p = _tickPool[_tickIndex];
    _tickIndex = (_tickIndex + 1) % _tickPool.length;
    p.stop();
    p.play(AssetSource('sounds/spin_tick.wav'), volume: 0.6);
    HapticFeedback.selectionClick(); // subtle physical tick too
  }

  Future<void> _spin() async {
    if (_spinning) return;
    setState(() {
      _spinning = true;
      _prize = null;
    });

    // 1. Server decides the prize first
    final outcome = await ref
        .read(walletPresenterProvider.notifier)
        .claimDailySpin();

    if (!mounted) return;

    if (outcome.result == SpinResult.alreadySpun) {
      setState(() => _spinning = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You already spun today — come back tomorrow!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (outcome.result == SpinResult.error) {
      setState(() => _spinning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Spin failed. Try again.'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 2. Animate to the server's prize
    final index = _segments.indexOf(outcome.prize);
    final segAngle = 2 * math.pi / _segments.length;
    final target =
        (5 * 2 * math.pi) +
        (2 * math.pi - (index * segAngle + segAngle / 2)) -
        math.pi / 2;

    _lastBoundary = 0; // reset tick counter for this spin
    _anim = Tween<double>(
      begin: 0,
      end: target,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutQuart));
    _ctrl.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      _winPlayer.stop();
      _winPlayer.play(AssetSource('sounds/spin_win.wav'), volume: 0.8);
      HapticFeedback.mediumImpact();
      setState(() {
        _spinning = false;
        _prize = outcome.prize;
      });
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: c.borderStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _prize != null ? 'You won $_prize coins! 🎉' : 'Daily Spin',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _prize != null ? 'Added to your wallet' : 'One free spin every day',
            style: TextStyle(fontSize: 12, color: c.textMuted),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 240,
            height: 250,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: 10,
                  child: AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, __) => Transform.rotate(
                      angle: _anim?.value ?? 0,
                      child: CustomPaint(
                        size: const Size(240, 240),
                        painter: _WheelPainter(
                          segments: _segments,
                          colors: _colors,
                        ),
                      ),
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 44,
                  color: AppColors.yellow,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _spinning || _prize != null ? null : _spin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primaryColor.withOpacity(
                  0.4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _prize != null
                    ? 'Come back tomorrow'
                    : _spinning
                    ? 'Spinning...'
                    : 'SPIN 🎡',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (_prize != null)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: TextStyle(color: c.textMuted, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<int> segments;
  final List<Color> colors;
  _WheelPainter({required this.segments, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segAngle = 2 * math.pi / segments.length;

    for (var i = 0; i < segments.length; i++) {
      final paint = Paint()..color = colors[i % colors.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * segAngle,
        segAngle,
        true,
        paint,
      );
      final labelAngle = i * segAngle + segAngle / 2;
      final labelPos = Offset(
        center.dx + math.cos(labelAngle) * radius * 0.65,
        center.dy + math.sin(labelAngle) * radius * 0.65,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '${segments[i]}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, labelPos - Offset(tp.width / 2, tp.height / 2));
    }

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = Colors.white.withOpacity(0.9),
    );
    canvas.drawCircle(center, 18, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      18,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF534AB7),
    );
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) => false;
}
