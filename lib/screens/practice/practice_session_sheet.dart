// lib/screens/practice/practice_session_sheet.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/practice_session.dart';
import '../../providers/practice_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_states.dart';

enum PracticeType { song, fingerstyle }

class PracticeSessionSheet extends ConsumerStatefulWidget {
  final String entityId;
  final String songTitle;
  final PracticeType practiceType;

  const PracticeSessionSheet({
    super.key,
    required this.entityId,
    required this.songTitle,
    required this.practiceType,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String entityId,
    required String songTitle,
    required PracticeType practiceType,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => PracticeSessionSheet(
        entityId: entityId,
        songTitle: songTitle,
        practiceType: practiceType,
      ),
    );
  }

  @override
  ConsumerState<PracticeSessionSheet> createState() =>
      _PracticeSessionSheetState();
}

class _PracticeSessionSheetState extends ConsumerState<PracticeSessionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  int _duration = 15;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final session = PracticeSession(
        durationMinutes: _duration,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (widget.practiceType == PracticeType.song) {
        await ref
            .read(songPracticeProvider(widget.entityId).notifier)
            .addSession(session);
      } else {
        await ref
            .read(fingerstylePracticeProvider(widget.entityId).notifier)
            .addSession(session);
      }

      if (mounted) {
        Navigator.pop(context, true);
        showSnackBar(context, 'Practice session logged!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        final message = e is DioException
            ? (e.error is ApiException
                ? (e.error as ApiException).message
                : e.message)
            : 'Failed to save session. Try again.';
        showSnackBar(context, message ?? 'Failed to save session. Try again.', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 32 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.onSurfaceMuted.withAlpha((0.3 * 255).round()),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.amber.withAlpha((0.12 * 255).round()),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.timer_rounded, color: AppTheme.amber, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Log Practice', style: theme.textTheme.titleLarge),
                      Text(
                        widget.songTitle,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppTheme.onSurfaceMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Duration
            Text('Duration (minutes)', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _duration.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    activeColor: AppTheme.amber,
                    inactiveColor: AppTheme.amber.withAlpha((0.2 * 255).round()),
                    onChanged: (v) => setState(() => _duration = v.round()),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 56,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.amber.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.amber.withAlpha((0.3 * 255).round())),
                  ),
                  child: Text(
                    '$_duration',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.amber,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notes
            Text('Notes (optional)', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'What did you work on? Any breakthroughs?',
              ),
            ),
            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text('Save Practice Session'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
