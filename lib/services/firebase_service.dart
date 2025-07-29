import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/profile_model.dart';
import '../models/video_list_model.dart';
import '../models/video_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  // Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference _userVideoListsCollection(String userId) =>
      _usersCollection.doc(userId).collection('videoLists');
  CollectionReference _userSearchHistoryCollection(String userId) =>
      _usersCollection.doc(userId).collection('searchHistory');

  // 🔐 Autenticação usando apenas Firebase Auth (SEM armazenar senhas no Firestore)
  Future<bool> signInWithUsername(String username, String password) async {
    try {
      // Buscar perfil no Firestore para verificar se o usuário existe
      final profile = await getProfileByUsername(username);
      if (profile == null) {
        return false;
      }

      // Tentar fazer login no Firebase Auth usando email temporário
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: '$username@mytubelist.com',
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
      // Validar username (sem espaços, acentos, etc.)
      if (!_isValidUsername(username)) {
        throw Exception(
            'Nome de usuário inválido. Use apenas letras, números e underscore.');
      }

      // Verificar se usuário já existe no Firebase Auth
      try {
        await _auth.signInWithEmailAndPassword(
          email: '$username@mytubelist.com',
          password: password,
        );
        // Se conseguiu fazer login, o usuário já existe
        await _auth.signOut();
        throw Exception('Nome de usuário já existe.');
      } catch (e) {
        // Se não conseguiu fazer login, pode ser que o usuário não exista
        // ou a senha esteja errada (o que é esperado para novo usuário)
      }

      // Criar usuário no Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: '$username@mytubelist.com', // Email temporário
        password: password,
      );

      if (userCredential.user == null) {
        return false;
      }

      // Criar perfil NO Firestore SEM a senha
      final profile = ProfileModel(
        id: username, // Usar username como ID para consistência
        name: name,
        username: username,
        category: category,
      );

      await _usersCollection.doc(userCredential.user!.uid).set({
        'profile': {
          'id': profile.id,
          'name': profile.name,
          'username': username,
          'category': category?.firebaseValue,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }
      });

      return true;
    } catch (e) {
      rethrow;
    }
  }

  bool _isValidUsername(String username) {
    // Apenas letras, números e underscore, sem espaços
    final regex = RegExp(r'^[a-zA-Z0-9_]+$');
    return regex.hasMatch(username) &&
        username.length >= 3 &&
        username.length <= 20;
  }

  /// Converte string do Firebase para enum UserCategory
  UserCategory? _parseCategory(String? categoryString) {
    return ProfileModel.parseCategory(categoryString);
  }

  Future<ProfileModel?> getProfileByUsername(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('profile.username',
              isEqualTo: username) // Revertido: buscar dentro do profile
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();

      final profileData = data['profile'] as Map<String, dynamic>;

      return ProfileModel(
        id: profileData['id'],
        name: profileData['name'],
        username: profileData['username'],
        category: _parseCategory(profileData['category']),
      );
    } catch (e) {
      return null;
    }
  }

  /// 📋 Buscar todos os perfis do Firebase
  Future<List<ProfileModel>> getAllProfiles() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();

      final profiles = <ProfileModel>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        if (data.containsKey('profile')) {
          final profileData = data['profile'] as Map<String, dynamic>;

          profiles.add(ProfileModel(
            id: profileData['id'],
            name: profileData['name'],
            username: profileData['username'],
            category: _parseCategory(profileData['category']),
          ));
        }
      }

      return profiles;
    } catch (e) {
      return [];
    }
  }

  /// 🚪 Fazer logout
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// 🗑️ Deletar usuário atual
  Future<void> deleteCurrentUser() async {
    try {
      final user = currentUser;
      if (user != null) {
        // Deletar dados do Firestore
        await _usersCollection.doc(user.uid).delete();

        // Deletar usuário do Firebase Auth
        await user.delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  auth.User? get currentUser => _auth.currentUser;

  // 👤 Perfil do usuário
  Future<void> createProfile(ProfileModel profile) async {
    try {
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
    } catch (e) {
      rethrow;
    }
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
      );
    } catch (e) {
      return null;
    }
  }

  // 📋 Listas de vídeos
  Future<void> createVideoList(VideoListModel videoList) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      await _userVideoListsCollection(user.uid).doc(videoList.id).set({
        'id': videoList.id,
        'name': videoList.name,
        'profileId': videoList.profileId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'videos': videoList.videos
            .map((video) => {
                  'id': video.id,
                  'title': video.title,
                  'thumbnailUrl': video.thumbnailUrl,
                  'addedAt': DateTime.now()
                      .toIso8601String(), // Corrigido: usar DateTime.now()
                })
            .toList(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<VideoListModel>> getVideoLists() async {
    try {
      final user = currentUser;
      if (user == null) return [];

      final querySnapshot = await _userVideoListsCollection(user.uid).get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return VideoListModel(
          id: data['id'],
          name: data['name'],
          profileId: data['profileId'],
          videos: (data['videos'] as List<dynamic>? ?? []).map((videoData) {
            return VideoModel(
              id: videoData['id'],
              title: videoData['title'],
              thumbnailUrl: videoData['thumbnailUrl'],
            );
          }).toList(),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> updateVideoList(VideoListModel videoList) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      await _userVideoListsCollection(user.uid).doc(videoList.id).update({
        'name': videoList.name,
        'updatedAt': FieldValue.serverTimestamp(),
        'videos': videoList.videos
            .map((video) => {
                  'id': video.id,
                  'title': video.title,
                  'thumbnailUrl': video.thumbnailUrl,
                  'addedAt': DateTime.now()
                      .toIso8601String(), // Corrigido: usar DateTime.now()
                })
            .toList(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteVideoList(String listId) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      await _userVideoListsCollection(user.uid).doc(listId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // 🔍 Histórico de buscas
  Future<void> addSearchTerm(String term, String profileId) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      // Verificar se o termo já existe para este perfil
      final existingQuery = await _userSearchHistoryCollection(user.uid)
          .where('term', isEqualTo: term)
          .where('profileId', isEqualTo: profileId)
          .limit(1)
          .get();

      // Só adicionar se não existir
      if (existingQuery.docs.isEmpty) {
        await _userSearchHistoryCollection(user.uid).add({
          'term': term,
          'profileId': profileId,
          'searchedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> getSearchHistory(String profileId) async {
    try {
      final user = currentUser;
      if (user == null) return [];

      final querySnapshot = await _userSearchHistoryCollection(user.uid)
          .where('profileId', isEqualTo: profileId)
          .orderBy('searchedAt', descending: true)
          .limit(20)
          .get();

      // Usar Set para garantir termos únicos
      final Set<String> uniqueTerms = {};
      final List<String> orderedTerms = [];

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final term = data['term'] as String;

        // Adicionar apenas se não existir (mantém ordem)
        if (!uniqueTerms.contains(term)) {
          uniqueTerms.add(term);
          orderedTerms.add(term);
        }
      }

      return orderedTerms;
    } catch (e) {
      return [];
    }
  }

  // 🔄 Sincronização
  Future<void> syncProfileWithFirebase(ProfileModel profile) async {
    try {
      // Verificar se o perfil já existe pelo username
      var existingProfile = await getProfileByUsername(profile.username);

      // Se não encontrou pelo username, verificar pelo perfil atual
      if (existingProfile == null) {
        existingProfile = await getProfile();
      }

      if (existingProfile == null) {
        await createProfile(profile);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> syncVideoListsWithFirebase(
      List<VideoListModel> videoLists) async {
    try {
      final user = currentUser;
      if (user == null) {
        try {
          final credential = await _auth.signInAnonymously();
          if (credential.user == null) {
            return;
          }
        } catch (e) {
          return;
        }
      }

      for (final videoList in videoLists) {
        final existingLists = await getVideoLists();
        final existingList = existingLists.firstWhere(
          (list) => list.id == videoList.id,
          orElse: () => videoList,
        );

        if (existingList.id == videoList.id) {
          await updateVideoList(videoList);
        } else {
          await createVideoList(videoList);
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
