// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:soundstatus/models/sound_model.dart';
// import 'package:soundstatus/providers/sound_library_provider.dart';
// import 'package:soundstatus/screens/sounds/states/sound_library_presenter.dart';
// import 'package:soundstatus/screens/sounds/widgets/share_bottom_widget.dart';
// import 'package:soundstatus/screens/sounds/widgets/insufficientCoinSheet.dart';
// import 'package:soundstatus/providers/profile_provider.dart';

// // ── Colors ────────────────────────────────────────────────────────
// const _bg = Color(0xFF0D0D0D);
// const _surface = Color(0xFF1A1A1A);
// const _card = Color(0xFF1E1E1E);
// const _purple = Color(0xFF7C3AED);
// const _purpleL = Color(0xFF9B59F5);
// const _white = Colors.white;

// class SoundHomePage extends ConsumerStatefulWidget {
//   const SoundHomePage({super.key});
//   @override
//   ConsumerState<SoundHomePage> createState() => _SoundHomePageState();
// }

// class _SoundHomePageState extends ConsumerState<SoundHomePage> {
//   final _searchCtrl = TextEditingController();
//   int _bannerIdx = 0;

//   static const _categories = [
//     ('😂', 'Funny'),
//     ('🇳🇵', 'Nepali'),
//     ('🇮🇳', 'Indian'),
//     ('🎬', 'Movies'),
//     ('🎵', 'Reels'),
//     ('🎮', 'Gaming'),
//   ];

//   static const _creators = [
//     ('MemeKing', '2.3M'),
//     ('SoundPro', '1.8M'),
//     ('ViralGuy', '1.6M'),
//     ('DesiMemer', '1.2M'),
//     ('NepaliVibes', '980K'),
//   ];

//   @override
//   void dispose() {
//     _searchCtrl.dispose();
//     super.dispose();
//   }

//   String get _greeting {
//     final h = DateTime.now().hour;
//     if (h < 12) return 'Good Morning! 👋';
//     if (h < 17) return 'Good Afternoon! 👋';
//     return 'Good Evening! 👋';
//   }

//   @override
//   Widget build(BuildContext context) {
//     final sounds = ref.watch(soundLibraryProvider);
//         final playback = ref.watch(playbackPresenterProvider);

//     final isLoading = playback.isLoading && playback.playingSoundId == sound.id;

//     return Scaffold(
//       backgroundColor: _bg,
//       body: SafeArea(
//         child: CustomScrollView(
//           physics: const BouncingScrollPhysics(),
//           slivers: [
//             // ── Header ────────────────────────────────────────────
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             _greeting,
//                             style: const TextStyle(
//                               color: Colors.white70,
//                               fontSize: 13,
//                             ),
//                           ),
//                           const SizedBox(height: 2),
//                           RichText(
//                             text: const TextSpan(
//                               style: TextStyle(
//                                 fontSize: 26,
//                                 fontWeight: FontWeight.w800,
//                               ),
//                               children: [
//                                 TextSpan(
//                                   text: 'Sound',
//                                   style: TextStyle(color: _white),
//                                 ),
//                                 TextSpan(
//                                   text: 'Adda',
//                                   style: TextStyle(color: _purpleL),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(height: 2),
//                           const Text(
//                             'Discover Viral Meme Sounds',
//                             style: TextStyle(
//                               color: Colors.white38,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     // Bell
//                     Stack(
//                       children: [
//                         IconButton(
//                           icon: const Icon(
//                             Icons.notifications_outlined,
//                             color: _white,
//                             size: 24,
//                           ),
//                           onPressed: () {},
//                         ),
//                         Positioned(
//                           top: 10,
//                           right: 10,
//                           child: Container(
//                             width: 8,
//                             height: 8,
//                             decoration: const BoxDecoration(
//                               color: _purpleL,
//                               shape: BoxShape.circle,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(width: 4),
//                     // Avatar
//                     Container(
//                       width: 42,
//                       height: 42,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         border: Border.all(color: _purple, width: 2),
//                         color: _surface,
//                       ),
//                       child: const Icon(
//                         Icons.person_rounded,
//                         color: Colors.white54,
//                         size: 22,
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                   ],
//                 ),
//               ),
//             ),

