import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../constants/app_constants.dart';

class SearchRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  auth.User? get _currentUser => _auth.currentUser;

  CollectionReference get _usersCollection => _firestore.collection('users');

  CollectionReference _userSearchHistoryCollection(String userId) =>
      _usersCollection.doc(userId).collection('searchHistory');

  CollectionReference _userSearchHistoryTermsCollection(
          String userId, String profileId, String listId) =>
      _userSearchHistoryCollection(userId)
          .doc('${profileId}_$listId')
          .collection('terms');

  Future<void> addSearchTerm(
      String term, String profileId, String listId) async {
    final user = _currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    final normalizedTerm = term.trim();
    if (normalizedTerm.isEmpty) return;

    final termDocId = Uri.encodeComponent(normalizedTerm.toLowerCase());
    final termsCollection =
        _userSearchHistoryTermsCollection(user.uid, profileId, listId);

    await termsCollection.doc(termDocId).set({
      'term': normalizedTerm,
      'searchedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final recentSearches =
        await termsCollection.orderBy('searchedAt', descending: true).get();

    if (recentSearches.docs.length > AppConstants.maxSearchHistory) {
      final docsToDelete =
          recentSearches.docs.skip(AppConstants.maxSearchHistory);
      final batch = _firestore.batch();

      for (final doc in docsToDelete) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    }
  }

  Future<List<String>> getSearchHistory(String profileId, String listId) async {
    try {
      final user = _currentUser;
      if (user == null) return [];

      final querySnapshot =
          await _userSearchHistoryTermsCollection(user.uid, profileId, listId)
              .orderBy('searchedAt', descending: true)
              .limit(AppConstants.maxSearchHistory)
              .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['term'] as String;
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
