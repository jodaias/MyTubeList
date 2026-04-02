import '../constants/app_constants.dart';

class InputValidators {
  InputValidators._();

  static final _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  static final _usernameRegex = RegExp(r'^[a-z0-9_]+$');
  static final _usernameLooseRegex = RegExp(r'^[a-zA-Z0-9_]+$');

  // ── Email ─────────────────────────────────────────────

  static bool isValidEmail(String email) => _emailRegex.hasMatch(email);

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Digite um email';
    if (!isValidEmail(value)) return 'Digite um email válido';
    return null;
  }

  // ── Username ──────────────────────────────────────────

  static bool isValidUsername(String username) {
    return _usernameLooseRegex.hasMatch(username) &&
        username.length >= AppConstants.usernameMinLength &&
        username.length <= AppConstants.usernameMaxLength;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) return 'Digite um nome de usuário';
    if (value.length < AppConstants.usernameMinLength) {
      return 'Nome de usuário deve ter pelo menos ${AppConstants.usernameMinLength} caracteres';
    }
    if (value.length > AppConstants.usernameMaxLength) {
      return 'O nome de usuário deve ter no máximo ${AppConstants.usernameMaxLength} caracteres';
    }
    if (!_usernameRegex.hasMatch(value)) {
      return 'Apenas letras minúsculas, números e underscore';
    }
    return null;
  }

  // ── Password ──────────────────────────────────────────

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Digite sua senha';
    if (value.length < AppConstants.passwordMinLength) {
      return 'A senha deve ter pelo menos ${AppConstants.passwordMinLength} caracteres';
    }
    if (value.length > AppConstants.passwordMaxLength) {
      return 'A senha deve ter no máximo ${AppConstants.passwordMaxLength} caracteres';
    }
    return null;
  }

  static String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) return 'Digite a nova senha';
    if (value.length < AppConstants.passwordMinLength) {
      return 'A senha deve ter pelo menos ${AppConstants.passwordMinLength} caracteres';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String newPassword) {
    if (value == null || value.isEmpty) return 'Confirme a nova senha';
    if (value != newPassword) return 'As senhas não coincidem';
    return null;
  }

  // ── Profile Name ──────────────────────────────────────

  static String? validateProfileName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Digite um nome para o perfil';
    }
    if (value.length < AppConstants.profileNameMinLength) {
      return 'O nome deve ter pelo menos ${AppConstants.profileNameMinLength} caracteres';
    }
    if (value.length > AppConstants.profileNameMaxLength) {
      return 'O nome deve ter no máximo ${AppConstants.profileNameMaxLength} caracteres';
    }
    return null;
  }

  // ── Input Cleaners ────────────────────────────────────

  static String cleanUsername(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'\s'), '')
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll(RegExp(r'[çÇ]'), 'c')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  static String cleanPassword(String value) {
    return value
        .replaceAll(RegExp(r'\s'), '')
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u');
  }

  static String cleanProfileName(String value) {
    return value
        .replaceAll(RegExp(r'[0-9]'), '')
        .replaceAll(RegExp(r"[^\p{L}\s']", unicode: true), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
