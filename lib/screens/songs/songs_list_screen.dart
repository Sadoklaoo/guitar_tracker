// lib/screens/songs/songs_list_screen.dart

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/song.dart';
import '../../providers/songs_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/song_card.dart';
import '../../widgets/app_states.dart';

final _songSearchProvider = StateProvider<String>((ref) => '');
final _songDifficultyFilterProvider = StateProvider<String?>((ref) => null);
final _songSortProvider = StateProvider<String>((ref) => 'date');

class SongsListScreen extends ConsumerWidget {
  const SongsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(songsProvider);
    final search = ref.watch(_songSearchProvider);
    final diffFilter = ref.watch(_songDifficultyFilterProvider);
    final sort = ref.watch(_songSortProvider);
   

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Songs'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort by',
            onSelected: (v) =>
                ref.read(_songSortProvider.notifier).state = v,
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'date', child: Text('Date Added')),
              const PopupMenuItem(value: 'rating', child: Text('Rating')),
              const PopupMenuItem(
                  value: 'difficulty', child: Text('Difficulty')),
              const PopupMenuItem(value: 'title', child: Text('Title')),
            ],
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
                  ref.read(_songSearchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Search songs or artists...',
                prefixIcon:
                    const Icon(Icons.search_rounded, color: AppTheme.onSurfaceMuted),
                suffixIcon: search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () =>
                            ref.read(_songSearchProvider.notifier).state = '',
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // ── Difficulty filter chips ──────────────────────────────────
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _DiffChip(
                  label: 'All',
                  selected: diffFilter == null,
                  onTap: () => ref
                      .read(_songDifficultyFilterProvider.notifier)
                      .state = null,
                ),
                const SizedBox(width: 8),
                _DiffChip(
                  label: 'Beginner',
                  color: AppTheme.beginner,
                  selected: diffFilter == 'beginner',
                  onTap: () => ref
                      .read(_songDifficultyFilterProvider.notifier)
                      .state = 'beginner',
                ),
                const SizedBox(width: 8),
                _DiffChip(
                  label: 'Intermediate',
                  color: AppTheme.intermediate,
                  selected: diffFilter == 'intermediate',
                  onTap: () => ref
                      .read(_songDifficultyFilterProvider.notifier)
                      .state = 'intermediate',
                ),
                const SizedBox(width: 8),
                _DiffChip(
                  label: 'Advanced',
                  color: AppTheme.advanced,
                  selected: diffFilter == 'advanced',
                  onTap: () => ref
                      .read(_songDifficultyFilterProvider.notifier)
                      .state = 'advanced',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Songs List ───────────────────────────────────────────────
          Expanded(
            child: songsAsync.when(
              loading: () => const LoadingView(message: 'Loading songs...'),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.read(songsProvider.notifier).refresh(),
              ),
              data: (songs) {
                final filtered = _filter(songs, search, diffFilter, sort);

                if (songs.isEmpty) {
                  return const EmptyView(
                    icon: Icons.music_note_rounded,
                    title: 'No songs yet',
                    subtitle: 'Tap + to add your first song',
                  );
                }

                if (filtered.isEmpty) {
                  return const EmptyView(
                    icon: Icons.search_off_rounded,
                    title: 'No results found',
                    subtitle: 'Try a different search or filter',
                  );
                }

                return RefreshIndicator(
                  color: AppTheme.amber,
                  onRefresh: () =>
                      ref.read(songsProvider.notifier).refresh(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final song = filtered[i];
                      return SongCard(
                        song: song,
                        onTap: song.id != null
                            ? () {
                                // ignore: avoid_print
                                print('[SongsListScreen] navigating to /songs/${song.id}');
                                context.go('/songs/${song.id}');
                              }
                            : null,
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
        onPressed: () => context.push('/songs/new'),
        tooltip: 'Add Song',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  List<Song> _filter(
      List<Song> songs, String search, String? diff, String sort) {
    var result = songs.where((s) {
      final matchSearch = search.isEmpty ||
          s.title.toLowerCase().contains(search.toLowerCase()) ||
          s.artist.toLowerCase().contains(search.toLowerCase());
      final matchDiff =
          diff == null || s.difficulty.toLowerCase() == diff;
      return matchSearch && matchDiff;
    }).toList();

    switch (sort) {
      case 'rating':
        result.sort((a, b) =>
            (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case 'difficulty':
        const order = ['beginner', 'intermediate', 'advanced'];
        result.sort((a, b) => order
            .indexOf(a.difficulty.toLowerCase())
            .compareTo(order.indexOf(b.difficulty.toLowerCase())));
        break;
      case 'title':
        result.sort((a, b) => a.title.compareTo(b.title));
        break;
      default: // date
        result.sort((a, b) =>
            (b.createdAt ?? DateTime(0))
                .compareTo(a.createdAt ?? DateTime(0)));
    }
    return result;
  }

  void _showOptions(BuildContext context, WidgetRef ref, Song song) {
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
                if (song.id != null) {
                  context.push('/songs/${song.id}/edit');
                } else {
                  showSnackBar(context, 'Unable to edit this song because its ID is missing.', isError: true);
                }
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
                  content:
                      'Are you sure you want to delete "${song.title}"? This cannot be undone.',
                );
                if (confirmed == true && context.mounted) {
                  try {
                    if (song.id != null) {
                      await ref
                          .read(songsProvider.notifier)
                          .deleteSong(song.id!);
                      if (context.mounted) {
                        showSnackBar(context, '"${song.title}" deleted');
                      }
                    } else {
                      if (context.mounted) {
                        showSnackBar(context,
                            'Unable to delete this song because its ID is missing.',
                            isError: true);
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      final message = e is DioException
                          ? (e.error is ApiException
                              ? (e.error as ApiException).message
                              : e.message ?? 'Failed to delete song')
                          : 'Failed to delete song';
                      showSnackBar(context, message, isError: true);
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

class _DiffChip extends StatelessWidget {
  final String label;
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  const _DiffChip({
    required this.label,
    this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.amber;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: AppTheme.surfaceContainerHigh,
      selectedColor: c.withAlpha((0.15 * 255).round()),
      checkmarkColor: c,
      labelStyle: TextStyle(
        color: selected ? c : AppTheme.onSurfaceMuted,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        fontSize: 13,
      ),
      side: BorderSide(
        color: selected ? c.withAlpha((0.05 * 255).round()): const Color(0xFF3E3D41),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
