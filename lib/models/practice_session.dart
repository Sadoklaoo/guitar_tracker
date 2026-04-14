// lib/models/practice_session.dart

import '../utils/json_utils.dart';

class PracticeSession {
  final int? id;
  final int? songId;
  final int? fingerstyleSongId;
  final int durationMinutes;
  final String? notes;
  final DateTime? practicedAt;

  const PracticeSession({
    this.id,
    this.songId,
    this.fingerstyleSongId,
    required this.durationMinutes,
    this.notes,
    this.practicedAt,
  });

  factory PracticeSession.fromJson(Map<String, dynamic> json) {
    return PracticeSession(
      id: parseInt(json['id']),
      songId: parseInt(json['song_id']),
      fingerstyleSongId: parseInt(json['fingerstyle_song_id']),
      durationMinutes: parseInt(json['duration_minutes']) ?? 0,
      notes: json['notes'] as String?,
      practicedAt: json['practiced_at'] != null
          ? DateTime.tryParse(json['practiced_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (songId != null) 'song_id': songId,
      if (fingerstyleSongId != null) 'fingerstyle_song_id': fingerstyleSongId,
      'duration_minutes': durationMinutes,
      if (notes != null) 'notes': notes,
    };
  }

  PracticeSession copyWith({
    int? id,
    int? songId,
    int? fingerstyleSongId,
    int? durationMinutes,
    String? notes,
    DateTime? practicedAt,
  }) {
    return PracticeSession(
      id: id ?? this.id,
      songId: songId ?? this.songId,
      fingerstyleSongId: fingerstyleSongId ?? this.fingerstyleSongId,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      practicedAt: practicedAt ?? this.practicedAt,
    );
  }
}
