import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/profile_model.dart';

class LocalProfilesProvider extends ChangeNotifier {
  static const String _profilesBoxName = 'local_profiles';
  late Box<ProfileModel> _box;
  List<ProfileModel> _profiles = [];
  bool _isLoading = false;

  List<ProfileModel> get profiles => _profiles;
  bool get isLoading => _isLoading;

  LocalProfilesProvider() {
    _init();
  }

  Future<void> _init() async {
    _box = await Hive.openBox<ProfileModel>(_profilesBoxName);
    await loadProfiles();
  }

  /// 📋 Carregar perfis salvos localmente
  Future<void> loadProfiles() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Carregar perfis salvos localmente
      _profiles = _box.values.toList();
    } catch (e) {
      _profiles = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ➕ Adicionar novo perfil local
  Future<void> addProfile(ProfileModel profile) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_box.containsKey(profile.id)) return;

      // Adicionar perfil usando ID como chave
      await _box.put(profile.id, profile);

      // Recarregar lista
      await loadProfiles();
    } catch (e) {
      rethrow;
    }
  }

  /// 🗑️ Remover perfil local
  Future<void> removeProfile(String profileId) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (!_box.containsKey(profileId)) return;

      // Deletar perfil usando ID como chave
      await _box.delete(profileId);

      // Recarregar lista
      await loadProfiles();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🗑️ Limpar todos os perfis locais
  Future<void> clearAllProfiles() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Limpar todos os perfis
      await _box.clear();

      // Recarregar lista
      await loadProfiles();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔍 Buscar perfil por ID
  ProfileModel? getProfileById(String profileId) {
    try {
      return _profiles.firstWhere(
        (profile) => profile.id == profileId,
      );
    } catch (e) {
      return null;
    }
  }

  /// 🔍 Buscar perfil por username
  ProfileModel? getProfileByUsername(String username) {
    try {
      return _profiles.firstWhere(
        (profile) => profile.username == username,
      );
    } catch (e) {
      return null;
    }
  }
}
