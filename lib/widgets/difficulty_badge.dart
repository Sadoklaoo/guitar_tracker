// lib/widgets/difficulty_badge.dart

import 'package:flutter/material.dart';
import '../config/theme.dart';

class DifficultyBadge extends StatelessWidget {
  final String difficulty;
  final bool compact;

  const DifficultyBadge({
    super.key,
    required this.difficulty,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.difficultyColor(difficulty);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha((0.12 * 255).round()),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color..withAlpha((0.3 * 255).round()), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppTheme.difficultyIcon(difficulty),
            color: color,
            size: compact ? 10 : 12,
          ),
          const SizedBox(width: 4),
          Text(
            _capitalize(difficulty),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 10 : 11,
                ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}
