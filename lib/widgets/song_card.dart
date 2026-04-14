// lib/widgets/song_card.dart

import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/song.dart';
import 'difficulty_badge.dart';
import 'star_rating.dart';

class SongCard extends StatelessWidget {
  final Song song;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const SongCard({
    super.key,
    required this.song,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (song.id == null) {
      // ignore: avoid_print
      print('[SongCard] song has no id: title="${song.title}" artist="${song.artist}"');
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                // Debug tap logging for song cards.
                // Check the console to confirm tap handling.
                // ignore: avoid_print
                print('[SongCard] tapped: id=${song.id}, title="${song.title}"');
                onTap?.call();
              },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Guitar icon accent
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.amber.withAlpha((0.12 * 255).round()),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.music_note_rounded,
                      color: AppTheme.amber,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          song.artist,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.more_vert_rounded),
                      iconSize: 20,
                      color: AppTheme.onSurfaceMuted,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        DifficultyBadge(difficulty: song.difficulty),
                        if (song.genre != null) _GenrePill(genre: song.genre!),
                      ],
                    ),
                  ),
                  if (song.rating != null)
                    StarRatingDisplay(rating: song.rating!, size: 13),
                ],
              ),
              if (song.chordIds != null && song.chordIds!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.piano_rounded,
                      size: 14,
                      color: AppTheme.onSurfaceMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${song.chordIds!.length} chord${song.chordIds!.length == 1 ? '' : 's'}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GenrePill extends StatelessWidget {
  final String genre;

  const _GenrePill({required this.genre});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        genre,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}
