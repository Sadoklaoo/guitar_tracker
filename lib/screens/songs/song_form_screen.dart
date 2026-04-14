// lib/screens/songs/song_form_screen.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/song.dart';
import '../../providers/songs_provider.dart';
import '../../providers/chords_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_states.dart';
import '../../widgets/star_rating.dart';

class SongFormScreen extends ConsumerStatefulWidget {
  final String? songId;

  const SongFormScreen({super.key, this.songId});

  @override
  ConsumerState<SongFormScreen> createState() => _SongFormScreenState();
}

class _SongFormScreenState extends ConsumerState<SongFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _genreController = TextEditingController();

  String _difficulty = 'Beginner';
  double _rating = 3;
  List<int> _selectedChordIds = [];
  final Set<String> _selectedChordKeys = {};
  final _sequenceTextController = TextEditingController();
  List<SongSequenceItem> _sequenceItems = [];
  bool _isLoading = false;
  bool _initialized = false;

  bool get _isEditing => widget.songId != null;

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _genreController.dispose();
    _sequenceTextController.dispose();
    super.dispose();
  }

  void _initFromSong(Song song) {
    if (_initialized) return;
    _initialized = true;
    _titleController.text = song.title;
    _artistController.text = song.artist;
    _genreController.text = song.genre ?? '';
    _difficulty = song.difficulty;
    _rating = song.rating ?? 3;
    _selectedChordIds = List.from(song.chordIds ?? []);
    _sequenceItems = List.from(song.sequence ?? []);
  }

  void _applySequenceText() {
    final raw = _sequenceTextController.text.trim();
    if (raw.isEmpty) return;
    setState(() {
      _sequenceItems = SongSequenceItem.parseText(raw);
    });
  }

  Widget _buildSequenceRow(int index, SongSequenceItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: TextFormField(
              initialValue: item.name,
              decoration: const InputDecoration(
                labelText: 'Chord name',
                hintText: 'G, D, Em, etc.',
              ),
              onChanged: (value) {
                setState(() {
                  _sequenceItems[index] = item.copyWith(name: value);
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: TextFormField(
              initialValue: item.repeats.toString(),
              decoration: const InputDecoration(
                labelText: 'Repeats',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final parsed = int.tryParse(value) ?? 1;
                setState(() {
                  _sequenceItems[index] = item.copyWith(repeats: parsed);
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              setState(() {
                _sequenceItems.removeAt(index);
              });
            },
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final parsedSequence = _sequenceItems.isNotEmpty
          ? _sequenceItems
          : _sequenceTextController.text.trim().isNotEmpty
              ? SongSequenceItem.parseText(
                  _sequenceTextController.text.trim())
              : null;

      final song = Song(
        title: _titleController.text.trim(),
        artist: _artistController.text.trim(),
        genre: _genreController.text.trim().isEmpty
            ? null
            : _genreController.text.trim(),
        difficulty: _difficulty,
        rating: _rating,
        sequence: parsedSequence?.isNotEmpty == true ? parsedSequence : null,
        chordIds: parsedSequence == null && _selectedChordIds.isNotEmpty
            ? _selectedChordIds
            : null,
      );

      if (_isEditing) {
        await ref.read(songsProvider.notifier).updateSong(widget.songId!, song);
        if (mounted) {
          showSnackBar(context, 'Song updated!');
          context.pop();
        }
      } else {
        final created =
            await ref.read(songsProvider.notifier).createSong(song);
        if (mounted) {
          showSnackBar(context, '"${created?.title}" added!');
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final message = e is DioException
            ? (e.error is ApiException
                ? (e.error as ApiException).message
                : e.message)
            : 'Failed to save song. Try again.';
        showSnackBar(context, message ?? 'Failed to save song. Try again.', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chordsAsync = ref.watch(chordsProvider);

    if (_isEditing) {
      final songAsync = ref.watch(songDetailProvider(widget.songId!));
      songAsync.whenData((song) {
        _initFromSong(song);
        if (!_selectedChordKeys.isNotEmpty && song.chordIds != null) {
          _selectedChordKeys.addAll(song.chordIds!.map((id) => id.toString()));
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Song' : 'Add Song'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.amber,
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Basic Info ──────────────────────────────────────────
            _FormSection(
              title: 'Song Info',
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'e.g. Blackbird',
                    prefixIcon: Icon(Icons.music_note_rounded),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Title is required' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _artistController,
                  decoration: const InputDecoration(
                    labelText: 'Artist *',
                    hintText: 'e.g. The Beatles',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Artist is required' : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _genreController,
                  decoration: const InputDecoration(
                    labelText: 'Genre',
                    hintText: 'e.g. Rock, Folk, Classical',
                    prefixIcon: Icon(Icons.category_rounded),
                  ),
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Difficulty ──────────────────────────────────────────
            _FormSection(
              title: 'Difficulty',
              children: [
                Row(
                  children: ['Beginner', 'Intermediate', 'Advanced']
                      .map((d) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: _DiffButton(
                                label: d,
                                selected: _difficulty == d,
                                onTap: () =>
                                    setState(() => _difficulty = d),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Rating ──────────────────────────────────────────────
            _FormSection(
              title: 'Your Rating',
              children: [
                Center(
                  child: StarRatingSelector(
                    initialRating: _rating,
                    onRatingChanged: (r) => setState(() => _rating = r),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Sequence ───────────────────────────────────────────
            _FormSection(
              title: 'Sequence',
              children: [
                TextFormField(
                  controller: _sequenceTextController,
                  decoration: const InputDecoration(
                    labelText: 'Quick sequence entry',
                    hintText: 'G*4 D*2 Em or G x4, D x2, Em',
                    prefixIcon: Icon(Icons.keyboard_double_arrow_right_rounded),
                  ),
                  maxLines: 2,
                  textInputAction: TextInputAction.newline,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _applySequenceText,
                      child: const Text('Parse sequence'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Use the text entry field to add sequence items, or add items directly below.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_sequenceItems.isNotEmpty) ...[
                  Column(
                    children: _sequenceItems
                        .asMap()
                        .entries
                        .map((entry) => _buildSequenceRow(entry.key, entry.value))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _sequenceItems.add(SongSequenceItem(name: '', repeats: 1));
                    }),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add item'),
                  ),
                ] else ...[
                  const Text(
                    'No sequence items yet. Use quick entry or keep selecting chords below as a fallback.',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _sequenceItems.add(SongSequenceItem(name: '', repeats: 1));
                    }),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add sequence item'),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // ── Chords ──────────────────────────────────────────────
            _FormSection(
              title: 'Chords',
              children: [
                chordsAsync.when(
                  loading: () => const LoadingView(),
                  error: (_, __) => const Text('Could not load chords'),
                  data: (chords) => chords.isEmpty
                      ? Text(
                          'No chords available. Add some on the Chords tab.',
                          style: theme.textTheme.bodySmall,
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: chords.map((chord) {
                            final chordId = chord.id;
                            final key = chordId != null
                                ? chordId.toString()
                                : chord.name;
                            final selected = _selectedChordKeys.contains(key);

                            return FilterChip(
                              label: Text(chord.name),
                              selected: selected,
                              selectedColor:
                                  AppTheme.amber.withAlpha((0.2 * 255).round()),
                              checkmarkColor: AppTheme.amber,
                              onSelected: (v) {
                                setState(() {
                                  if (v) {
                                    _selectedChordKeys.add(key);
                                    if (chordId != null) {
                                      _selectedChordIds.add(chordId);
                                    }
                                  } else {
                                    _selectedChordKeys.remove(key);
                                    if (chordId != null) {
                                      _selectedChordIds.remove(chordId);
                                    }
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Buttons ──────────────────────────────────────────────
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              child: Text(_isEditing ? 'Update Song' : 'Add Song'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _FormSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.amber,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }
}

class _DiffButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DiffButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.difficultyColor(label);
    final capitalize =
        label[0].toUpperCase() + label.substring(1);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha((0.15 * 255).round()) : AppTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color.withAlpha((0.6 * 255).round()) : const Color(0xFF3E3D41),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          capitalize,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? color : AppTheme.onSurfaceMuted,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
        ),
      ),
    );
  }
}
