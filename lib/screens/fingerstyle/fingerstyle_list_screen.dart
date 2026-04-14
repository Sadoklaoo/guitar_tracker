// lib/screens/fingerstyle/fingerstyle_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/fingerstyle_song.dart';
import '../../providers/fingerstyle_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/fingerstyle_card.dart';
import '../../widgets/app_states.dart';

final _fsSearchProvider = StateProvider<String>((ref) => '');

class FingerstyleListScreen extends ConsumerStatefulWidget {
  const FingerstyleListScreen({super.key});

  @override
  ConsumerState<FingerstyleListScreen> createState() =>
      _FingerstyleListScreenState();
}

class _FingerstyleListScreenState
    extends ConsumerState<FingerstyleListScreen> {
  bool _filtersExpanded = false;

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(fingerstyleProvider);
    final search = ref.watch(_fsSearchProvider);
    final filters = ref.watch(fingerstyleFiltersProvider);
    final techniquesAsync = ref.watch(techniquesProvider);
  

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fingerstyle Songs'),
        actions: [
          IconButton(
            icon: Icon(
              _filtersExpanded
                  ? Icons.filter_list_off_rounded
                  : Icons.filter_list_rounded,
              color: filters.hasFilters ? AppTheme.amber : null,
            ),
            onPressed: () =>
                setState(() => _filtersExpanded = !_filtersExpanded),
            tooltip: 'Filters',
          ),
          if (filters.hasFilters)
            TextButton(
              onPressed: () {
                ref.read(fingerstyleFiltersProvider.notifier).state =
                    const FingerstyleFilters();
              },
              child: const Text('Clear'),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              onChanged: (v) =>
                  ref.read(_fsSearchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Search fingerstyle songs...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppTheme.onSurfaceMuted),
                suffixIcon: search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () =>
                            ref.read(_fsSearchProvider.notifier).state = '',
                      )
                    : null,
              ),
            ),
          ),

          // ── Expandable Filters ──────────────────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _FilterPanel(
              filters: filters,
              techniquesAsync: techniquesAsync,
              onChanged: (f) =>
                  ref.read(fingerstyleFiltersProvider.notifier).state = f,
            ),
            crossFadeState: _filtersExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),

          // ── Songs List ───────────────────────────────────────────────
          Expanded(
            child: songsAsync.when(
              loading: () => const LoadingView(message: 'Loading songs...'),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () =>
                    ref.read(fingerstyleProvider.notifier).refresh(),
              ),
              data: (songs) {
                final filtered = _filter(songs, search);

                if (songs.isEmpty) {
                  return const EmptyView(
                    icon: Icons.queue_music_rounded,
                    title: 'No fingerstyle songs yet',
                    subtitle: 'Tap + to add your first arrangement',
                  );
                }

                if (filtered.isEmpty) {
                  return const EmptyView(
                    icon: Icons.search_off_rounded,
                    title: 'No results',
                    subtitle: 'Try adjusting search or filters',
                  );
                }

                return RefreshIndicator(
                  color: AppTheme.amber,
                  onRefresh: () =>
                      ref.read(fingerstyleProvider.notifier).refresh(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final song = filtered[i];
                      return FingerstyleCard(
                        song: song,
                        onTap: () => context.push('/fingerstyle/${song.id}'),
                        onDelete: () => _showOptions(context, ref, song),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/fingerstyle/new'),
        tooltip: 'Add Fingerstyle Song',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  List<FingerstyleSong> _filter(List<FingerstyleSong> songs, String search) {
    if (search.isEmpty) return songs;
    return songs.where((s) {
      return s.title.toLowerCase().contains(search.toLowerCase()) ||
          s.artist.toLowerCase().contains(search.toLowerCase());
    }).toList();
  }

  void _showOptions(
      BuildContext context, WidgetRef ref, FingerstyleSong song) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/fingerstyle/${song.id}/edit');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: AppTheme.error),
              title: const Text('Delete',
                  style: TextStyle(color: AppTheme.error)),
              onTap: () async {
                Navigator.pop(ctx);
                final confirmed = await ConfirmDialog.show(
                  context,
                  title: 'Delete Song',
                  content: 'Delete "${song.title}"? This cannot be undone.',
                );
                if (confirmed == true && context.mounted) {
                  try {
                    await ref
                        .read(fingerstyleProvider.notifier)
                        .deleteSong(song.id!);
                    if (context.mounted) {
                      showSnackBar(context, '"${song.title}" deleted');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      final message = e is DioException
                          ? (e.error is ApiException
                              ? (e.error as ApiException).message
                              : e.message)
                          : 'Failed to delete';
                      showSnackBar(context, message ?? 'Failed to delete',
                          isError: true);
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final FingerstyleFilters filters;
  final AsyncValue<List<String>> techniquesAsync;
  final ValueChanged<FingerstyleFilters> onChanged;

  const _FilterPanel({
    required this.filters,
    required this.techniquesAsync,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3E3D41)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Technique filter
          Text('Technique',
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          techniquesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (techniques) => Wrap(
              spacing: 6,
              runSpacing: 6,
              children: techniques.map((t) {
                final selected = filters.technique == t;
                return FilterChip(
                  label: Text(t),
                  selected: selected,
                  onSelected: (_) => onChanged(
                    selected
                        ? filters.copyWith(clearTechnique: true)
                        : filters.copyWith(technique: t),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Difficulty filter
          Text('Difficulty',
              style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: ['beginner', 'intermediate', 'advanced'].map((d) {
              final selected = filters.difficulty == d;
              return FilterChip(
                label: Text(d[0].toUpperCase() + d.substring(1)),
                selected: selected,
                onSelected: (_) => onChanged(
                  selected
                      ? filters.copyWith(clearDifficulty: true)
                      : filters.copyWith(difficulty: d),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Min rating
          Row(
            children: [
              Text('Min Rating: ',
                  style: Theme.of(context).textTheme.labelMedium),
              Expanded(
                child: Slider(
                  value: filters.minRating ?? 0,
                  min: 0,
                  max: 5,
                  divisions: 5,
                  activeColor: AppTheme.amber,
                  inactiveColor: AppTheme.amber.withAlpha((0.2 * 255).round()),
                  label: filters.minRating?.toStringAsFixed(0) ?? 'Any',
                  onChanged: (v) => onChanged(
                    v == 0
                        ? filters.copyWith(clearMinRating: true)
                        : filters.copyWith(minRating: v),
                  ),
                ),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  filters.minRating != null
                      ? '${filters.minRating!.round()}★'
                      : 'Any',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.amber,
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
