import 'package:flutter/material.dart';
import '../models/profile_model.dart';
import '../services/firebase_service.dart';
import '../di/service_locator.dart';
import '../utils/retry.dart';

class FirebaseProfileProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = getIt<FirebaseService>();

  ProfileModel? _currentProfile;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;

  ProfileModel? get currentProfile => _currentProfile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

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
        _currentProfile = await retryWithBackoff(
          () => _firebaseService.getProfile(),
        );
      }
    } catch (e) {
      _errorMessage = 'Erro ao inicializar perfil.';
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

      _isAuthenticated = _firebaseService.currentUser != null;

      if (_isAuthenticated) {
        _currentProfile = await retryWithBackoff(
          () => _firebaseService.getProfile(),
        );
      }
    } catch (e) {
      _isAuthenticated = false;
      _errorMessage = 'Erro ao verificar autenticação.';
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
      _errorMessage = 'Falha no login. Verifique suas credenciais.';
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
      _errorMessage = 'Erro ao criar usuário.';
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

  /// 🚪 Fazer logout
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firebaseService.signOut();
      _isAuthenticated = false;
      _currentProfile = null;
    } catch (e) {
      _errorMessage = 'Erro ao fazer logout.';
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
      _errorMessage = 'Erro ao excluir usuário.';
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
      _errorMessage = 'Erro ao sincronizar perfil.';
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
      _errorMessage = 'Erro ao recarregar perfil.';
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
      _errorMessage = 'Erro ao atualizar email.';
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
      _errorMessage = 'Erro ao alterar senha.';
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
      _errorMessage = 'Erro ao enviar email de recuperação.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 📧 Verificar se o email está verificado
  bool isEmailVerified() {
    return _firebaseService.isEmailVerified();
  }

  /// 📧 Enviar email de verificação
  Future<bool> sendEmailVerification() async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await _firebaseService.sendEmailVerification();

      return success;
    } catch (e) {
      _errorMessage = 'Erro ao enviar verificação de email.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔄 Recarregar dados do usuário (para atualizar status de verificação)
  Future<void> reloadUser() async {
    try {
      await _firebaseService.reloadUser();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao recarregar dados do usuário.';
    }
  }
}
