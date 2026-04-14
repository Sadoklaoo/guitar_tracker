// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/songs_provider.dart';
import '../../providers/fingerstyle_provider.dart';
import '../../widgets/song_card.dart';
import '../../widgets/stat_tile.dart';
import '../../widgets/app_states.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(songsProvider);
    final fingerstyleAsync = ref.watch(fingerstyleProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        color: AppTheme.amber,
        onRefresh: () async {
          await Future.wait([
            ref.read(songsProvider.notifier).refresh(),
            ref.read(fingerstyleProvider.notifier).refresh(),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 140,
              collapsedHeight: 60,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Guitar Tracker',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ],
                ),
                background: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppTheme.amber.withAlpha((0.08 * 255).round()),
                              AppTheme.surface,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -20,
                      top: -10,
                      child: Icon(
                        Icons.queue_music_rounded,
                        size: 160,
                        color: AppTheme.amber.withAlpha((0.04 * 255).round()),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 48, 20, 0),
                      child: Text(
                        _greeting(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onSurfaceMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Stats Row ────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverToBoxAdapter(
                child: songsAsync.when(
                  loading: () => const SizedBox(
                    height: 100,
                    child: LoadingView(),
                  ),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (songs) {
                    final fsCount =
                        fingerstyleAsync.valueOrNull?.length ?? 0;
                    return Row(
                      children: [
                        Expanded(
                          child: StatTile(
                            label: 'Songs',
                            value: '${songs.length}',
                            icon: Icons.music_note_rounded,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatTile(
                            label: 'Fingerstyle',
                            value: '$fsCount',
                            icon: Icons.queue_music_rounded,
                            color: AppTheme.amberLight,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatTile(
                            label: 'Total',
                            value: '${songs.length + fsCount}',
                            icon: Icons.library_music_rounded,
                            color: AppTheme.amberGlow,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // ── Quick Actions ────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick Access', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.music_note_rounded,
                            label: 'My Songs',
                            onTap: () => context.go('/songs'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.queue_music_rounded,
                            label: 'Fingerstyle',
                            onTap: () => context.go('/fingerstyle'),
                            secondary: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Recently Practiced ───────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Your Songs', style: theme.textTheme.titleSmall),
                    TextButton(
                      onPressed: () => context.go('/songs'),
                      child: const Text('See all'),
                    ),
                  ],
                ),
              ),
            ),

            songsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: SizedBox(height: 200, child: LoadingView()),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.read(songsProvider.notifier).refresh(),
                ),
              ),
              data: (songs) {
                if (songs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: EmptyView(
                      icon: Icons.music_note_rounded,
                      title: 'No songs yet',
                      subtitle: 'Add your first song to get started',
                      action: ElevatedButton(
                        onPressed: () => context.go('/songs'),
                        child: const Text('Add Song'),
                      ),
                    ),
                  );
                }

                final recent = songs.take(5).toList();

                return SliverToBoxAdapter(
                  child: SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: recent.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (ctx, i) {
                        final song = recent[i];
                        return SizedBox(
                          width: 220,
                          child: SongCard(
                            song: song,
                            onTap: song.id != null
                                ? () {
                                    // ignore: avoid_print
                                    print('[HomeScreen] navigating to /songs/${song.id}');
                                    context.go('/songs/${song.id}');
                                  }
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, let\'s play 🎸';
    if (hour < 17) return 'Good afternoon, ready to practice?';
    return 'Good evening, time to strum 🎵';
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool secondary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: secondary
          ? AppTheme.amberDark.withAlpha((0.12 * 255).round())
          : AppTheme.amber.withAlpha((0.12 * 255).round()),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: secondary
                  ? AppTheme.amberLight.withAlpha((0.2 * 255).round())
                  : AppTheme.amber.withAlpha((0.3 * 255).round()),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: secondary ? AppTheme.amberLight : AppTheme.amber,
                size: 26,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: secondary ? AppTheme.amberLight : AppTheme.amber,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
