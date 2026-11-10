import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/match_stream_model.dart';

abstract class MatchStreamRepository {
  /// Real-time snapshot listener stream for match stream config.
  Stream<MatchStreamModel?> listenToMatchStream(int matchId);

  /// One-time fetch for match stream config.
  Future<MatchStreamModel?> getMatchStreamOnce(int matchId);
}

class FirestoreMatchStreamRepository implements MatchStreamRepository {
  final FirebaseFirestore? _explicitFirestore;
  final FirebaseAuth? _explicitAuth;

  FirestoreMatchStreamRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _explicitFirestore = firestore,
        _explicitAuth = auth;

  FirebaseFirestore? get _firestore {
    if (_explicitFirestore != null) return _explicitFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseAuth? get _auth {
    if (_explicitAuth != null) return _explicitAuth;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureAuth() async {
    final auth = _auth;
    if (auth != null && auth.currentUser == null) {
      try {
        await auth.signInAnonymously();
        debugPrint('[MatchStreamRepo] Anonymous sign-in established: ${auth.currentUser?.uid}');
      } catch (e) {
        debugPrint('[MatchStreamRepo] Anonymous sign-in notice: $e');
      }
    }
  }

  @override
  Stream<MatchStreamModel?> listenToMatchStream(int matchId) async* {
    try {
      final fs = _firestore;
      if (fs == null) {
        debugPrint('[MatchStreamRepo] Firestore unavailable.');
        yield null;
        return;
      }

      await _ensureAuth();

      yield* fs
          .collection('match_streams')
          .doc(matchId.toString())
          .snapshots()
          .map((docSnap) {
            if (!docSnap.exists || docSnap.data() == null) {
              return null;
            }
            return MatchStreamModel.fromMap(docSnap.data()!, matchId);
          })
          .handleError((error) {
            debugPrint('[MatchStreamRepo] Snapshot error for match $matchId: $error');
            return null;
          });
    } catch (e) {
      debugPrint('[MatchStreamRepo] Exception setting up stream listener: $e');
      yield null;
    }
  }

  @override
  Future<MatchStreamModel?> getMatchStreamOnce(int matchId) async {
    try {
      await _ensureAuth();
      final fs = _firestore;
      if (fs == null) return null;

      final docSnap = await fs
          .collection('match_streams')
          .doc(matchId.toString())
          .get(const GetOptions(source: Source.serverAndCache));

      if (!docSnap.exists || docSnap.data() == null) {
        return null;
      }
      return MatchStreamModel.fromMap(docSnap.data()!, matchId);
    } on FirebaseException catch (fe) {
      if (fe.code == 'permission-denied') {
        debugPrint('[MatchStreamRepo] 🔒 PERMISSION DENIED fetching match_streams/$matchId.');
      } else {
        debugPrint('[MatchStreamRepo] FirebaseException fetching match stream: $fe');
      }
      return null;
    } catch (e) {
      debugPrint('[MatchStreamRepo] Error fetching match stream once: $e');
      return null;
    }
  }
}
