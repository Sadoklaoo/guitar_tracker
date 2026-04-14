// lib/services/api_service.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/song.dart';
import '../models/chord.dart';
import '../models/practice_session.dart';
import '../models/fingerstyle_song.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(_LogInterceptor());
    _dio.interceptors.add(_ErrorInterceptor());

    // Avoid sending a global Content-Type header on GET requests in Flutter Web.
    // A browser preflight OPTIONS request is triggered when Content-Type is set to application/json,
    // and the backend must support OPTIONS/CORS to avoid 405 responses.
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.method == 'GET' || options.method == 'DELETE' ||
            options.method == 'HEAD' || options.method == 'OPTIONS') {
          options.headers.remove('Content-Type');
        }
        handler.next(options);
      },
    ));
  }

  // ─── Songs ────────────────────────────────────────────────────────────────

  Future<List<Song>> getSongs() async {
    final response = await _dio.get(ApiConfig.songs);
    return compute(_parseSongs, response.data as List<dynamic>);
  }

  Future<Song> getSong(String id) async {
    final response = await _dio.get(ApiConfig.songById(id));
    return compute(_parseSong, response.data as Map<String, dynamic>);
  }

  Future<Song> createSong(Song song) async {
    final response = await _dio.post(ApiConfig.songs, data: song.toJson());
    return Song.fromJson(response.data);
  }

  Future<Song> updateSong(String id, Song song) async {
    final response =
        await _dio.put(ApiConfig.songById(id), data: song.toJson());
    return Song.fromJson(response.data);
  }

  Future<void> deleteSong(String id) async {
    await _dio.delete(ApiConfig.songById(id));
  }

  // ─── Practice Sessions ────────────────────────────────────────────────────

  Future<List<PracticeSession>> getSongPractice(String songId) async {
    final response = await _dio.get(ApiConfig.songPractice(songId));
    return compute(_parsePracticeSessions, response.data as List<dynamic>);
  }

  Future<PracticeSession> createSongPractice(
      String songId, PracticeSession session) async {
    final response = await _dio.post(
      ApiConfig.songPractice(songId),
      data: session.toJson(),
    );
    return compute(_parsePracticeSession, response.data as Map<String, dynamic>);
  }

  Future<List<PracticeSession>> getFingerstylePractice(
      String fingerstyleId) async {
    final response =
        await _dio.get(ApiConfig.fingerstylePractice(fingerstyleId));
    return compute(_parsePracticeSessions, response.data as List<dynamic>);
  }

  Future<PracticeSession> createFingerstylePractice(
      String fingerstyleId, PracticeSession session) async {
    final response = await _dio.post(
      ApiConfig.fingerstylePractice(fingerstyleId),
      data: session.toJson(),
    );
    return compute(_parsePracticeSession, response.data as Map<String, dynamic>);
  }

  // ─── Chords ───────────────────────────────────────────────────────────────

  Future<List<Chord>> getChords() async {
    final response = await _dio.get(ApiConfig.chords);
    return compute(_parseChords, response.data as List<dynamic>);
  }

  Future<Chord> getChord(int id) async {
    final response = await _dio.get(ApiConfig.chordById(id));
    return compute(_parseChord, response.data as Map<String, dynamic>);
  }
  Future<List<Chord>> getSongChords(String songId) async {
    final response = await _dio.get(ApiConfig.songChords(songId));
    return compute(_parseChords, response.data as List<dynamic>);
  }
  // ─── Fingerstyle Songs ───────────────────────────────────────────────────

  Future<List<FingerstyleSong>> getFingerstyleSongs({
    String? technique,
    String? difficulty,
    String? tuning,
    double? minRating,
  }) async {
    final queryParams = <String, dynamic>{};
    if (technique != null && technique.isNotEmpty) {
      queryParams['technique'] = technique;
    }
    if (difficulty != null && difficulty.isNotEmpty) {
      queryParams['difficulty'] = difficulty;
    }
    if (tuning != null && tuning.isNotEmpty) queryParams['tuning'] = tuning;
    if (minRating != null) queryParams['min_rating'] = minRating;

    final response = await _dio.get(
      ApiConfig.fingerstyle,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    return compute(_parseFingerstyleSongs, response.data as List<dynamic>);
  }

  Future<FingerstyleSong> getFingerstyleSong(String id) async {
    final response = await _dio.get(ApiConfig.fingerstyleById(id));
    return compute(_parseFingerstyleSong, response.data as Map<String, dynamic>);
  }

  Future<FingerstyleSong> createFingerstyleSong(FingerstyleSong song) async {
    final response =
        await _dio.post(ApiConfig.fingerstyle, data: song.toJson());
    return FingerstyleSong.fromJson(response.data);
  }

  Future<FingerstyleSong> updateFingerstyleSong(
      String id, FingerstyleSong song) async {
    final response =
        await _dio.put(ApiConfig.fingerstyleById(id), data: song.toJson());
    return FingerstyleSong.fromJson(response.data);
  }

  Future<void> deleteFingerstyleSong(String id) async {
    await _dio.delete(ApiConfig.fingerstyleById(id));
  }

  Future<List<Chord>> getFingerstyleChords(String id) async {
    final response = await _dio.get(ApiConfig.fingerstyleChords(id));
    return compute(_parseChords, response.data as List<dynamic>);
  }

  // ─── Meta ─────────────────────────────────────────────────────────────────

  Future<List<String>> getTechniques() async {
    final response = await _dio.get(ApiConfig.fingerstyleMeta);
    return (response.data as List).map((e) => e.toString()).toList();
  }
}

