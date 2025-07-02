import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileProvider extends ChangeNotifier {
  final _uuid = Uuid();
  static const String boxName = 'profilesBox';

  late Box<ProfileModel> _box;
  List<ProfileModel> _profiles = [];
  ProfileModel? _selectedProfile;

  List<ProfileModel> get profiles => _profiles;
  ProfileModel? get selectedProfile => _selectedProfile;

  ProfileProvider() {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<ProfileModel>(boxName);
    _profiles = _box.values.toList();
    if (_profiles.isNotEmpty) {
      _selectedProfile = _profiles.first;
    }

    notifyListeners();
  }

  Future<void> addProfile(String name) async {
    final profile = ProfileModel(id: _uuid.v4(), name: name);
    await _box.put(profile.id, profile);
    _profiles = _box.values.toList();
    notifyListeners();
  }

  Future<void> selectProfile(ProfileModel profile) async {
    _selectedProfile = profile;
    notifyListeners();
  }

  Future<void> deleteProfile(String id) async {
    await _box.delete(id);
    _profiles = _box.values.toList();
    if (_selectedProfile?.id == id) {
      _selectedProfile = null;
    }
    notifyListeners();
  }

  Future<void> clearProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_profile');
    _selectedProfile = null;
    notifyListeners();
  }

  Future<void> addAllowedVideo(String videoId) async {
    if (_selectedProfile == null) return;
    final updatedList = List<String>.from(_selectedProfile!.allowedVideoIds)
      ..add(videoId);
    final updatedProfile =
        _selectedProfile!.copyWith(allowedVideoIds: updatedList);
    await _box.put(updatedProfile.id, updatedProfile);
    _selectedProfile = updatedProfile;
    notifyListeners();
  }

  Future<void> removeAllowedVideo(String videoId) async {
    if (_selectedProfile == null) return;
    final updatedList = List<String>.from(_selectedProfile!.allowedVideoIds)
      ..remove(videoId);
    final updatedProfile =
        _selectedProfile!.copyWith(allowedVideoIds: updatedList);
    await _box.put(updatedProfile.id, updatedProfile);
    _selectedProfile = updatedProfile;
    notifyListeners();
  }
}
