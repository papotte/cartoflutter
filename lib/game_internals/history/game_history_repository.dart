import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

import '../models/player_state.dart';

final _log = Logger('GameHistoryRepository');

/// Persists completed games under `users/{uid}/games/{gameId}`.
class GameHistoryRepository {
  GameHistoryRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> saveGame(GameRecord record) async {
    final user = _auth.currentUser;
    if (user == null) {
      _log.fine('No signed-in user; skip history save');
      return;
    }
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('games')
          .doc(record.id)
          .set(record.toJson());
      _log.fine('Saved game ${record.id}');
    } catch (e, st) {
      _log.warning('Failed to save game history', e, st);
    }
  }

  Stream<List<GameRecord>> listGames() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('games')
        .orderBy('playedAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => GameRecord.fromJson(d.data())).toList(),
        );
  }

  Future<GameRecord?> getGame(String id) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('games')
        .doc(id)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return GameRecord.fromJson(doc.data()!);
  }

  Future<void> deleteGame(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('games')
        .doc(id)
        .delete();
  }
}
