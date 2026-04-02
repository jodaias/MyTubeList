import 'package:flutter/material.dart';
import '../models/video_list_model.dart';
import '../models/video_model.dart';
import '../services/firebase_service.dart';
import '../di/service_locator.dart';

class FirebaseVideoListProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = getIt<FirebaseService>();

  List<VideoListModel> _videoLists = [];
  bool _isLoading = false;

  List<VideoListModel> get videoLists => _videoLists;
  bool get isLoading => _isLoading;

  /// 📋 Carregar listas de vídeos do Firebase
  Future<void> loadVideoLists() async {
    try {
      _isLoading = true;
      notifyListeners();

      _videoLists = await _firebaseService.getVideoLists();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      // Silently handle load errors
    }
  }

  /// ➕ Criar nova lista de vídeos
  Future<bool> createVideoList(String name, String profileId) async {
    try {
      notifyListeners();

      final videoList = VideoListModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        profileId: profileId,
      );

      await _firebaseService.createVideoList(videoList);
      _videoLists.add(videoList);

      return true;
    } catch (e) {
      // Silently handle creation errors
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// 📝 Atualizar lista de vídeos
  Future<bool> updateVideoList(VideoListModel videoList) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firebaseService.updateVideoList(videoList);

      final index = _videoLists.indexWhere((list) => list.id == videoList.id);
      if (index != -1) {
        _videoLists[index] = videoList;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      // Silently handle update errors
      return false;
    }
  }

  /// ❌ Deletar lista de vídeos
  Future<bool> deleteVideoList(String listId) async {
    try {
      notifyListeners();

      await _firebaseService.deleteVideoList(listId);
      _videoLists.removeWhere((list) => list.id == listId);

      return true;
    } catch (e) {
      // Silently handle delete errors
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// ➕ Adicionar vídeo à lista
  Future<bool> addVideoToList(String listId, VideoModel video) async {
    try {
      final videoList = _videoLists.firstWhere((list) => list.id == listId);
      final updatedVideos = List<VideoModel>.from(videoList.videos);

      // Verificar se o vídeo já existe
      if (!updatedVideos.any((v) => v.id == video.id)) {
        updatedVideos.add(video);

        final updatedVideoList = videoList.copyWith(videos: updatedVideos);
        return await updateVideoList(updatedVideoList);
      }

      return true;
    } catch (e) {
      // Silently handle add video errors
      return false;
    }
  }

  /// ➕ Adicionar vários vídeos à lista (batch)
  Future<bool> addVideosToList(String listId, List<VideoModel> videos) async {
    try {
      final videoList = _videoLists.firstWhere((list) => list.id == listId);
      final updatedVideos = List<VideoModel>.from(videoList.videos);

      // Adiciona apenas vídeos que ainda não estão na lista
      for (final video in videos) {
        if (!updatedVideos.any((v) => v.id == video.id)) {
          updatedVideos.add(video);
        }
      }

      final updatedVideoList = videoList.copyWith(videos: updatedVideos);
      return await updateVideoList(updatedVideoList);
    } catch (e) {
      // Silently handle batch add errors
      return false;
    }
  }

  /// ➖ Remover vídeo da lista
  Future<bool> removeVideoFromList(String listId, String videoId) async {
    try {
      final videoList = _videoLists.firstWhere((list) => list.id == listId);
      final updatedVideos =
          videoList.videos.where((video) => video.id != videoId).toList();

      final updatedVideoList = videoList.copyWith(videos: updatedVideos);
      return await updateVideoList(updatedVideoList);
    } catch (e) {
      // Silently handle remove video errors
      return false;
    }
  }

  /// 🔍 Buscar lista por ID
  VideoListModel? getVideoListById(String listId) {
    try {
      return _videoLists.firstWhere((list) => list.id == listId);
    } catch (e) {
      return null;
    }
  }

  /// 👤 Buscar listas por perfil
  List<VideoListModel> getListsByProfile(String profileId) {
    return _videoLists.where((list) => list.profileId == profileId).toList();
  }

  /// 🔄 Sincronizar listas com Firebase
  Future<bool> syncVideoListsWithFirebase(
      List<VideoListModel> videoLists) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firebaseService.syncVideoListsWithFirebase(videoLists);
      _videoLists = videoLists;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      // Silently handle sync errors
      return false;
    }
  }

  /// 📋 Atualizar ordem dos vídeos
  Future<void> updateVideoOrder({
    required String listId,
    required List<VideoModel> newOrder,
  }) async {
    try {
      final videoList = _videoLists.firstWhere((list) => list.id == listId);
      final updatedVideoList = videoList.copyWith(videos: newOrder);
      await updateVideoList(updatedVideoList);
    } catch (e) {
      // Silently handle reorder errors
    }
  }

  /// 🔄 Sincronizar com Firebase
  Future<void> syncWithFirebase(dynamic profileProvider) async {
    try {
      await syncVideoListsWithFirebase(_videoLists);
    } catch (e) {
      // Silently handle Firebase sync errors
    }
  }

  /// 🗑️ Limpar dados locais
  Future<void> clearLocalData() async {
    try {
      _videoLists.clear();
      notifyListeners();
    } catch (e) {
      // Silently handle clear errors
    }
  }

  /// Renomear lista de vídeos
  Future<void> renameVideoList(String listId, String newName) async {
    final index = _videoLists.indexWhere((list) => list.id == listId);
    if (index != -1) {
      final updated = _videoLists[index].copyWith(name: newName);
      await updateVideoList(updated);
    }
  }
}
