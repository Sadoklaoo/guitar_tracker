// lib/screens/fingerstyle/fingerstyle_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import '../../models/chord.dart';
import '../../models/fingerstyle_song.dart';
import '../../providers/fingerstyle_provider.dart';
import '../../providers/chords_provider.dart';
import '../../widgets/app_states.dart';
import '../../widgets/chord_diagram.dart';
import '../../widgets/difficulty_badge.dart';
import '../../widgets/star_rating.dart';

class FingerstyleDetailScreen extends ConsumerStatefulWidget {
  final String songId;

  const FingerstyleDetailScreen({super.key, required this.songId});

  @override
  ConsumerState<FingerstyleDetailScreen> createState() =>
      _FingerstyleDetailScreenState();
}

class _FingerstyleDetailScreenState
    extends ConsumerState<FingerstyleDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songAsync = ref.watch(fingerstyleDetailProvider(widget.songId));
    final chordsAsync = ref.watch(fingerstyleChordsProvider(widget.songId));
    final theme = Theme.of(context);

    return songAsync.when(
      loading: () => const Scaffold(body: LoadingView()),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: e.toString()),
      ),
      data: (song) {
        final imageUrl =
            'https://source.unsplash.com/featured/900x600/?${Uri.encodeComponent('${song.title} ${song.artist} guitar')}';

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (ctx, _) => [
              // ── Hero Header ──────────────────────────────────────
              SliverAppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.pop(),
                ),
                expandedHeight: 220,
                pinned: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    onPressed: () =>
                        context.push('/fingerstyle/${widget.songId}/edit'),
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
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: AppTheme.surface,
                          );
                        },
                        errorBuilder: (_, __, ___) => Container(
                          color: AppTheme.surface,
                        ),
                      ),
                      Container(
                        color: AppTheme.surface.withAlpha((0.32 * 255).round()),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppTheme.amberDark.withAlpha((0.18 * 255).round()),
                              AppTheme.surface.withAlpha((0.85 * 255).round()),
                            ],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Icon(
                            Icons.queue_music_rounded,
                            size: 110,
                            color: AppTheme.amber.withAlpha((0.06 * 255).round()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Info Grid ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          DifficultyBadge(difficulty: song.difficulty),
                          if (song.rating != null)
                            StarRatingDisplay(rating: song.rating!),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _InfoGrid(song: song),
                    ],
                  ),
                ),
              ),

              // ── Tab Bar ───────────────────────────────────────────
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.amber,
                    labelColor: AppTheme.amber,
                    unselectedLabelColor: AppTheme.onSurfaceMuted,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Chords'),

                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                // ── Tab 0: Overview ─────────────────────────────────
                _OverviewTab(song: song),

                // ── Tab 1: Chords ────────────────────────────────────
                chordsAsync.when(
                  loading: () => const LoadingView(),
                  error: (e, _) => ErrorView(message: e.toString()),
                  data: (chords) {
                    final sequenceChordCounts = <String, int>{};
                    for (final item in song.sequence ?? <FingerstyleSequenceItem>[]) {
                      if (item.type == 'chord' && item.value.isNotEmpty) {
                        final chordName = item.value.trim();
                        if (chordName.isNotEmpty) {
                          sequenceChordCounts[chordName] =
                              (sequenceChordCounts[chordName] ?? 0) + 1;
                        }
                      }
                    }

                    final chordMap = {
                      for (final chord in chords)
                        chord.name.toLowerCase(): chord,
                    };

                    final sequenceChords = sequenceChordCounts.entries
                        .map((entry) {
                          final chord = chordMap[entry.key.toLowerCase()];
                          return chord == null
                              ? null
                              : _SequenceChordCard(
                                  chord: chord,
                                  count: entry.value,
                                );
                        })
                        .whereType<_SequenceChordCard>()
                        .toList();

                    if (sequenceChords.isEmpty) {
                      return const EmptyView(
                        icon: Icons.piano_rounded,
                        title: 'No chords linked',
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: sequenceChords.length,
                      itemBuilder: (ctx, i) => sequenceChords[i],
                    );
                  },
                ),

              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Info Grid ─────────────────────────────────────────────────────────────────

class _InfoGrid extends StatelessWidget {
  final FingerstyleSong song;

  const _InfoGrid({required this.song});

  @override
  Widget build(BuildContext context) {
    final capo = song.capo;
    final items = <_GridEntry>[
      if (song.technique != null)
        _GridEntry(Icons.fingerprint_rounded, 'Technique', song.technique!),
      if (song.tuning != null)
        _GridEntry(Icons.tune_rounded, 'Tuning', song.tuning!),
      if (song.bpm != null)
        _GridEntry(Icons.speed_rounded, 'BPM', '${song.bpm}'),
      if (song.timeSignature != null)
        _GridEntry(Icons.access_time_rounded, 'Time Sig.', song.timeSignature!),
      if (song.key != null)
        _GridEntry(Icons.music_note_rounded, 'Key', song.key!),
      if (capo != null && capo > 0)
        _GridEntry(Icons.linear_scale_rounded, 'Capo', 'Fret $capo'),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: items
          .map((e) => _InfoCell(icon: e.icon, label: e.label, value: e.value))
          .toList(),
    );
  }
}

class _GridEntry {
  final IconData icon;
  final String label;
  final String value;

  _GridEntry(this.icon, this.label, this.value);
}

class _InfoCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF3E3D41)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: AppTheme.amber),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.onSurfaceMuted,
                      fontSize: 9,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Overview Tab ──────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final FingerstyleSong song;

  const _OverviewTab({required this.song});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sequenceItems = song.sequence ?? <FingerstyleSequenceItem>[];
    final chordCounts = <String, int>{};
    for (final item in sequenceItems.where((item) => item.type == 'chord' && item.value.isNotEmpty)) {
      chordCounts[item.value] = (chordCounts[item.value] ?? 0) + 1;
    }
    final chordChips = chordCounts.entries.toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (sequenceItems.isNotEmpty) ...[
          Text('Sequence', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          ...sequenceItems.map((item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  item.type == 'note' ? Icons.music_note_outlined : Icons.queue_music,
                  color: AppTheme.amber,
                ),
                title: Text(item.value),
                subtitle: Text('Duration: ${item.duration}'),
                trailing: item.type == 'chord'
                    ? Text('Chord', style: theme.textTheme.bodySmall)
                    : null,
              )),
          if (chordChips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Chord list', style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chordChips
                  .map((entry) => Chip(
                        label: Text(entry.value > 1
                            ? '${entry.key} x${entry.value}'
                            : entry.key),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 20),
        ],
        if (song.arrangementNotes != null &&
            song.arrangementNotes!.isNotEmpty) ...[
          Text('Arrangement Notes',
              style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3E3D41)),
            ),
            child: Text(
              song.arrangementNotes!,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (song.tabUrl != null && song.tabUrl!.isNotEmpty) ...[
          Text('Tab Link', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              final uri = Uri.tryParse(song.tabUrl!);
              if (uri != null && await canLaunchUrl(uri)) {
                await launchUrl(uri,
                    mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Open Tab'),
          ),
        ],
        if (song.arrangementNotes == null && song.tabUrl == null)
          const EmptyView(
            icon: Icons.notes_rounded,
            title: 'No overview info',
            subtitle: 'Edit the song to add notes or a tab link',
          ),
      ],
    );
  }
}

class _SequenceChordCard extends StatelessWidget {
  final Chord chord;
  final int count;

  const _SequenceChordCard({required this.chord, required this.count});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ChordDetailSheet.show(context, chord),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3E3D41)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              chord.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.amber,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            ChordDiagram(chord: chord, size: 80, showLabel: false),
            const SizedBox(height: 10),
            if (count > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.amber.withAlpha((0.12 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'x$count',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.amber, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Tab Bar Delegate ──────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppTheme.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}
