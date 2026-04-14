// lib/providers/practice_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/practice_session.dart';
import '../services/api_service.dart';
import 'api_service_provider.dart';

// ─── Song Practice ────────────────────────────────────────────────────────────

final songPracticeProvider =
    AsyncNotifierProvider.family<SongPracticeNotifier, List<PracticeSession>, String>(
  SongPracticeNotifier.new,
);

class SongPracticeNotifier
    extends FamilyAsyncNotifier<List<PracticeSession>, String> {
  late ApiService _api;

  @override
  Future<List<PracticeSession>> build(String arg) async {
    _api = ref.read(apiServiceProvider);
    return _api.getSongPractice(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _api.getSongPractice(arg));
  }

  Future<PracticeSession?> addSession(PracticeSession session) async {
    final created = await _api.createSongPractice(arg, session);
    state = AsyncValue.data([created, ...state.value ?? []]);
    return created;
  }
}

// ─── Fingerstyle Practice ─────────────────────────────────────────────────────

final fingerstylePracticeProvider =
    AsyncNotifierProvider.family<FingerstylePracticeNotifier, List<PracticeSession>, String>(
  FingerstylePracticeNotifier.new,
);

class FingerstylePracticeNotifier
    extends FamilyAsyncNotifier<List<PracticeSession>, String> {
  late ApiService _api;

  @override
  Future<List<PracticeSession>> build(String arg) async {
    _api = ref.read(apiServiceProvider);
    return _api.getFingerstylePractice(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state =
        await AsyncValue.guard(() => _api.getFingerstylePractice(arg));
  }

  Future<PracticeSession?> addSession(PracticeSession session) async {
    final created = await _api.createFingerstylePractice(arg, session);
    state = AsyncValue.data([created, ...state.value ?? []]);
    return created;
  }
}
