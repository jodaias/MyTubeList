import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:youtube_api/youtube_api.dart';
import '../models/video_model.dart';
import '../services/firebase_service.dart';

class FirebaseVideoProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final _youtubeApiKey = dotenv.env['YOUTUBE_API_KEY'] ?? '';
  late YoutubeAPI _youtubeApi;

  List<VideoModel> _allCachedVideos = [];
  List<String> _previousSearches = [];
  bool _isLoading = false;

  List<VideoModel> get allCachedVideos => _allCachedVideos;
  List<String> get previousSearches => _previousSearches;
  bool get isLoading => _isLoading;

  FirebaseVideoProvider() {
    _init();
  }

  Future<void> _init() async {
    _youtubeApi = YoutubeAPI(_youtubeApiKey, maxResults: 50);
  }

  /// 🔎 Busca vídeos no YouTube e retorna a lista sem salvar ainda
  Future<List<VideoModel>> search(String query) async {
    try {
      _isLoading = true;
      notifyListeners();

      List<YouTubeVideo> results =
          await _youtubeApi.search(query, type: "video");

      return results.map((e) {
        return VideoModel(
          id: e.id ?? '',
          title: e.title,
          thumbnailUrl: e.thumbnail.toMap()['high']['url'] ??
              e.thumbnail.toMap()['medium']['url'] ??
              e.thumbnail.toMap()['default']['url'],
        );
      }).toList();
    } catch (e) {
      // Silently handle search errors
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 📝 Adicionar termo de busca ao histórico do Firebase
  Future<void> addSearchTerm(String term, String profileId) async {
    try {
      notifyListeners();

      await _firebaseService.addSearchTerm(term, profileId);
      await loadPreviousSearches(profileId);
    } catch (e) {
      // Silently handle add search term errors
    } finally {
      notifyListeners();
    }
  }

  /// 📚 Carregar histórico de buscas do Firebase
  Future<void> loadPreviousSearches(String profileId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _previousSearches = await _firebaseService.getSearchHistory(profileId);
    } catch (e) {
      // Silently handle load history errors
      _previousSearches = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 💾 Salvar vídeo no cache local (mantém compatibilidade)
  Future<void> cacheVideo(VideoModel video) async {
    try {
      // Verificar se o vídeo já existe
      if (!_allCachedVideos.any((v) => v.id == video.id)) {
        _allCachedVideos.add(video);
        notifyListeners();
      }
    } catch (e) {
      // Silently handle cache errors
    }
  }

  /// ❌ Remover vídeo do cache local
  Future<void> removeVideoFromCache(String videoId) async {
    try {
      _allCachedVideos.removeWhere((video) => video.id == videoId);
      notifyListeners();
    } catch (e) {
      // Silently handle remove cache errors
    }
  }

  /// ✅ Retorna vídeos de uma lista específica
  List<VideoModel> getVideosForList(List<String> videoIds) {
    return _allCachedVideos
        .where((video) => videoIds.contains(video.id))
        .toList();
  }

  /// 🔄 Recarregar histórico de buscas
  Future<void> reloadSearchHistory(String profileId) async {
    await loadPreviousSearches(profileId);
  }

  /// 🧹 Limpar cache local
  void clearCache() {
    _allCachedVideos.clear();
    notifyListeners();
  }

  /// 🔍 Verificar se vídeo está no cache
  bool isVideoCached(String videoId) {
    return _allCachedVideos.any((video) => video.id == videoId);
  }
}
