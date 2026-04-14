// lib/providers/chords_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chord.dart';
import '../services/api_service.dart';
import 'api_service_provider.dart';

final chordsProvider =
    AsyncNotifierProvider<ChordsNotifier, List<Chord>>(ChordsNotifier.new);

class ChordsNotifier extends AsyncNotifier<List<Chord>> {
  late ApiService _api;

  @override
  Future<List<Chord>> build() async {
    _api = ref.read(apiServiceProvider);
    return _api.getChords();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _api.getChords());
  }
}

// Chords for a specific song (fetched via song endpoint)
final songChordsProvider =
    FutureProvider.family<List<Chord>, String>((ref, songId) async {
  final api = ref.read(apiServiceProvider);
  return api.getSongChords(songId);
});

// Chords for a fingerstyle song
final fingerstyleChordsProvider =
    FutureProvider.family<List<Chord>, String>((ref, id) async {
  final api = ref.read(apiServiceProvider);
  return api.getFingerstyleChords(id);
});
