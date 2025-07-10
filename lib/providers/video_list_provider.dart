import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/video_list_model.dart';
import '../models/video_model.dart';

class VideoListProvider extends ChangeNotifier {
  static const String boxName = 'videoListsBox';
  late Box<VideoListModel> _box;
  List<VideoListModel> _lists = [];

  List<VideoListModel> get lists => _lists;

  Future<void> init() async {
    _box = await Hive.openBox<VideoListModel>(boxName);
    _lists = _box.values.toList();
    notifyListeners();
  }

  List<VideoListModel> getListsByProfile(String profileId) {
    return _lists.where((l) => l.profileId == profileId).toList();
  }

  VideoListModel getListById(String listId) {
    return _lists.firstWhere((l) => l.id == listId);
  }

  Future<String> createList(String name, String profileId) async {
    final list = VideoListModel(
      id: Uuid().v4(),
      name: name,
      profileId: profileId,
      videos: [],
    );
    await _box.put(list.id, list);
    _lists = _box.values.toList();
    notifyListeners();
    return list.id;
  }

  Future<void> addVideoToList(String listId, VideoModel video) async {
    final listIndex = _lists.indexWhere((l) => l.id == listId);
    if (listIndex == -1) return;

    final list = _lists[listIndex];
    final updatedVideos = [...list.videos, video];

    final updatedList = list.copyWith(videos: updatedVideos);
    await _box.put(updatedList.id, updatedList);

    _lists = _box.values.toList();
    notifyListeners();
  }

  Future<void> removeVideoFromList(String listId, String videoId) async {
    final listIndex = _lists.indexWhere((l) => l.id == listId);
    if (listIndex == -1) return;

    final list = _lists[listIndex];
    final updatedVideos = list.videos.where((v) => v.id != videoId).toList();

    final updatedList = list.copyWith(videos: updatedVideos);
    await _box.put(updatedList.id, updatedList);

    _lists = _box.values.toList();
    notifyListeners();
  }

  Future<void> deleteList(String listId) async {
    await _box.delete(listId);
    _lists = _box.values.toList();
    notifyListeners();
  }

  Future<void> updateVideoOrder({
    required String listId,
    required List<VideoModel> newOrder,
  }) async {
    final listIndex = _lists.indexWhere((l) => l.id == listId);
    if (listIndex == -1) return;

    final list = _lists[listIndex];
    final updatedList = list.copyWith(videos: newOrder);

    await _box.put(listId, updatedList);

    _lists = _box.values.toList();
    notifyListeners();
  }
}
