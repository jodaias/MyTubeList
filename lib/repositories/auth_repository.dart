import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/profile_model.dart';

class AuthRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');

  auth.User? get currentUser => _auth.currentUser;

  Future<bool> signInWithUsername(String username, String password) async {
    try {
      final profile = await getProfileByUsername(username);
      if (profile == null) return false;

      final email = profile.email ?? '$username@mytubelist.com';

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential.user != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> createUserWithPassword(
      String username, String password, String name,
      {UserCategory? category}) async {
    try {
      if (!_isValidUsername(username)) {
        throw Exception(
            'Nome de usuário inválido. Use apenas letras, números e underscore.');
      }

      try {
        await _auth.signInWithEmailAndPassword(
          email: '$username@mytubelist.com',
          password: password,
        );
        await _auth.signOut();
        throw Exception('Nome de usuário já existe.');
      } catch (e) {
        // Expected for new users
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: '$username@mytubelist.com',
        password: password,
      );

      if (userCredential.user == null) return false;

      final profile = ProfileModel(
        id: username,
        name: name,
        username: username,
        category: category,
        email: '$username@mytubelist.com',
      );

      await _usersCollection.doc(userCredential.user!.uid).set({
        'profile': {
          'id': profile.id,
          'name': profile.name,
          'username': username,
          'category': category?.firebaseValue,
          'email': profile.email,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }
      });

      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> deleteCurrentUser() async {
    final user = currentUser;
    if (user != null) {
      await _usersCollection.doc(user.uid).delete();
      await user.delete();
    }
  }

  Future<bool> updateEmail(String newEmail) async {
    try {
      final user = currentUser;
      if (user == null) return false;
      if (!_isValidEmail(newEmail)) return false;

      await user.verifyBeforeUpdateEmail(newEmail);

      await _usersCollection.doc(user.uid).update({
        'profile.email': newEmail,
        'profile.updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final credential = auth.EmailAuthProvider.credential(
        email: user.email ?? '',
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      return false;
    }
  }

  bool isEmailVerified() {
    return currentUser?.emailVerified ?? false;
  }

  Future<bool> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user == null) return false;
      await user.sendEmailVerification();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> reloadUser() async {
    try {
      await currentUser?.reload();
    } catch (e) {
      // Silently handle
    }
  }

  // Profile methods
  Future<void> createProfile(ProfileModel profile) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    await _usersCollection.doc(user.uid).set({
      'profile': {
        'id': profile.id,
        'name': profile.name,
        'username': profile.username,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }
    });
  }

  Future<ProfileModel?> getProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final doc = await _usersCollection.doc(user.uid).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      final profileData = data['profile'] as Map<String, dynamic>;

      return ProfileModel(
        id: profileData['id'],
        name: profileData['name'],
        username: profileData['username'],
        category: ProfileModel.parseCategory(profileData['category']),
        email: profileData['email'],
      );
    } catch (e) {
      return null;
    }
  }

  Future<ProfileModel?> getProfileByUsername(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('profile.username', isEqualTo: username)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final data = querySnapshot.docs.first.data();
      final profileData = data['profile'] as Map<String, dynamic>;

      return ProfileModel(
        id: profileData['id'],
        name: profileData['name'],
        username: profileData['username'],
        category: ProfileModel.parseCategory(profileData['category']),
        email: profileData['email'],
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> syncProfileWithFirebase(ProfileModel profile) async {
    var existingProfile = await getProfileByUsername(profile.username);
    if (existingProfile == null) {
      existingProfile = await getProfile();
    }
    if (existingProfile == null) {
      await createProfile(profile);
    }
  }

  bool _isValidUsername(String username) {
    final regex = RegExp(r'^[a-zA-Z0-9_]+$');
    return regex.hasMatch(username) &&
        username.length >= 3 &&
        username.length <= 20;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
