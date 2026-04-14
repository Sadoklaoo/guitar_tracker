// lib/screens/fingerstyle/fingerstyle_form_screen.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../models/fingerstyle_song.dart';
import '../../providers/fingerstyle_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/app_states.dart';
import '../../widgets/star_rating.dart';

class FingerstyleFormScreen extends ConsumerStatefulWidget {
  final String? songId;

  const FingerstyleFormScreen({super.key, this.songId});

  @override
  ConsumerState<FingerstyleFormScreen> createState() =>
      _FingerstyleFormScreenState();
}

class _FingerstyleFormScreenState
    extends ConsumerState<FingerstyleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _genreController = TextEditingController();
  final _tuningController = TextEditingController();
  final _timeSignatureController = TextEditingController();
  final _keyController = TextEditingController();
  final _tabUrlController = TextEditingController();
  final _notesController = TextEditingController();

  String _difficulty = 'beginner';
  double _rating = 3;
  String? _technique;
  int _bpm = 80;
  int _capo = 0;
  List<String> _selectedChordIds = [];
  List<FingerstyleSequenceItem> _sequenceItems = [];
  bool _isLoading = false;
  bool _initialized = false;

  bool get _isEditing => widget.songId != null;

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _genreController.dispose();
    _tuningController.dispose();
    _timeSignatureController.dispose();
    _keyController.dispose();
    _tabUrlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initFromSong(FingerstyleSong song) {
    if (_initialized) return;
    _initialized = true;
    _titleController.text = song.title;
    _artistController.text = song.artist;
    _genreController.text = song.genre ?? '';
    _tuningController.text = song.tuning ?? '';
    _timeSignatureController.text = song.timeSignature ?? '';
    _keyController.text = song.key ?? '';
    _tabUrlController.text = song.tabUrl ?? '';
    _notesController.text = song.arrangementNotes ?? '';
    _difficulty = song.difficulty;
    _rating = song.rating ?? 3;
    _technique = song.technique;
    _bpm = song.bpm ?? 80;
    _capo = song.capo ?? 0;
    _selectedChordIds = List.from(song.chordIds ?? []);
    _sequenceItems = List.from(song.sequence ?? []);
  }

  Widget _buildSequenceRow(int index, FingerstyleSequenceItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: DropdownButtonFormField<String>(
              initialValue: item.type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'note', child: Text('Note')),
                DropdownMenuItem(value: 'chord', child: Text('Chord')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _sequenceItems[index] = item.copyWith(type: value);
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: TextFormField(
              initialValue: item.value,
              decoration: const InputDecoration(
                labelText: 'Value',
                hintText: 'E, G, Em, etc.',
              ),
              onChanged: (value) {
                setState(() {
                  _sequenceItems[index] = item.copyWith(value: value);
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: TextFormField(
              initialValue: item.duration.toString(),
              decoration: const InputDecoration(labelText: 'Duration'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                final parsed = double.tryParse(value);
                setState(() {
                  _sequenceItems[index] = item.copyWith(
                    duration: parsed ?? item.duration,
                  );
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
      final parsedSequence = _sequenceItems.isNotEmpty ? _sequenceItems : null;
      final song = FingerstyleSong(
        title: _titleController.text.trim(),
        artist: _artistController.text.trim(),
        genre: _genreController.text.trim().isEmpty
            ? null
            : _genreController.text.trim(),
        difficulty: _difficulty,
        rating: _rating,
        technique: _technique,
        tuning: _tuningController.text.trim().isEmpty
            ? null
            : _tuningController.text.trim(),
        bpm: _bpm,
        timeSignature: _timeSignatureController.text.trim().isEmpty
            ? null
            : _timeSignatureController.text.trim(),
        key: _keyController.text.trim().isEmpty
            ? null
            : _keyController.text.trim(),
        capo: _capo,
        tabUrl: _tabUrlController.text.trim().isEmpty
            ? null
            : _tabUrlController.text.trim(),
        arrangementNotes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        sequence: parsedSequence,
        chordIds: parsedSequence == null && _selectedChordIds.isNotEmpty
            ? _selectedChordIds
            : null,
      );

      if (_isEditing) {
        await ref
            .read(fingerstyleProvider.notifier)
            .updateSong(widget.songId!, song);
        if (mounted) {
          showSnackBar(context, 'Song updated!');
          context.pop();
        }
      } else {
        final created = await ref
            .read(fingerstyleProvider.notifier)
            .createSong(song);
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
            : 'Failed to save. Try again.';
        showSnackBar(context, message ?? 'Failed to save. Try again.', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final techniquesAsync = ref.watch(techniquesProvider);

    if (_isEditing) {
      final songAsync = ref.watch(fingerstyleDetailProvider(widget.songId!));
      songAsync.whenData(_initFromSong);
    }

    const tuningHints = ['Standard', 'Drop D', 'DADGAD', 'Open G', 'Open D'];

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Song' : 'Add Fingerstyle Song'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.amber),
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
            _Section(
              title: 'Song Info',
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    prefixIcon: Icon(Icons.music_note_rounded),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Title is required'
                      : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _artistController,
                  decoration: const InputDecoration(
                    labelText: 'Artist *',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Artist is required'
                      : null,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _genreController,
                  decoration: const InputDecoration(
                    labelText: 'Genre',
                    prefixIcon: Icon(Icons.category_rounded),
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Difficulty ──────────────────────────────────────────
            _Section(
              title: 'Difficulty',
              children: [
                Row(
                  children: ['beginner', 'intermediate', 'advanced']
                      .map((d) => Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
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
            _Section(
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

            // ── Fingerstyle Specifics ────────────────────────────────
            _Section(
              title: 'Fingerstyle Details',
              children: [
                // Technique dropdown
                techniquesAsync.when(
                  loading: () => const LoadingView(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (techniques) => DropdownButtonFormField<String>(
                    initialValue: _technique,
                    decoration: const InputDecoration(
                      labelText: 'Technique',
                      prefixIcon: Icon(Icons.fingerprint_rounded),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('None')),
                      ...techniques.map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t),
                          )),
                    ],
                    onChanged: (v) => setState(() => _technique = v),
                  ),
                ),
                const SizedBox(height: 12),

                // Tuning
                TextFormField(
                  controller: _tuningController,
                  decoration: InputDecoration(
                    labelText: 'Tuning',
                    hintText: 'e.g. Standard, DADGAD',
                    prefixIcon: const Icon(Icons.tune_rounded),
                    suffix: PopupMenuButton<String>(
                      icon: const Icon(Icons.arrow_drop_down_rounded,
                          size: 18),
                      tooltip: 'Suggestions',
                      onSelected: (v) =>
                          _tuningController.text = v,
                      itemBuilder: (_) => tuningHints
                          .map((h) => PopupMenuItem(
                              value: h, child: Text(h)))
                          .toList(),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // BPM
                Row(
                  children: [
                    const Icon(Icons.speed_rounded,
                        color: AppTheme.onSurfaceMuted, size: 18),
                    const SizedBox(width: 8),
                    Text('BPM', style: theme.textTheme.labelMedium),
                    Expanded(
                      child: Slider(
                        value: _bpm.toDouble(),
                        min: 20,
                        max: 300,
                        divisions: 280,
                        activeColor: AppTheme.amber,
                        inactiveColor: AppTheme.amber.withAlpha((0.2 * 255).round()),
                        onChanged: (v) =>
                            setState(() => _bpm = v.round()),
                      ),
                    ),
                    Container(
                      width: 52,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.amber.withAlpha((0.1 * 255).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_bpm',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppTheme.amber,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Time signature & key
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _timeSignatureController,
                        decoration: const InputDecoration(
                          labelText: 'Time Sig.',
                          hintText: '4/4',
                          prefixIcon:
                              Icon(Icons.access_time_rounded),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _keyController,
                        decoration: const InputDecoration(
                          labelText: 'Key',
                          hintText: 'G major',
                          prefixIcon:
                              Icon(Icons.music_note_rounded),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Capo
                Row(
                  children: [
                    const Icon(Icons.linear_scale_rounded,
                        color: AppTheme.onSurfaceMuted, size: 18),
                    const SizedBox(width: 8),
                    Text('Capo', style: theme.textTheme.labelMedium),
                    Expanded(
                      child: Slider(
                        value: _capo.toDouble(),
                        min: 0,
                        max: 12,
                        divisions: 12,
                        activeColor: AppTheme.amber,
                        inactiveColor: AppTheme.amber.withAlpha((0.2 * 255).round()),
                        onChanged: (v) =>
                            setState(() => _capo = v.round()),
                      ),
                    ),
                    SizedBox(
                      width: 52,
                      child: Text(
                        _capo == 0 ? 'None' : 'Fret $_capo',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Tab URL & Notes ──────────────────────────────────────
            _Section(
              title: 'Resources',
              children: [
                TextFormField(
                  controller: _tabUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Tab URL',
                    hintText: 'https://...',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Arrangement Notes',
                    hintText: 'Notes about the arrangement, challenges...',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  maxLines: 4,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Sequence ───────────────────────────────────────────
            _Section(
              title: 'Sequence',
              children: [
                const Text(
                  'Build a mixed note/chord sequence for this fingerstyle song.',
                ),
                const SizedBox(height: 12),
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
                    _sequenceItems.add(
                      FingerstyleSequenceItem(
                        type: 'chord',
                        value: '',
                        duration: 1.0,
                      ),
                    );
                  }),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add sequence item'),
                ),
                if (_selectedChordIds.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Legacy chord IDs will be preserved if no sequence is created.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 32),

            // ── Buttons ──────────────────────────────────────────────
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              child: Text(
                  _isEditing ? 'Update Song' : 'Add Fingerstyle Song'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

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
    final cap = label[0].toUpperCase() + label.substring(1);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withAlpha((0.15 * 255).round())
              : AppTheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? color.withAlpha((0.6 * 255).round())
                : const Color(0xFF3E3D41),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          cap,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? color : AppTheme.onSurfaceMuted,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w400,
              ),
        ),
      ),
    );
  }
}
