import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive/hive.dart';
import 'package:youtube_api/youtube_api.dart';
import '../models/video_model.dart';
import '../providers/profile_provider.dart';
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

  List<VideoModel> allowedVideos = [];

  VideoProvider() {
    _init();
  }

  Future<void> _init() async {
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

    // Atualiza o provider em memória também, se desejar manter local
    _previousSearches = searches;
    notifyListeners();
  }

  Future<void> loadPreviousSearches(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'previousSearches_$profileId';

    _previousSearches = prefs.getStringList(key) ?? [];
    notifyListeners();
  }

  /// 💾 Salva ou atualiza um vídeo no cache local
  Future<void> cacheVideo(VideoModel video) async {
    await _videoBox.put(video.id, video.toMap());
    if (!_allCachedVideos.any((v) => v.id == video.id)) {
      _allCachedVideos.add(video);
      notifyListeners();
    }
  }

  /// ❌ Remove um vídeo do cache (opcional)
  Future<void> removeVideoFromCache(String videoId) async {
    await _videoBox.delete(videoId);
    _allCachedVideos.removeWhere((v) => v.id == videoId);
    notifyListeners();
  }

  /// ✅ Retorna vídeos permitidos de acordo com o perfil ativo
  List<VideoModel> getAllowedVideos(ProfileProvider profileProvider) {
    final allowedIds = profileProvider.selectedProfile?.allowedVideoIds ?? [];
    return _allCachedVideos
        .where((video) => allowedIds.contains(video.id))
        .toList();
  }

  List<VideoModel> getCachedVideosByIds(List<String> ids) {
    return _allCachedVideos.where((video) => ids.contains(video.id)).toList();
  }

  void setAllowedVideos(List<VideoModel> value) {
    allowedVideos = value;
  }
}
