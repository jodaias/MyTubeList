import 'package:get_it/get_it.dart';
import '../services/firebase_service.dart';
import '../services/biometric_service.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<FirebaseService>(() => FirebaseService());
  getIt.registerLazySingleton<BiometricService>(() => BiometricService());
}
