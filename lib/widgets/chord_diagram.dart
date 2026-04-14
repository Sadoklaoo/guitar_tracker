// lib/widgets/chord_diagram.dart

import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/chord.dart';

class ChordDiagram extends StatelessWidget {
  final Chord chord;
  final double size;
  final bool showLabel;

  const ChordDiagram({
    super.key,
    required this.chord,
    this.size = 80,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasTextDiagram = chord.frets == null &&
        chord.diagramData != null &&
        chord.diagramData!.trim().isNotEmpty;

    final Widget diagramWidget = hasTextDiagram
        ? Container(
            width: size,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3E3D41), width: 1),
            ),
            child: Text(
              chord.diagramData!,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.2,
              ),
              textAlign: TextAlign.left,
            ),
          )
        : CustomPaint(
            size: Size(size, size * 1.2),
            painter: _ChordPainter(chord: chord),
          );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) ...[
          Text(
            chord.name,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.amber,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
        ],
        diagramWidget,
      ],
    );
  }
}

class ChordDiagramCard extends StatelessWidget {
  final Chord chord;
  final VoidCallback? onTap;

  const ChordDiagramCard({super.key, required this.chord, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3E3D41), width: 1),
        ),
        child: ChordDiagram(chord: chord, size: 68),
      ),
    );
  }
}

class _ChordPainter extends CustomPainter {
  final Chord chord;

  _ChordPainter({required this.chord});

  @override
  void paint(Canvas canvas, Size size) {
    final frets = chord.frets ?? List.filled(6, 0);
    final fingers = chord.fingers ?? List.filled(6, 0);
    final baseFret = chord.baseFret ?? 1;

    const strings = 6;
    const fretCount = 4;

    final stringSpacing = size.width / (strings - 1);
    final fretSpacing = size.height / (fretCount + 1);
    final topPadding = fretSpacing * 0.7;
    final dotRadius = stringSpacing * 0.3;

    final linePaint = Paint()
      ..color = const Color(0xFF5E5D62)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final nutPaint = Paint()
      ..color = AppTheme.amber
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = AppTheme.amber
      ..style = PaintingStyle.fill;

    final openPaint = Paint()
      ..color = AppTheme.amber
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final mutedPaint = Paint()
      ..color = AppTheme.error
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw fret lines
    for (int i = 0; i <= fretCount; i++) {
      final y = topPadding + i * fretSpacing;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        i == 0 && baseFret == 1 ? nutPaint : linePaint,
      );
    }

    // Draw string lines
    for (int i = 0; i < strings; i++) {
      final x = i * stringSpacing;
      canvas.drawLine(
        Offset(x, topPadding),
        Offset(x, topPadding + fretCount * fretSpacing),
        linePaint,
      );
    }

    // Draw base fret indicator
    if (baseFret > 1) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${baseFret}fr',
          style: const TextStyle(
            color: AppTheme.onSurfaceMuted,
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width + 3, topPadding));
    }

    // Draw dots and muted/open indicators
    for (int i = 0; i < frets.length && i < strings; i++) {
      final fret = frets[i];
      final x = i * stringSpacing;

      if (fret == null || fret < 0) {
        // Muted string — X above nut
        final y = topPadding - fretSpacing * 0.4;
        canvas.drawLine(
          Offset(x - dotRadius, y - dotRadius),
          Offset(x + dotRadius, y + dotRadius),
          mutedPaint,
        );
        canvas.drawLine(
          Offset(x + dotRadius, y - dotRadius),
          Offset(x - dotRadius, y + dotRadius),
          mutedPaint,
        );
      } else if (fret == 0) {
        // Open string — O above nut
        final y = topPadding - fretSpacing * 0.4;
        canvas.drawCircle(Offset(x, y), dotRadius * 0.8, openPaint);
      } else {
        // Fretted dot
        final adjustedFret = fret - (baseFret - 1);
        if (adjustedFret > 0 && adjustedFret <= fretCount) {
          final y = topPadding + (adjustedFret - 0.5) * fretSpacing;
          canvas.drawCircle(Offset(x, y), dotRadius, dotPaint);

          // Finger number
          if (fingers.isNotEmpty && i < fingers.length && fingers[i] != null && fingers[i]! > 0) {
            final textPainter = TextPainter(
              text: TextSpan(
                text: '${fingers[i]}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              textDirection: TextDirection.ltr,
            );
            textPainter.layout();
            textPainter.paint(
              canvas,
              Offset(x - textPainter.width / 2, y - textPainter.height / 2),
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChordPainter oldDelegate) =>
      oldDelegate.chord != chord;
}

// Full screen chord detail bottom sheet
class ChordDetailSheet extends StatelessWidget {
  final Chord chord;

  const ChordDetailSheet({super.key, required this.chord});

  static void show(BuildContext context, Chord chord) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => ChordDetailSheet(chord: chord),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.onSurfaceMuted.withAlpha((0.3 * 255).round()),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            chord.name,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppTheme.amber,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ChordDiagram(
              chord: chord,
              size: 150,
              showLabel: false,
            ),
          ),
          if (chord.diagramData != null && chord.diagramData!.trim().isNotEmpty && chord.frets == null) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Diagram', style: theme.textTheme.labelMedium),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3E3D41), width: 1),
              ),
              child: Text(
                chord.diagramData!,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ),
          ],
          if (chord.notes != null && chord.notes!.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Notes', style: theme.textTheme.labelMedium),
            ),
            const SizedBox(height: 8),
            Text(chord.notes!, style: theme.textTheme.bodyMedium),
          ],
          if (chord.baseFret != null && chord.baseFret! > 1) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.keyboard_tab, color: AppTheme.onSurfaceMuted, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Starting at fret ${chord.baseFret}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
