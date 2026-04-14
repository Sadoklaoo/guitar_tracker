// lib/screens/songs/song_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/songs_provider.dart';
import '../../providers/chords_provider.dart';
import '../../widgets/app_states.dart';
import '../../widgets/chord_diagram.dart';
import '../../widgets/difficulty_badge.dart';
import '../../widgets/star_rating.dart';

class SongDetailScreen extends ConsumerWidget {
  final String songId;

  const SongDetailScreen({super.key, required this.songId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songAsync = ref.watch(songDetailProvider(songId));
    final theme = Theme.of(context);

    return songAsync.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: e.toString()),
      ),
      data: (song) {
        final chordCount = song.chordCount ??
            song.chordDetails?.length ??
            song.chordIds?.length;
        final sequenceItems = song.sequence ?? [];
        final sequenceChordNames = sequenceItems
            .map((item) => item.name)
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList();
        final useEmbeddedChords =
            song.chordDetails != null && song.chordDetails!.isNotEmpty;
        final songChordsAsync = !useEmbeddedChords &&
                song.chordIds != null &&
                song.chordIds!.isNotEmpty
            ? ref.watch(songChordsProvider(songId))
            : null;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // ── Hero Header ────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    onPressed: () => context.push('/songs/$songId/edit'),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding:
                      const EdgeInsets.fromLTRB(16, 0, 60, 16),
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: theme.textTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        song.artist,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.amber.withAlpha((0.1 * 255).round()),
                          AppTheme.surface,
                        ],
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Icon(
                          Icons.music_note_rounded,
                          size: 100,
                          color: AppTheme.amber.withAlpha((0.06 * 255).round()),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Info Row ───────────────────────────────────
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        DifficultyBadge(difficulty: song.difficulty),
                        if (song.genre != null)
                          _InfoChip(
                            label: song.genre!,
                            icon: Icons.category_outlined,
                          ),
                        if (chordCount != null)
                          _InfoChip(
                            label: '$chordCount chord${chordCount == 1 ? '' : 's'}',
                            icon: Icons.piano_rounded,
                          ),
                        if (song.rating != null)
                          StarRatingDisplay(rating: song.rating!),
                      ],
                    ),

                    if (sequenceItems.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      _SectionHeader(
                        title: 'Sequence',
                        icon: Icons.list_rounded,
                        count: sequenceItems.length,
                      ),
                      const SizedBox(height: 12),
                      ...sequenceItems.map((item) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.music_note_rounded),
                            title: Text(item.name),
                            trailing: item.repeats > 1
                                ? Text('x${item.repeats}')
                                : null,
                          )),
                      if (sequenceChordNames.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _SectionHeader(
                          title: 'Chord list',
                          icon: Icons.music_note,
                          count: sequenceChordNames.length,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: sequenceChordNames
                              .map((name) => Chip(label: Text(name)))
                              .toList(),
                        ),
                      ],
                    ],

                    // ── Chords Section ─────────────────────────────
                    const SizedBox(height: 28),
                    _SectionHeader(
                      title: 'Chords',
                      icon: Icons.piano_rounded,
                      count: chordCount,
                    ),
                    const SizedBox(height: 12),
                    if (useEmbeddedChords) ...[
                      SizedBox(
                        height: 140,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: song.chordDetails!.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (ctx, i) => ChordDiagramCard(
                            chord: song.chordDetails![i],
                            onTap: () =>
                                ChordDetailSheet.show(ctx, song.chordDetails![i]),
                          ),
                        ),
                      ),
                    ] else if (songChordsAsync != null) ...[
                      songChordsAsync.when(
                        loading: () => const SizedBox(
                          height: 80,
                          child: LoadingView(),
                        ),
                        error: (e, _) => const Text('Failed to load chords'),
                        data: (chords) => chords.isEmpty
                            ? const Text('No chords linked')
                            : SizedBox(
                                height: 140,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: chords.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 10),
                                  itemBuilder: (ctx, i) => ChordDiagramCard(
                                    chord: chords[i],
                                    onTap: () => ChordDetailSheet.show(
                                        ctx, chords[i]),
                                  ),
                                ),
                              ),
                      ),
                    ] else ...[
                      const Text('No chords available'),
                    ],

                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final int? count;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.amber, size: 18),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.amber.withAlpha((0.12 * 255).round()),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.amber,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3E3D41)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.onSurfaceMuted),
          const SizedBox(width: 5),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
