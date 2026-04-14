// lib/providers/songs_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/song.dart';
import '../services/api_service.dart';
import 'api_service_provider.dart';

// ─── Songs List Provider ──────────────────────────────────────────────────────

final songsProvider =
    AsyncNotifierProvider<SongsNotifier, List<Song>>(SongsNotifier.new);

class SongsNotifier extends AsyncNotifier<List<Song>> {
  late ApiService _api;

  @override
  Future<List<Song>> build() async {
    _api = ref.read(apiServiceProvider);
    return _api.getSongs();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _api.getSongs());
  }

  Future<Song?> createSong(Song song) async {
    try {
      final created = await _api.createSong(song);
      state = AsyncValue.data([...state.value ?? [], created]);
      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<Song?> updateSong(String id, Song song) async {
    try {
      final updated = await _api.updateSong(id, song);
      state = AsyncValue.data(
        (state.value ?? []).map((s) => s.id == id ? updated : s).toList(),
      );
      return updated;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteSong(String id) async {
    await _api.deleteSong(id);
    state = AsyncValue.data(
      (state.value ?? []).where((s) => s.id != id).toList(),
    );
  }
}

// ─── Single Song Provider ─────────────────────────────────────────────────────

final songDetailProvider =
    FutureProvider.family<Song, String>((ref, id) async {
  final api = ref.read(apiServiceProvider);
  return api.getSong(id);
});
