// lib/config/api_config.dart

class ApiConfig {
  static const String baseUrl = 'http://192.168.0.15:8000';

  // Songs
  static const String songs = '/songs';
  static String songById(String id) => '/songs/$id';


  // Chords
  static const String chords = '/chords';
  static String chordById(int id) => '/chords/$id';
  static String songChords(String id) => '/songs/$id/chords';

  // Fingerstyle
  static const String fingerstyle = '/fingerstyle';
  static String fingerstyleById(String id) => '/fingerstyle/$id';
  static String fingerstyleChords(String id) => '/fingerstyle/$id/chords';
  static const String fingerstyleMeta = '/fingerstyle/meta/techniques';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
}
