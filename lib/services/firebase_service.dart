import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/profile_model.dart';
import '../models/video_list_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/video_list_repository.dart';
import '../repositories/search_repository.dart';

/// Facade that delegates to specific repositories.
/// Kept for backward compatibility — providers can migrate
/// to use repositories directly over time.
class FirebaseService {
  final AuthRepository _authRepo = AuthRepository();
  final VideoListRepository _videoListRepo = VideoListRepository();
  final SearchRepository _searchRepo = SearchRepository();

  AuthRepository get authRepo => _authRepo;
  VideoListRepository get videoListRepo => _videoListRepo;
  SearchRepository get searchRepo => _searchRepo;

  // Auth
  auth.User? get currentUser => _authRepo.currentUser;

  Future<bool> signInWithUsername(String username, String password) =>
      _authRepo.signInWithUsername(username, password);

  Future<bool> createUserWithPassword(
          String username, String password, String name,
          {UserCategory? category}) =>
      _authRepo.createUserWithPassword(username, password, name,
          category: category);

  Future<void> signOut() => _authRepo.signOut();

  Future<void> deleteCurrentUser() => _authRepo.deleteCurrentUser();

  Future<bool> updateEmail(String newEmail) => _authRepo.updateEmail(newEmail);

  Future<bool> changePassword(String currentPassword, String newPassword) =>
      _authRepo.changePassword(currentPassword, newPassword);

  Future<bool> sendPasswordResetEmail(String email) =>
      _authRepo.sendPasswordResetEmail(email);

  bool isEmailVerified() => _authRepo.isEmailVerified();

  Future<bool> sendEmailVerification() => _authRepo.sendEmailVerification();

  Future<void> reloadUser() => _authRepo.reloadUser();

  // Profile
  Future<void> createProfile(ProfileModel profile) =>
      _authRepo.createProfile(profile);

  Future<ProfileModel?> getProfile() => _authRepo.getProfile();

  Future<ProfileModel?> getProfileByUsername(String username) =>
      _authRepo.getProfileByUsername(username);

  Future<void> syncProfileWithFirebase(ProfileModel profile) =>
      _authRepo.syncProfileWithFirebase(profile);

  // Video Lists
  Future<void> createVideoList(VideoListModel videoList) =>
      _videoListRepo.createVideoList(videoList);

  Future<List<VideoListModel>> getVideoLists() =>
      _videoListRepo.getVideoLists();

  Future<void> updateVideoList(VideoListModel videoList) =>
      _videoListRepo.updateVideoList(videoList);

  Future<void> deleteVideoList(String listId) =>
      _videoListRepo.deleteVideoList(listId);

  Future<void> syncVideoListsWithFirebase(List<VideoListModel> videoLists) =>
      _videoListRepo.syncVideoListsWithFirebase(videoLists);

  // Search History
  Future<void> addSearchTerm(String term, String profileId, String listId) =>
      _searchRepo.addSearchTerm(term, profileId, listId);

  Future<List<String>> getSearchHistory(String profileId, String listId) =>
      _searchRepo.getSearchHistory(profileId, listId);
}
