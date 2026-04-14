// lib/models/chord.dart

import '../utils/json_utils.dart';

class Chord {
  final int? id;
  final String name;
  final List<int?>? frets; // null = muted string, -1 = open
  final List<int?>? fingers;
  final int? baseFret;
  final String? notes;
  final String? diagramData;

  const Chord({
    this.id,
    required this.name,
    this.frets,
    this.fingers,
    this.baseFret,
    this.notes,
    this.diagramData,
  });

  factory Chord.fromJson(Map<String, dynamic> json) {
    return Chord(
      id: parseInt(json['id']),
      name: json['name'] as String,
      frets: parseNullableIntList(json['frets']),
      fingers: parseNullableIntList(json['fingers']),
      baseFret: parseInt(json['base_fret']),
      notes: json['notes'] as String?,
      diagramData: json['diagram_data'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (frets != null) 'frets': frets,
      if (fingers != null) 'fingers': fingers,
      if (baseFret != null) 'base_fret': baseFret,
      if (notes != null) 'notes': notes,
      if (diagramData != null) 'diagram_data': diagramData,
    };
  }

  Chord copyWith({
    int? id,
    String? name,
    List<int?>? frets,
    List<int?>? fingers,
    int? baseFret,
    String? notes,
    String? diagramData,
  }) {
    return Chord(
      id: id ?? this.id,
      name: name ?? this.name,
      frets: frets ?? this.frets,
      fingers: fingers ?? this.fingers,
      baseFret: baseFret ?? this.baseFret,
      notes: notes ?? this.notes,
      diagramData: diagramData ?? this.diagramData,
    );
  }
}
