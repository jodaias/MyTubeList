import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../services/firebase_service.dart';

class FirebaseProfileProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  ProfileModel? _currentProfile;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  ProfileModel? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  FirebaseProfileProvider() {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Verificar se está autenticado
      _isAuthenticated = _firebaseService.currentUser != null;

      if (_isAuthenticated) {
        // Carregar perfil do Firebase
        _currentProfile = await _firebaseService.getProfile();
      }
    } catch (e) {
      // Silently handle initialization errors
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔍 Verificar status de autenticação
  Future<void> checkAuthStatus() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Verificar se está autenticado
      _isAuthenticated = _firebaseService.currentUser != null;

      if (_isAuthenticated) {
        // Carregar perfil atual
        _currentProfile = await _firebaseService.getProfile();
      }
    } catch (e) {
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔐 Fazer login com username e senha
  Future<bool> signInWithUsername(String username, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final success =
          await _firebaseService.signInWithUsername(username, password);
      _isAuthenticated = success;

      if (_isAuthenticated) {
        // Carregar perfil após login
        _currentProfile = await _firebaseService.getProfile();
      }

      return _isAuthenticated;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 👤 Criar novo usuário com senha
  Future<bool> createUserWithPassword(
      String username, String password, String name,
      {UserCategory? category}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await _firebaseService
          .createUserWithPassword(username, password, name, category: category);

      if (success) {
        _isAuthenticated = true;
        // Carregar perfil após criação
        _currentProfile = await _firebaseService.getProfile();
      }

      return success;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔍 Buscar perfil por username
  Future<ProfileModel?> getProfileByUsername(String username) async {
    try {
      return await _firebaseService.getProfileByUsername(username);
    } catch (e) {
      return null;
    }
  }

  /// 🔍 Verificar se username já existe
  Future<bool> checkUsernameExists(String username) async {
    try {
      final profile = await _firebaseService.getProfileByUsername(username);
      return profile != null;
    } catch (e) {
      return false;
    }
  }

  /// 📋 Buscar todos os perfis do Firebase
  Future<List<ProfileModel>> getAllProfiles() async {
    try {
      return await _firebaseService.getAllProfiles();
    } catch (e) {
      return [];
    }
  }

  /// 🚪 Fazer logout
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firebaseService.signOut();
      _isAuthenticated = false;
      _currentProfile = null;
    } catch (e) {
      // Silently handle logout errors
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🗑️ Deletar usuário atual
  Future<void> deleteCurrentUser() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firebaseService.deleteCurrentUser();
      _isAuthenticated = false;
      _currentProfile = null;
    } catch (e) {
      // Silently handle delete errors
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔄 Sincronizar perfil com Firebase
  Future<bool> syncProfileWithFirebase(ProfileModel profile) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firebaseService.syncProfileWithFirebase(profile);
      _currentProfile = profile;

      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔄 Recarregar perfil
  Future<void> reloadProfile() async {
    try {
      _isLoading = true;
      notifyListeners();

      _currentProfile = await _firebaseService.getProfile();
    } catch (e) {
      // Silently handle reload errors
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 📧 Atualizar email para recuperação de senha
  Future<bool> updateEmail(String newEmail) async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await _firebaseService.updateEmail(newEmail);

      if (success) {
        // Recarregar perfil após atualização
        await reloadProfile();
      }

      return success;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔐 Alterar senha
  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    try {
      _isLoading = true;
      notifyListeners();

      final success =
          await _firebaseService.changePassword(currentPassword, newPassword);

      return success;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 📧 Enviar email de recuperação de senha
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await _firebaseService.sendPasswordResetEmail(email);

      return success;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
