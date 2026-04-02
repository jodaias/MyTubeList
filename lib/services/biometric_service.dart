import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _biometricEnabledPrefix = 'biometric_enabled_';
  static const String _usernamePrefix = 'bio_username_';
  static const String _passwordPrefix = 'bio_password_';

  /// Verifica se o dispositivo suporta biometria
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Retorna os tipos de biometria disponíveis
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Autentica o usuário com biometria
  Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Use sua biometria para entrar',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  /// Salva as credenciais para login biométrico
  Future<void> saveCredentials(
      String profileId, String username, String password) async {
    await _secureStorage.write(
        key: '$_usernamePrefix$profileId', value: username);
    await _secureStorage.write(
        key: '$_passwordPrefix$profileId', value: password);
    await _secureStorage.write(
        key: '$_biometricEnabledPrefix$profileId', value: 'true');
  }

  /// Verifica se biometria está habilitada para um perfil
  Future<bool> isBiometricEnabledForProfile(String profileId) async {
    final value =
        await _secureStorage.read(key: '$_biometricEnabledPrefix$profileId');
    return value == 'true';
  }

  /// Recupera as credenciais salvas
  Future<Map<String, String>?> getCredentials(String profileId) async {
    final username =
        await _secureStorage.read(key: '$_usernamePrefix$profileId');
    final password =
        await _secureStorage.read(key: '$_passwordPrefix$profileId');

    if (username != null && password != null) {
      return {'username': username, 'password': password};
    }
    return null;
  }

  /// Remove credenciais biométricas de um perfil
  Future<void> removeCredentials(String profileId) async {
    await _secureStorage.delete(key: '$_usernamePrefix$profileId');
    await _secureStorage.delete(key: '$_passwordPrefix$profileId');
    await _secureStorage.delete(key: '$_biometricEnabledPrefix$profileId');
  }

  /// Desabilita biometria para um perfil
  Future<void> disableBiometric(String profileId) async {
    await removeCredentials(profileId);
  }
}