//             // ── Search bar ────────────────────────────────────────
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
//                 child: Container(
//                   height: 46,
//                   decoration: BoxDecoration(
//                     color: _surface,
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                   child: Row(
//                     children: [
//                       const SizedBox(width: 14),
//                       const Icon(
//                         Icons.search_rounded,
//                         color: Colors.white38,
//                         size: 20,
//                       ),
//                       const SizedBox(width: 10),
//                       Expanded(
//                         child: TextField(
//                           controller: _searchCtrl,
//                           style: const TextStyle(color: _white, fontSize: 13),
//                           decoration: const InputDecoration(
//                             hintText: 'Search meme sounds, dialogues...',
//                             hintStyle: TextStyle(
//                               color: Colors.white38,
//                               fontSize: 13,
//                             ),
//                             border: InputBorder.none,
//                             isDense: true,
//                           ),
//                           onChanged: (v) => ref
//                               .read(soundLibraryProvider.notifier)
//                               .setFilter(SoundFilter.all),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Container(width: 1, height: 20, color: Colors.white12),
//                       const SizedBox(width: 10),
//                       const Icon(
//                         Icons.tune_rounded,
//                         color: Colors.white54,
//                         size: 20,
//                       ),
//                       const SizedBox(width: 14),
//                     ],
//                   ),
//                 ),
//               ),
//             ),

//             // ── Banner carousel ───────────────────────────────────
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
//                 child: Column(
//                   children: [
//                     SizedBox(
//                       height: 180,
//                       child: PageView.builder(
//                         onPageChanged: (i) => setState(() => _bannerIdx = i),
//                         itemCount: 3,
//                         itemBuilder: (_, i) => _BannerCard(index: i),
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: List.generate(
//                         3,
//                         (i) => AnimatedContainer(
//                           duration: const Duration(milliseconds: 250),
//                           width: _bannerIdx == i ? 20 : 6,
//                           height: 6,
//                           margin: const EdgeInsets.only(right: 4),
//                           decoration: BoxDecoration(
//                             color: _bannerIdx == i ? _purple : Colors.white24,
//                             borderRadius: BorderRadius.circular(3),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             // ── Category chips ────────────────────────────────────
//             SliverToBoxAdapter(
//               child: SizedBox(
//                 height: 52,
//                 child: ListView(
//                   scrollDirection: Axis.horizontal,
//                   padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
//                   children: _categories
//                       .map((c) => _CategoryChip(emoji: c.$1, label: c.$2))
//                       .toList(),
//                 ),
//               ),
//             ),

//             // ── Trending Sounds ───────────────────────────────────
//             SliverToBoxAdapter(
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
//                 child: _SectionHeader('🔥 Trending Sounds', onSeeAll: () {}),
//               ),
//             ),

//             SliverToBoxAdapter(
//               child: sounds.when(
//                 loading: () => const SizedBox(
//                   height: 200,
//                   child: Center(
//                     child: CircularProgressIndicator(
//                       color: _purple,
//                       strokeWidth: 2,
//                     ),
//                   ),
//                 ),
//                 error: (_, __) => const _ErrorWidget(),
//                 data: (list) => _TrendingList(
//                   sounds: list.take(3).toList(),
//                   onShare: (s) => _share(s),
//                 ),
//               ),
//             ),

//             // ── Popular Creators ──────────────────────────────────
//             // SliverToBoxAdapter(
//             //   child: Padding(
//             //     padding: const EdgeInsets.fromLTRB(16, 24, 16, 14),
//             //     child: _SectionHeader('⭐ Popular Creators', onSeeAll: () {}),
//             //   ),
//             // ),

//             // SliverToBoxAdapter(
//             //   child: SizedBox(
//             //     height: 110,
//             //     child: ListView.separated(
//             //       scrollDirection: Axis.horizontal,
//             //       padding: const EdgeInsets.symmetric(horizontal: 16),
//             //       separatorBuilder: (_, __) => const SizedBox(width: 16),
//             //       itemCount: _creators.length,
//             //       itemBuilder: (_, i) => _CreatorChip(
//             //         name: _creators[i].$1,
//             //         followers: _creators[i].$2,
//             //         isCrown: i == 0,
//             //       ),
//             //     ),
//             //   ),
//             // ),

//             // ── New Uploads ───────────────────────────────────────
//             // SliverToBoxAdapter(
//             //   child: Padding(
//             //     padding: const EdgeInsets.fromLTRB(16, 24, 16, 14),
//             //     child: _SectionHeader('⚡ New Uploads', onSeeAll: () {}),
//             //   ),
//             // ),

//             // SliverToBoxAdapter(
//             //   child: sounds.when(
//             //     loading: () => const SizedBox(),
//             //     error: (_, __) => const SizedBox(),
//             //     data: (list) =>
//             //         _NewUploadsGrid(sounds: list.skip(3).take(4).toList()),
//             //   ),
//             // ),
//             const SliverToBoxAdapter(child: SizedBox(height: 32)),
//           ],
//         ),
//       ),
//     );
//   }

//   void _share(SoundModel sound) {
//     final coins = ref.read(profileProvider).valueOrNull?.coinBalance ?? 0;
//     if (coins < kShareCoinCost) {
//       showModalBottomSheet(
//         context: context,
//         backgroundColor: Colors.transparent,
//         builder: (_) => const InsufficientCoinsSheet(),
//       );
//       return;
//     }
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder: (_) => ShareBottomSheetWidget(
//         sound: sound,
//         coinCost: kShareCoinCost,
//         availableCoins: coins,
//         onShareMp3: () async {
//           Navigator.pop(context);
//         },
//         onShareToApp: (s) async {
//           Navigator.pop(context);
//         },
//         onCopyLink: () {
//           Navigator.pop(context);
//         },
//       ),
//     );
//   }
// }

// // ── Banner card ───────────────────────────────────────────────────
// class _BannerCard extends StatelessWidget {
//   final int index;
//   const _BannerCard({required this.index});

//   static const _data = [
//     ('"Arey Baap Re!"', '1.2M Plays'),
//     ('"Oho Ho Ho!"', '2.1M Plays'),
//     ('"Aayo K Garne?"', '1.8M Plays'),
//   ];

//   @override
//   Widget build(BuildContext context) => Container(
//     margin: const EdgeInsets.only(right: 10),
//     decoration: BoxDecoration(
//       borderRadius: BorderRadius.circular(20),
//       gradient: LinearGradient(
//         colors: [_purple.withOpacity(.9), const Color(0xFF1A0533)],
//         begin: Alignment.centerLeft,
//         end: Alignment.centerRight,
//       ),
//     ),
//     child: Stack(
//       children: [
//         // Right image placeholder
//         Positioned(
//           right: 0,
//           top: 0,
//           bottom: 0,
//           child: ClipRRect(
//             borderRadius: const BorderRadius.horizontal(
//               right: Radius.circular(20),
//             ),
//             child: Container(
//               width: 160,
//               color: Colors.purple.withOpacity(.3),
//               child: const Icon(
//                 Icons.person_rounded,
//                 size: 100,
//                 color: Colors.white12,
//               ),
//             ),
//           ),
//         ),

//         // Content
//         Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 10,
//                   vertical: 4,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.black38,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: const Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text('🔥', style: TextStyle(fontSize: 11)),
//                     SizedBox(width: 4),
//                     Text(
//                       'TRENDING NOW',
//                       style: TextStyle(
//                         color: _white,
//                         fontSize: 10,
//                         fontWeight: FontWeight.w700,
//                         letterSpacing: .6,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 10),
//               Text(
//                 _data[index].$1,
//                 style: const TextStyle(
//                   color: _white,
//                   fontSize: 22,
//                   fontWeight: FontWeight.w800,
//                   height: 1.2,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   const Icon(
//                     Icons.play_circle_filled,
//                     color: _purpleL,
//                     size: 16,
//                   ),
//                   const SizedBox(width: 5),
//                   Text(
//                     _data[index].$2,
//                     style: const TextStyle(color: Colors.white70, fontSize: 12),
//                   ),
//                 ],
//               ),
//               const Spacer(),
//               Row(
//                 children: [
//                   _BannerBtn(
//                     icon: Icons.play_arrow_rounded,
//                     label: 'Play Now',
//                     filled: true,
//                   ),
//                   const SizedBox(width: 10),
//                   _BannerBtn(
//                     icon: Icons.favorite_border_rounded,
//                     label: 'Save',
//                     filled: false,
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ],
//     ),
//   );
// }

// class _BannerBtn extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final bool filled;
//   const _BannerBtn({
//     required this.icon,
//     required this.label,
//     required this.filled,
//   });
//   @override
//   Widget build(BuildContext context) => Container(
//     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//     decoration: BoxDecoration(
//       color: filled ? _purple : Colors.transparent,
//       borderRadius: BorderRadius.circular(22),
//       border: filled ? null : Border.all(color: Colors.white38),
//     ),
//     child: Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, color: _white, size: 14),
//         const SizedBox(width: 5),
//         Text(
//           label,
//           style: const TextStyle(
//             color: _white,
//             fontSize: 12,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//       ],
//     ),
//   );
// }

// // ── Category chip ─────────────────────────────────────────────────
// class _CategoryChip extends StatefulWidget {
//   final String emoji, label;
//   const _CategoryChip({required this.emoji, required this.label});
//   @override
//   State<_CategoryChip> createState() => _CategoryChipState();
// }

// class _CategoryChipState extends State<_CategoryChip> {
//   bool _selected = false;
//   @override
//   Widget build(BuildContext context) => GestureDetector(
//     onTap: () => setState(() => _selected = !_selected),
//     child: AnimatedContainer(
//       duration: const Duration(milliseconds: 200),
//       margin: const EdgeInsets.only(right: 8),
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
//       decoration: BoxDecoration(
//         color: _selected ? _purple : _surface,
//         borderRadius: BorderRadius.circular(22),
//         border: Border.all(color: _selected ? _purple : Colors.white12),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(widget.emoji, style: const TextStyle(fontSize: 14)),
//           const SizedBox(width: 6),
//           Text(
//             widget.label,
//             style: TextStyle(
//               color: _selected ? _white : Colors.white70,
//               fontSize: 13,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }

// // ── Section header ────────────────────────────────────────────────
// class _SectionHeader extends StatelessWidget {
//   final String title;
//   final VoidCallback onSeeAll;
//   const _SectionHeader(this.title, {required this.onSeeAll});
//   @override
//   Widget build(BuildContext context) => Row(
//     children: [
//       Text(
//         title,
//         style: const TextStyle(
//           color: _white,
//           fontSize: 16,
//           fontWeight: FontWeight.w700,
//         ),
//       ),
//       const Spacer(),
//       GestureDetector(
//         onTap: onSeeAll,
//         child: const Row(
//           children: [
//             Text(
//               'See All',
//               style: TextStyle(
//                 color: _purpleL,
//                 fontSize: 13,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             SizedBox(width: 3),
//             Icon(Icons.chevron_right_rounded, color: _purpleL, size: 16),
//           ],
//         ),
//       ),
//     ],
//   );
// }

// // ── Trending sound list ───────────────────────────────────────────
// class _TrendingList extends StatelessWidget {
//   final List<SoundModel> sounds;
//   final void Function(SoundModel) onShare;
//   const _TrendingList({required this.sounds, required this.onShare});

//   @override
//   Widget build(BuildContext context) => Padding(
//     padding: const EdgeInsets.symmetric(horizontal: 16),
//     child: Container(
//       decoration: BoxDecoration(
//         color: _surface,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Column(
//         children: List.generate(sounds.length, (i) {
//           final s = sounds[i];
//           return Column(
//             children: [
//               _TrendingTile(sound: s, onShare: () => onShare(s)),
//               if (i < sounds.length - 1)
//                 const Divider(color: Colors.white70, height: 0, indent: 16),
//             ],
//           );
//         }),
//       ),
//     ),
//   );
// }

// class _TrendingTile extends StatelessWidget {
//   final SoundModel sound;
//   final VoidCallback onShare;
//   const _TrendingTile({required this.sound, required this.onShare});

//   @override
//   Widget build(BuildContext context) => Padding(
//     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//     child: Row(
//       children: [
//         // Thumbnail
//         Stack(
//           children: [
//             Container(
//               width: 56,
//               height: 56,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(10),
//                 color: _card,
//               ),
//               child: const Icon(
//                 Icons.music_note_rounded,
//                 color: Colors.white24,
//                 size: 24,
//               ),
//             ),
//             Positioned.fill(
//               child: Center(
//                 child: Container(
//                   width: 22,
//                   height: 22,
//                   decoration: BoxDecoration(
//                     color: _purple.withOpacity(.85),
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.play_arrow_rounded,
//                     color: _white,
//                     size: 14,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(width: 12),

//         // Info
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 sound.title ?? 'Unknown',
//                 style: const TextStyle(
//                   color: _white,
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                 ),
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               const SizedBox(height: 4),
//               Row(
//                 children: [
//                   const Icon(
//                     Icons.graphic_eq_rounded,
//                     color: _purpleL,
//                     size: 12,
//                   ),
//                   const SizedBox(width: 4),
//                   Text(
//                     '${sound.playCount ?? '0'} plays',
//                     style: const TextStyle(color: Colors.white38, fontSize: 11),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),

//         // Play button
//         GestureDetector(
//           onTap: () {
//             re
//           },
//           child: Container(
//             width: 42,
//             height: 42,
//             decoration: const BoxDecoration(
//               color: _purple,
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.play_arrow_rounded,
//               color: _white,
//               size: 22,
//             ),
//           ),
//         ),
//         const SizedBox(width: 10),

//         // Share button
//         GestureDetector(
//           onTap: onShare,
//           child: Container(
//             width: 42,
//             height: 42,
//             decoration: BoxDecoration(
//               color: _card,
//               shape: BoxShape.circle,
//               border: Border.all(color: Colors.white12),
//             ),
//             child: const Icon(
//               Icons.share_rounded,
//               color: Colors.white54,
//               size: 18,
//             ),
//           ),
//         ),
//       ],
//     ),
//   );
// }

// // ── Creator chip ──────────────────────────────────────────────────
// class _CreatorChip extends StatelessWidget {
//   final String name, followers;
//   final bool isCrown;
//   const _CreatorChip({
//     required this.name,
//     required this.followers,
//     required this.isCrown,
//   });
//   @override
//   Widget build(BuildContext context) => Column(
//     mainAxisSize: MainAxisSize.min,
//     children: [
//       Stack(
//         alignment: Alignment.topRight,
//         children: [
//           Container(
//             width: 64,
//             height: 64,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               border: Border.all(color: _purple, width: 2),
//               color: _surface,
//             ),
//             child: ClipOval(
//               child: Icon(
//                 Icons.person_rounded,
//                 color: Colors.white24,
//                 size: 36,
//               ),
//             ),
//           ),
//           if (isCrown)
//             const Positioned(
//               top: -2,
//               right: -2,
//               child: Text('👑', style: TextStyle(fontSize: 16)),
//             ),
//         ],
//       ),
//       const SizedBox(height: 6),
//       Text(
//         name,
//         style: const TextStyle(
//           color: _white,
//           fontSize: 12,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//       const SizedBox(height: 2),
//       Text(
//         followers,
//         style: const TextStyle(color: Colors.white38, fontSize: 11),
//       ),
//     ],
//   );
// }

// // ── New uploads grid ──────────────────────────────────────────────
// class _NewUploadsGrid extends StatelessWidget {
//   final List<SoundModel> sounds;
//   const _NewUploadsGrid({required this.sounds});

//   @override
//   Widget build(BuildContext context) => Padding(
//     padding: const EdgeInsets.symmetric(horizontal: 16),
//     child: GridView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 4,
//         crossAxisSpacing: 8,
//         mainAxisSpacing: 8,
//         childAspectRatio: 0.72,
//       ),
//       itemCount: sounds.isEmpty ? 4 : sounds.length,
//       itemBuilder: (_, i) {
//         final s = sounds.isEmpty ? null : sounds[i];
//         return _UploadCard(sound: s);
//       },
//     ),
//   );
// }

// class _UploadCard extends StatelessWidget {
//   final SoundModel? sound;
//   const _UploadCard({required this.sound});

//   @override
//   Widget build(BuildContext context) => Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Expanded(
//         child: Stack(
//           children: [
//             Container(
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(10),
//                 color: _surface,
//               ),
//               child: const Icon(
//                 Icons.music_note_rounded,
//                 color: Colors.white12,
//                 size: 28,
//               ),
//             ),
//             // Duration badge
//             Positioned(
//               bottom: 5,
//               right: 5,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: Colors.black54,
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//                 child: Text(
//                   sound?.durationSec.toString() ?? '0:05',
//                   style: const TextStyle(
//                     color: _white,
//                     fontSize: 9,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//             ),
//             // Play overlay
//             Positioned(
//               top: 5,
//               left: 5,
//               child: Container(
//                 width: 18,
//                 height: 18,
//                 decoration: BoxDecoration(
//                   color: _purple.withOpacity(.8),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.play_arrow_rounded,
//                   color: _white,
//                   size: 12,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//       const SizedBox(height: 5),
//       Text(
//         sound?.title ?? 'Sound ${0}',
//         style: const TextStyle(
//           color: _white,
//           fontSize: 10,
//           fontWeight: FontWeight.w600,
//         ),
//         maxLines: 1,
//         overflow: TextOverflow.ellipsis,
//       ),
//       const SizedBox(height: 2),
//       Row(
//         children: [
//           const Icon(Icons.play_arrow_rounded, color: Colors.white38, size: 10),
//           const SizedBox(width: 2),
//           Text(
//             sound?.playCount.toString() ?? '0',
//             style: const TextStyle(color: Colors.white38, fontSize: 9),
//           ),
//         ],
//       ),
//     ],
//   );
// }

// // ── Error widget ──────────────────────────────────────────────────
// class _ErrorWidget extends StatelessWidget {
//   const _ErrorWidget();
//   @override
//   Widget build(BuildContext context) => const SizedBox(
//     height: 120,
//     child: Center(
//       child: Text('Failed to load', style: TextStyle(color: Colors.white38)),
//     ),
//   );
// }
