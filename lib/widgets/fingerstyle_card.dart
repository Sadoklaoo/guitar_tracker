// lib/widgets/fingerstyle_card.dart

import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/fingerstyle_song.dart';
import 'difficulty_badge.dart';
import 'star_rating.dart';

class FingerstyleCard extends StatelessWidget {
  final FingerstyleSong song;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const FingerstyleCard({
    super.key,
    required this.song,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.amberDark.withAlpha((0.15 * 255).round()),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.queue_music_rounded,
                      color: AppTheme.amberLight,
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
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  DifficultyBadge(difficulty: song.difficulty),
                  if (song.technique != null)
                    _InfoPill(
                      icon: Icons.fingerprint_rounded,
                      label: song.technique!,
                      color: AppTheme.amber,
                    ),
                  if (song.tuning != null)
                    _InfoPill(
                      icon: Icons.tune_rounded,
                      label: song.tuning!,
                    ),
                  if (song.bpm != null)
                    _InfoPill(
                      icon: Icons.speed_rounded,
                      label: '${song.bpm} BPM',
                    ),
                ],
              ),
              if (song.rating != null) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                StarRatingDisplay(rating: song.rating!, size: 13),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoPill({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.onSurfaceMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: c.withAlpha((0.08 * 255).round()),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withAlpha((0.2 * 255).round()), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: c,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
