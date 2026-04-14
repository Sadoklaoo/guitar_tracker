// lib/models/song.dart

import '../models/chord.dart';
import '../utils/json_utils.dart';

String _normalizeDifficulty(String? value) {
  if (value == null) return 'Beginner';
  final lower = value.toLowerCase();
  switch (lower) {
    case 'beginner':
      return 'Beginner';
    case 'intermediate':
      return 'Intermediate';
    case 'advanced':
      return 'Advanced';
    default:
      return value;
  }
}

class Song {
  final String? id;
  final String title;
  final String artist;
  final String? genre;
  final String difficulty;
  final double? rating;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<int>? chordIds;
  final List<SongSequenceItem>? sequence;
  final int? chordCount;
  final List<Chord>? chordDetails;

  const Song({
    this.id,
    required this.title,
    required this.artist,
    this.genre,
    required this.difficulty,
    this.rating,
    this.createdAt,
    this.updatedAt,
    this.chordIds,
    this.sequence,
    this.chordCount,
    this.chordDetails,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    final idCandidate = json['id'] ?? json['song_id'] ?? json['songId'] ?? json['_id'];
    final String? id = idCandidate == null
        ? null
        : idCandidate is String
            ? idCandidate
            : idCandidate.toString();

    if (id == null || id.isEmpty) {
      // ignore: avoid_print
      print('[Song.fromJson] missing id; json.keys=${json.keys.toList()}');
      // ignore: avoid_print
      print('[Song.fromJson] raw id value: $idCandidate (${idCandidate?.runtimeType})');
      if (idCandidate is Map) {
        // ignore: unnecessary_brace_in_string_interps, avoid_print
        print('[Song.fromJson] nested id map: ${idCandidate}');
      }
    }

    return Song(
      id: id,
      title: json['title'] as String,
      artist: json['artist'] as String,
      genre: json['genre'] as String?,
      difficulty: _normalizeDifficulty(json['difficulty'] as String? ?? 'Beginner'),
      rating: parseDouble(json['rating']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      chordIds: parseIntList(json['chord_ids'] ?? json['chords']),
      sequence: _parseSongSequence(json['sequence'] ?? json['sequence_items'] ?? json['sequence_text']),
      chordCount: parseInt(json['chord_count']),
      chordDetails: json['chord_details'] is List
          ? (json['chord_details'] as List)
              .map((e) => Chord.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : null,
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
      if (sequence != null)
        'sequence': sequence!.map((item) => item.toJson()).toList(),
      if (chordIds != null) 'chord_ids': chordIds,
      if (chordCount != null) 'chord_count': chordCount,
      if (chordDetails != null)
        'chord_details': chordDetails!.map((c) => c.toJson()).toList(),
    };
  }

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? genre,
    String? difficulty,
    double? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<int>? chordIds,
    List<SongSequenceItem>? sequence,
    int? chordCount,
    List<Chord>? chordDetails,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      genre: genre ?? this.genre,
      difficulty: difficulty ?? this.difficulty,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      chordIds: chordIds ?? this.chordIds,
      sequence: sequence ?? this.sequence,
      chordCount: chordCount ?? this.chordCount,
      chordDetails: chordDetails ?? this.chordDetails,
    );
  }
}

List<SongSequenceItem>? _parseSongSequence(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    return value
        .map((e) => SongSequenceItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
  if (value is String) {
    return SongSequenceItem.parseText(value);
  }
  return null;
}

class SongSequenceItem {
  final String name;
  final int repeats;

  SongSequenceItem({required this.name, this.repeats = 1});

  factory SongSequenceItem.fromJson(Map<String, dynamic> json) {
    return SongSequenceItem(
      name: json['name']?.toString() ?? '',
      repeats: parseInt(json['repeats'] ?? json['count']) ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (repeats > 1) 'repeats': repeats,
    };
  }

  String get display => repeats > 1 ? '$name x$repeats' : name;

  SongSequenceItem copyWith({String? name, int? repeats}) {
    return SongSequenceItem(
      name: name ?? this.name,
      repeats: repeats ?? this.repeats,
    );
  }

  static List<SongSequenceItem> parseText(String raw) {
    final normalized = raw.trim().replaceAll('*', 'x');

    final parts = normalized.split(RegExp(r'[\s,]+'));
    final items = <SongSequenceItem>[];

    for (var i = 0; i < parts.length; i++) {
      final part = parts[i].trim();
      if (part.isEmpty) continue;

      if (part.toLowerCase() == 'x' &&
          items.isNotEmpty &&
          i + 1 < parts.length &&
          int.tryParse(parts[i + 1]) != null) {
        final previous = items.removeLast();
        final repeats = int.parse(parts[i + 1]);
        items.add(previous.copyWith(repeats: repeats));
        i += 1;
        continue;
      }

      final match = RegExp(r'^(.*?)(?:x(\d+))?$', caseSensitive: false)
          .firstMatch(part);
      if (match != null) {
        final name = match.group(1)?.trim() ?? '';
        final repeats = int.tryParse(match.group(2) ?? '') ?? 1;
        if (name.isNotEmpty) {
          items.add(SongSequenceItem(name: name, repeats: repeats));
          continue;
        }
      }

      items.add(SongSequenceItem(name: part));
    }

    return items;
  }
}
