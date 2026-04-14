int? parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final intValue = int.tryParse(value);
    if (intValue != null) return intValue;
    final doubleValue = double.tryParse(value);
    return doubleValue?.toInt();
  }
  return null;
}

double? parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

List<int?>? parseNullableIntList(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    return value.map((e) => parseInt(e)).toList();
  }
  if (value is String) {
    return value
        .split(',')
        .map((e) => parseInt(e.trim()))
        .toList();
  }
  return null;
}

List<int>? parseIntList(dynamic value) {
  return parseNullableIntList(value)?.whereType<int>().toList();
}

List<String>? parseStringList(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  if (value is String) {
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
  return null;
}
