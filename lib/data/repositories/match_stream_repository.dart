import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  FirestoreMatchStreamRepository({FirebaseFirestore? firestore})
      : _explicitFirestore = firestore;

  FirebaseFirestore? get _firestore {
    if (_explicitFirestore != null) return _explicitFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<MatchStreamModel?> listenToMatchStream(int matchId) {
    try {
      final fs = _firestore;
      if (fs == null) {
        debugPrint('[MatchStreamRepo] Firestore unavailable.');
        return Stream.value(null);
      }

      return fs
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
      debugPrint('[MatchStreamRepo] Failed to initialize stream for match $matchId: $e');
      return Stream.value(null);
    }
  }

  @override
  Future<MatchStreamModel?> getMatchStreamOnce(int matchId) async {
    try {
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
    } catch (e) {
      debugPrint('[MatchStreamRepo] Error fetching match stream once: $e');
      return null;
    }
  }
}
