import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundstatus/core/constant_assets.dart';
import 'package:soundstatus/providers/profile_provider.dart';
import 'package:soundstatus/providers/streak_provider.dart';
import 'package:soundstatus/screens/sounds/sound_library_screen.dart';
import 'package:soundstatus/screens/sounds/sound_upload_screen.dart';
import 'package:soundstatus/status/create_status_screen.dart';
import 'package:soundstatus/wallet/wallet_screen.dart';
import 'package:soundstatus/widgets/common_svg_widget.dart';

// class HomeScreen extends ConsumerStatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   ConsumerState<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends ConsumerState<HomeScreen> {
//   @override
//   void initState() {
//     super.initState();
//     // Record daily activity for streak
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       ref.read(streakProvider.notifier).recordActivity();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final profile = ref.watch(profileProvider).valueOrNull;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'StatusHub Sound',
//           style: TextStyle(fontWeight: FontWeight.w800),
//         ),
//         actions: [
//           // Coin balance badge
//           // if (profile != null)
//           //   Padding(
//           //     padding: const EdgeInsets.only(right: 16),
//           //     child: CoinBadge(coins: profile.coinBalance),
//           //   ),
//         ],
//       ),
//     );
//   }
// }

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final streak = ref.watch(streakProvider);

    return Scaffold(
      appBar: AppBar(title: Text("Sound"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text(
              'Hey ${profile?.name ?? ''} 👋',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Ready to make some noise?',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),

            const SizedBox(height: 24),

            // Stats row
            Row(
              children: [
                _StatCard(
                  icon: '🔥',
                  label: 'Streak',
                  value: '$streak days',
                  color: Colors.orange.shade50,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: '🎵',
                  label: 'Uploads',
                  value: '${profile?.uploadCount ?? 0}',
                  color: Colors.blue.shade50,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: '📤',
                  label: 'Shares today',
                  value: '${profile?.shareCountToday ?? 0}/5',
                  color: Colors.green.shade50,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Quick actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _QuickAction(
                  icon: Icons.add_rounded,
                  label: 'Create Status',
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateStatusScreen(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _QuickAction(
                  icon: Icons.upload_rounded,
                  label: 'Upload Sound',
                  color: Colors.blue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SoundUploadScreen(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Share limit warning
            if (profile != null && profile.shareCountToday >= 4)
              _ShareLimitBanner(remaining: 5 - profile.shareCountToday),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String icon, label, value;
  final Color color;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ShareLimitBanner extends StatelessWidget {
  final int remaining;
  const _ShareLimitBanner({required this.remaining});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.orange.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.orange.shade200),
    ),
    child: Row(
      children: [
        const Icon(Icons.warning_rounded, color: Colors.orange),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            remaining == 0
                ? 'Daily share limit reached. Watch an ad to earn more shares!'
                : 'Only $remaining free share${remaining == 1 ? "" : "s"} left today.',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _TabItem {
  final String icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}