// ─── Interceptors ─────────────────────────────────────────────────────────────

class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // ignore: avoid_print
    print('[API] ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // ignore: avoid_print
    print('[API] ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ignore: avoid_print
    print('[API ERROR] ${err.message}');
    handler.next(err);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String message;
    final statusCode = err.response?.statusCode;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timed out. Please check your network.';
        break;
      case DioExceptionType.connectionError:
        message = 'Cannot connect to server. Is the backend running?';
        break;
      case DioExceptionType.badResponse:
        message = _extractErrorMessage(err.response?.data) ??
            'Server error (${statusCode ?? 'unknown'})';
        break;
      default:
        message = err.message ?? 'An unexpected error occurred.';
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: ApiException(message, statusCode: statusCode),
        message: message,
        type: err.type,
        response: err.response,
      ),
    );
  }
}

String? _extractErrorMessage(dynamic data) {
  if (data == null) return null;
  if (data is String) return data;
  if (data is Map) {
    if (data.containsKey('detail')) {
      return data['detail'].toString();
    }
    if (data.containsKey('message')) {
      return data['message'].toString();
    }
    if (data.containsKey('errors')) {
      final errors = data['errors'];
      if (errors is String) return errors;
      if (errors is List) return errors.join(', ');
      if (errors is Map) {
        return errors.values
          .expand((e) => e is List ? e.map((item) => item.toString()) : [e.toString()])
          .join(', ');
      }
    }
    return data.values.map((value) => value.toString()).join(', ');
  }
  if (data is List) {
    return data.map((e) => e.toString()).join(', ');
  }
  return data.toString();
}

List<Song> _parseSongs(List<dynamic> json) {
  return json
      .map((e) => Song.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

Song _parseSong(Map<String, dynamic> json) {
  return Song.fromJson(json);
}

List<PracticeSession> _parsePracticeSessions(List<dynamic> json) {
  return json
      .map((e) => PracticeSession.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

PracticeSession _parsePracticeSession(Map<String, dynamic> json) {
  return PracticeSession.fromJson(json);
}

List<Chord> _parseChords(List<dynamic> json) {
  return json
      .map((e) => Chord.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

Chord _parseChord(Map<String, dynamic> json) {
  return Chord.fromJson(json);
}

List<FingerstyleSong> _parseFingerstyleSongs(List<dynamic> json) {
  return json
      .map((e) => FingerstyleSong.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();
}

FingerstyleSong _parseFingerstyleSong(Map<String, dynamic> json) {
  return FingerstyleSong.fromJson(json);
}
