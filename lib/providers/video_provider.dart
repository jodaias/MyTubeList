import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
import 'package:youtube_api/youtube_api.dart';
import '../models/video_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VideoProvider extends ChangeNotifier {
  static const String videosBoxName = 'videosBox';
  final _youtubeApiKey = dotenv.env['YOUTUBE_API_KEY'] ?? '';

  late Box _videoBox;
  late YoutubeAPI _youtubeApi;

  List<VideoModel> _allCachedVideos = [];
  List<VideoModel> get allCachedVideos => _allCachedVideos;

  List<String> _previousSearches = [];
  List<String> get previousSearches => _previousSearches;

  VideoProvider() {
    init();
  }

  Future<void> init() async {
    _videoBox = await Hive.openBox(videosBoxName);
    _youtubeApi = YoutubeAPI(_youtubeApiKey, maxResults: 50);

    // Carrega vídeos salvos em cache ao iniciar
    _allCachedVideos = _videoBox.values
        .map((e) => VideoModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    notifyListeners();
  }

  /// 🔎 Busca vídeos no YouTube e retorna a lista sem salvar ainda
  Future<List<VideoModel>> search(String query) async {
    List<YouTubeVideo> results = await _youtubeApi.search(query, type: "video");

    return results.map((e) {
      return VideoModel(
        id: e.id ?? '',
        title: e.title,
        thumbnailUrl: e.thumbnail.toMap()['high']['url'] ??
            e.thumbnail.toMap()['medium']['url'] ??
            e.thumbnail.toMap()['default']['url'],
      );
    }).toList();
  }

  Future<void> addSearchTerm(String term, String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'previousSearches_$profileId';

    List<String> searches = prefs.getStringList(key) ?? [];

    if (!searches.contains(term)) {
      searches.insert(0, term);
      if (searches.length > 10) {
        searches = searches.sublist(0, 10);
      }
      await prefs.setStringList(key, searches);
    }

    _previousSearches = prefs.getStringList(key) ?? [];

    notifyListeners();
  }

  Future<void> loadPreviousSearches(String profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'previousSearches_$profileId';

      _previousSearches = prefs.getStringList(key) ?? [];
    } catch (e) {
      _previousSearches = [];
    }
    notifyListeners();
  }

  /// 💾 Salva ou atualiza um vídeo no cache local
  Future<void> cacheVideo(VideoModel video) async {
    await _videoBox.put(video.id, video.toMap());

    _allCachedVideos = _videoBox.values
        .map((e) => VideoModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    notifyListeners();
  }

  /// ❌ Remove um vídeo do cache (opcional)
  Future<void> removeVideoFromCache(String videoId) async {
    await _videoBox.delete(videoId);

    _allCachedVideos = _videoBox.values
        .map((e) => VideoModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    notifyListeners();
  }

  /// ✅ Retorna vídeos de uma lista específica
  List<VideoModel> getVideosForList(List<String> videoIds) {
    return _allCachedVideos
        .where((video) => videoIds.contains(video.id))
        .toList();
  }
}
