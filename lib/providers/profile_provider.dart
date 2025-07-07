import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileProvider extends ChangeNotifier {
  static const String boxName = 'profilesBox';

  late Box<ProfileModel> _box;
  List<ProfileModel> _profiles = [];
  ProfileModel? _selectedProfile;

  List<ProfileModel> get profiles => _profiles;
  ProfileModel? get selectedProfile => _selectedProfile;

  Future<void> init() async {
    _box = await Hive.openBox<ProfileModel>(boxName);
    setProfiles();
    if (_profiles.isNotEmpty) {
      _selectedProfile = _profiles.first;
    }

    notifyListeners();
  }

  Future<void> createProfile(
    String name,
    String password,
    String question,
    String answer,
  ) async {
    final id = Uuid().v4();
    final profile = ProfileModel(
      id: id,
      name: name,
      password: password.isEmpty ? null : password,
      securityQuestion: question.isEmpty ? null : question,
      securityAnswer: answer.isEmpty ? null : answer,
    );
    await _box.put(id, profile);
    setProfiles();
    notifyListeners();
  }

  void setProfiles() {
    _profiles = _box.values.toList();
  }

  Future<void> selectProfile(ProfileModel profile) async {
    final freshProfile = _box.get(profile.id);
    _selectedProfile = freshProfile;
    notifyListeners();
  }

  Future<void> deleteProfile(String id) async {
    await _box.delete(id);
    setProfiles();
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

  Future<void> setProfilePassword(String profileId, String password) async {
    final profile = _profiles.firstWhere((p) => p.id == profileId);
    final updatedProfile = profile.copyWith(password: password);
    await _box.put(updatedProfile.id, updatedProfile);
    _profiles[_profiles.indexWhere((p) => p.id == profileId)] = updatedProfile;

    if (_selectedProfile?.id == profileId) {
      _selectedProfile = _box.get(updatedProfile.id);
    }
    notifyListeners();
  }
}
