import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/video_list_model.dart';
import '../models/video_model.dart';

class VideoListRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  auth.User? get _currentUser => _auth.currentUser;

  CollectionReference get _usersCollection => _firestore.collection('users');

  CollectionReference _userVideoListsCollection(String userId) =>
      _usersCollection.doc(userId).collection('videoLists');

  Future<void> createVideoList(VideoListModel videoList) async {
    final user = _currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    await _userVideoListsCollection(user.uid).doc(videoList.id).set({
      'id': videoList.id,
      'name': videoList.name,
      'profileId': videoList.profileId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'videos': videoList.videos
          .map((video) => {
                'id': video.id,
                'title': video.title,
                'thumbnailUrl': video.thumbnailUrl,
                'addedAt': DateTime.now().toIso8601String(),
              })
          .toList(),
    });
  }

  Future<List<VideoListModel>> getVideoLists() async {
    try {
      final user = _currentUser;
      if (user == null) return [];

      final querySnapshot = await _userVideoListsCollection(user.uid).get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return VideoListModel(
          id: data['id'],
          name: data['name'],
          profileId: data['profileId'],
          videos: (data['videos'] as List<dynamic>? ?? []).map((videoData) {
            return VideoModel(
              id: videoData['id'],
              title: videoData['title'],
              thumbnailUrl: videoData['thumbnailUrl'],
            );
          }).toList(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> updateVideoList(VideoListModel videoList) async {
    final user = _currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    await _userVideoListsCollection(user.uid).doc(videoList.id).update({
      'name': videoList.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'videos': videoList.videos
          .map((video) => {
                'id': video.id,
                'title': video.title,
                'thumbnailUrl': video.thumbnailUrl,
                'addedAt': DateTime.now().toIso8601String(),
              })
          .toList(),
    });
  }

  Future<void> deleteVideoList(String listId) async {
    final user = _currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    await _userVideoListsCollection(user.uid).doc(listId).delete();
  }

  Future<void> syncVideoListsWithFirebase(
      List<VideoListModel> videoLists) async {
    final user = _currentUser;
    if (user == null) {
      try {
        final credential = await _auth.signInAnonymously();
        if (credential.user == null) return;
      } catch (e) {
        return;
      }
    }

    for (final videoList in videoLists) {
      final existingLists = await getVideoLists();
      final existingList = existingLists.firstWhere(
        (list) => list.id == videoList.id,
        orElse: () => videoList,
      );

      if (existingList.id == videoList.id) {
        await updateVideoList(videoList);
      } else {
        await createVideoList(videoList);
      }
    }
  }
}
