// lib/models/fingerstyle_song.dart

import '../utils/json_utils.dart';

class FingerstyleSong {
  final String? id;
  final String title;
  final String artist;
  final String? genre;
  final String difficulty;
  final double? rating;
  final String? technique;
  final String? tuning;
  final int? bpm;
  final String? timeSignature;
  final String? key;
  final int? capo;
  final String? tabUrl;
  final String? arrangementNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String>? chordIds;
  final List<FingerstyleSequenceItem>? sequence;

  const FingerstyleSong({
    this.id,
    required this.title,
    required this.artist,
    this.genre,
    required this.difficulty,
    this.rating,
    this.technique,
    this.tuning,
    this.bpm,
    this.timeSignature,
    this.key,
    this.capo,
    this.tabUrl,
    this.arrangementNotes,
    this.createdAt,
    this.updatedAt,
    this.chordIds,
    this.sequence,
  });

  factory FingerstyleSong.fromJson(Map<String, dynamic> json) {
    final idCandidate = json['id'] ?? json['song_id'] ?? json['songId'] ?? json['_id'];
    final String? id = idCandidate == null
        ? null
        : idCandidate is String
            ? idCandidate
            : idCandidate.toString();

    return FingerstyleSong(
      id: id,
      title: json['title'] as String,
      artist: json['artist'] as String,
      genre: json['genre'] as String?,
      difficulty: json['difficulty'] as String? ?? 'beginner',
      rating: parseDouble(json['rating']),
      technique: json['technique'] as String?,
      tuning: json['tuning'] as String?,
      bpm: parseInt(json['tempo_bpm'] ?? json['bpm']),
      timeSignature: json['time_signature'] as String?,
      key: json['key'] as String?,
      capo: parseInt(json['capo']),
      tabUrl: json['tab_url'] as String?,
      arrangementNotes: json['arrangement_notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      chordIds: parseStringList(json['chordIds'] ?? json['chord_ids']),
      sequence: _parseFingerstyleSequence(json['sequence']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'artist': artist,
      if (genre != null) 'genre': genre,
      'difficulty': difficulty,
      if (rating != null) 'rating': rating,
      if (technique != null) 'technique': technique,
      if (tuning != null) 'tuning': tuning,
      if (bpm != null) 'tempo_bpm': bpm,
      if (timeSignature != null) 'time_signature': timeSignature,
      if (key != null) 'key': key,
      if (capo != null) 'capo': capo,
      if (tabUrl != null) 'tab_url': tabUrl,
      if (arrangementNotes != null) 'arrangement_notes': arrangementNotes,
      if (sequence != null)
        'sequence': sequence!.map((item) => item.toJson()).toList(),
      if (chordIds != null) 'chordIds': chordIds,
    };
  }

  FingerstyleSong copyWith({
    String? id,
    String? title,
    String? artist,
    String? genre,
    String? difficulty,
    double? rating,
    String? technique,
    String? tuning,
    int? bpm,
    String? timeSignature,
    String? key,
    int? capo,
    String? tabUrl,
    String? arrangementNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? chordIds,
    List<FingerstyleSequenceItem>? sequence,
  }) {
    return FingerstyleSong(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      genre: genre ?? this.genre,
      difficulty: difficulty ?? this.difficulty,
      rating: rating ?? this.rating,
      technique: technique ?? this.technique,
      tuning: tuning ?? this.tuning,
      bpm: bpm ?? this.bpm,
      timeSignature: timeSignature ?? this.timeSignature,
      key: key ?? this.key,
      capo: capo ?? this.capo,
      tabUrl: tabUrl ?? this.tabUrl,
      arrangementNotes: arrangementNotes ?? this.arrangementNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      chordIds: chordIds ?? this.chordIds,
      sequence: sequence ?? this.sequence,
    );
  }
}

List<FingerstyleSequenceItem>? _parseFingerstyleSequence(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    return value
        .map((e) => FingerstyleSequenceItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
  return null;
}

class FingerstyleSequenceItem {
  final String type;
  final String value;
  final double duration;

  FingerstyleSequenceItem({
    required this.type,
    required this.value,
    required this.duration,
  });

  factory FingerstyleSequenceItem.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] as String?)?.toLowerCase();
    return FingerstyleSequenceItem(
      type: type == 'note' ? 'note' : 'chord',
      value: json['value']?.toString() ?? '',
      duration: parseDouble(json['duration']) ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
      'duration': duration,
    };
  }

  String get display {
    final base = '$type: $value';
    return '$base (${duration.toString()})';
  }

  FingerstyleSequenceItem copyWith({
    String? type,
    String? value,
    double? duration,
  }) {
    return FingerstyleSequenceItem(
      type: type ?? this.type,
      value: value ?? this.value,
      duration: duration ?? this.duration,
    );
  }
}
