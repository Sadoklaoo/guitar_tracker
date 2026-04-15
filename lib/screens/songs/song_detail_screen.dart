// lib/screens/songs/song_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/chord.dart';
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
        final capo = song.capo;
        final strummingPattern = song.strummingPattern?.trim();
        final chordCount = song.chordDetails?.length ??
            song.chordIds?.length ??
            song.chordNames?.length ??
            song.chordCount ??
            sequenceChordNames.length;

        List<Chord> _matchSequenceChords(List<String> names, List<Chord> chords) {
          final seen = <String>{};
          final result = <Chord>[];

          for (final rawName in names) {
            final normalized = rawName.trim().toLowerCase();
            if (normalized.isEmpty || seen.contains(normalized)) continue;

            Chord? match;
            for (final chord in chords) {
              if (chord.name.trim().toLowerCase() == normalized) {
                match = chord;
                break;
              }
            }

            if (match != null) {
              result.add(match);
              seen.add(normalized);
            }
          }

          return result;
        }

        Widget _buildSequenceChordList(List<Chord> chords) {
          if (chords.isEmpty) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sequenceChordNames.map((name) => Chip(label: Text(name))).toList(),
            );
          }

          return SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: chords.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) => ChordDiagramCard(
                chord: chords[i],
                onTap: () => ChordDetailSheet.show(ctx, chords[i]),
              ),
            ),
          );
        }

        Widget _buildChordGrid(List<Chord> chords) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: chords
                    .map(
                      (chord) => SizedBox(
                        width: itemWidth.clamp(140.0, constraints.maxWidth),
                        child: ChordDiagramCard(
                          chord: chord,
                          onTap: () => ChordDetailSheet.show(context, chord),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // ── Hero Header ────────────────────────────────────────
              SliverAppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      context.pop();
                    } else {
                      context.go('/songs');
                    }
                  },
                ),
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
                      const EdgeInsets.fromLTRB(16, 0, 60, 12),
                  title: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: theme.textTheme.titleLarge?.copyWith(height: 1),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        song.artist,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurfaceMuted,
                          height: 1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                      alignment: WrapAlignment.start,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        DifficultyBadge(difficulty: song.difficulty),
                        if (song.genre != null)
                          _InfoChip(
                            label: song.genre!,
                            icon: Icons.category_outlined,
                          ),
                        if (sequenceChordNames.isNotEmpty)
                          _InfoChip(
                            label: '${sequenceChordNames.length} chord${sequenceChordNames.length == 1 ? '' : 's'}',
                            icon: Icons.piano_rounded,
                          ),
                        if (song.rating != null)
                          StarRatingDisplay(rating: song.rating!),
                      ],
                    ),

                    if (song.capo != null ||
                        (song.strummingPattern?.trim().isNotEmpty ?? false)) ...[
                      const SizedBox(height: 28),
                      if (song.capo != null)
                        _SectionHeader(
                          title: 'Capo',
                          icon: Icons.filter_tilt_shift,
                          badgeText: '${song.capo}',
                        ),
                      if (song.strummingPattern?.trim().isNotEmpty ?? false) ...[
                        if (song.capo != null) const SizedBox(height: 12),
                        _SectionHeader(
                          title: 'Strumming',
                          icon: Icons.music_note_rounded,
                          badgeText: song.strummingPattern!.trim().replaceAll(RegExp(r"\s+"), ' '),
                        ),
                      ],
                    ],

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
                    ],

                    if (sequenceChordNames.isNotEmpty ||
                        (song.chordDetails != null && song.chordDetails!.isNotEmpty) ||
                        (song.chordNames != null && song.chordNames!.isNotEmpty)) ...[
                      const SizedBox(height: 28),
                      _SectionHeader(
                        title: 'Chord list',
                        icon: Icons.piano_rounded,
                        count: chordCount != null && chordCount > 0 ? chordCount : null,
                      ),
                      const SizedBox(height: 12),
                      if (useEmbeddedChords) ...[
                        _buildChordGrid(song.chordDetails!),
                      ] else if (songChordsAsync != null) ...[
                        songChordsAsync.when(
                          loading: () => const SizedBox(
                            height: 80,
                            child: LoadingView(),
                          ),
                          error: (e, _) => const Text('Failed to load chord list'),
                          data: (availableChords) {
                            if (availableChords.isEmpty) {
                              return const Text('No chords available');
                            }
                            return _buildChordGrid(availableChords);
                          },
                        ),
                      ] else if (song.chordNames != null && song.chordNames!.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: song.chordNames!
                              .map((name) => Chip(label: Text(name)))
                              .toList(),
                        ),
                      ],
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
  final String? badgeText;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.count,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    final badge = badgeText ?? (count != null ? '$count' : null);

    return Row(
      children: [
        Icon(icon, color: AppTheme.amber, size: 18),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.amber.withAlpha((0.12 * 255).round()),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                badge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.amber,
                      fontWeight: FontWeight.w600,
                    ),
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
