// lib/screens/chords/chords_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/chord.dart';
import '../../providers/chords_provider.dart';
import '../../widgets/chord_diagram.dart';
import '../../widgets/app_states.dart';

class ChordsScreen extends ConsumerWidget {
  const ChordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chordsAsync = ref.watch(chordsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chords Library')),
      body: chordsAsync.when(
        loading: () => const LoadingView(message: 'Loading chords...'),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(chordsProvider.notifier).refresh(),
        ),
        data: (chords) {
          if (chords.isEmpty) {
            return const EmptyView(
              icon: Icons.piano_rounded,
              title: 'No chords available',
              subtitle: 'Chord library is managed by the app and cannot be edited.',
            );
          }

          return RefreshIndicator(
            color: AppTheme.amber,
            onRefresh: () => ref.read(chordsProvider.notifier).refresh(),
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: chords.length,
              itemBuilder: (ctx, i) => _ChordGridItem(chord: chords[i]),
            ),
          );
        },
      ),
    );
  }
}

class _ChordGridItem extends StatelessWidget {
  final Chord chord;

  const _ChordGridItem({required this.chord});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ChordDetailSheet.show(context, chord),
      onLongPress: null,
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
            const SizedBox(height: 12),
            ChordDiagram(chord: chord, size: 80, showLabel: false),
            const SizedBox(height: 8),
            Text(
              'Tap to expand',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.onSurfaceMuted.withAlpha((0.5 * 255).round()),
                    fontSize: 10,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

