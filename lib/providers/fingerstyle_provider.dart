// lib/providers/fingerstyle_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fingerstyle_song.dart';
import '../services/api_service.dart';
import 'api_service_provider.dart';

// ─── Filter State ─────────────────────────────────────────────────────────────

class FingerstyleFilters {
  final String? technique;
  final String? difficulty;
  final String? tuning;
  final double? minRating;

  const FingerstyleFilters({
    this.technique,
    this.difficulty,
    this.tuning,
    this.minRating,
  });

  FingerstyleFilters copyWith({
    String? technique,
    String? difficulty,
    String? tuning,
    double? minRating,
    bool clearTechnique = false,
    bool clearDifficulty = false,
    bool clearTuning = false,
    bool clearMinRating = false,
  }) {
    return FingerstyleFilters(
      technique: clearTechnique ? null : (technique ?? this.technique),
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      tuning: clearTuning ? null : (tuning ?? this.tuning),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
    );
  }

  bool get hasFilters =>
      technique != null || difficulty != null || tuning != null || minRating != null;
}

final fingerstyleFiltersProvider =
    StateProvider<FingerstyleFilters>((ref) => const FingerstyleFilters());

// ─── Fingerstyle Songs Provider ───────────────────────────────────────────────

final fingerstyleProvider =
    AsyncNotifierProvider<FingerstyleNotifier, List<FingerstyleSong>>(
  FingerstyleNotifier.new,
);

class FingerstyleNotifier extends AsyncNotifier<List<FingerstyleSong>> {
  late ApiService _api;

  @override
  Future<List<FingerstyleSong>> build() async {
    _api = ref.read(apiServiceProvider);
    final filters = ref.watch(fingerstyleFiltersProvider);
    return _api.getFingerstyleSongs(
      technique: filters.technique,
      difficulty: filters.difficulty,
      tuning: filters.tuning,
      minRating: filters.minRating,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final filters = ref.read(fingerstyleFiltersProvider);
    state = await AsyncValue.guard(() => _api.getFingerstyleSongs(
          technique: filters.technique,
          difficulty: filters.difficulty,
          tuning: filters.tuning,
          minRating: filters.minRating,
        ));
  }

  Future<FingerstyleSong?> createSong(FingerstyleSong song) async {
    final created = await _api.createFingerstyleSong(song);
    state = AsyncValue.data([...state.value ?? [], created]);
    ref.invalidate(fingerstyleProvider);
    return created;
  }

  Future<FingerstyleSong?> updateSong(String id, FingerstyleSong song) async {
    final updated = await _api.updateFingerstyleSong(id, song);
    state = AsyncValue.data(
      (state.value ?? []).map((s) => s.id == id ? updated : s).toList(),
    );
    ref.invalidate(fingerstyleProvider);
    ref.invalidate(fingerstyleDetailProvider(id));
    return updated;
  }

  Future<void> deleteSong(String id) async {
    await _api.deleteFingerstyleSong(id);
    state = AsyncValue.data(
      (state.value ?? []).where((s) => s.id != id).toList(),
    );
  }
}

// ─── Single Fingerstyle Song ──────────────────────────────────────────────────

final fingerstyleDetailProvider =
    FutureProvider.family<FingerstyleSong, String>((ref, id) async {
  final api = ref.read(apiServiceProvider);
  return api.getFingerstyleSong(id);
});

// ─── Techniques Meta ──────────────────────────────────────────────────────────

final techniquesProvider = FutureProvider<List<String>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getTechniques();
});
