import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stream issue options supported by the dashboard and client.
enum StreamIssueType {
  buffering,
  offline,
  wrongMatch,
  noAudio,
  badQuality;

  String get key {
    switch (this) {
      case StreamIssueType.buffering:
        return 'buffering';
      case StreamIssueType.offline:
        return 'offline';
      case StreamIssueType.wrongMatch:
        return 'wrong_match';
      case StreamIssueType.noAudio:
        return 'no_audio';
      case StreamIssueType.badQuality:
        return 'bad_quality';
    }
  }

  String get arabicLabel {
    switch (this) {
      case StreamIssueType.buffering:
        return 'تقطيع مستمر وبطء في البث';
      case StreamIssueType.offline:
        return 'البث متوقف تماماً عن العمل';
      case StreamIssueType.wrongMatch:
        return 'مباراة أخرى غير المحددة';
      case StreamIssueType.noAudio:
        return 'الصوت لا يعمل أو غير متطابق';
      case StreamIssueType.badQuality:
        return 'جودة الصورة ضعيفة جداً';
    }
  }
}

/// Service handling stream issue reporting in private streaming builds.
class StreamReportService {
  final FirebaseFirestore? _explicitFirestore;
  final FirebaseAuth? _explicitAuth;

  StreamReportService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _explicitFirestore = firestore,
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

  /// Submits an issue report for a specific match stream server.
  /// Throws user-friendly Arabic exception on duplicate submission or failure.
  Future<void> submitReport({
    required dynamic matchId,
    required String matchTitle,
    required String serverId,
    required String serverName,
    required StreamIssueType issueType,
    String userComment = '',
  }) async {
    final auth = _auth;
    User? currentUser = auth?.currentUser;

    // Ensure user is signed in
    if (currentUser == null && auth != null) {
      try {
        final cred = await auth.signInAnonymously();
        currentUser = cred.user;
      } catch (e) {
        debugPrint('[StreamReportService] Anonymous sign-in failed: $e');
        throw Exception('يجب الاتصال بحساب مستخدم لإرسال الإبلاغ');
      }
    }

    if (currentUser == null) {
      throw Exception('تعذر التحقق من هوية المستخدم');
    }

    final uid = currentUser.uid;
    final matchIdStr = matchId.toString().trim();
    final issueKey = issueType.key;
    final reportDocId = '${uid}_${matchIdStr}_$issueKey';

    final fs = _firestore;
    if (fs == null) {
      throw Exception('خدمة الإبلاغات غير متاحة حالياً');
    }

    final docRef = fs.collection('stream_reports').doc(reportDocId);

    try {
      await docRef.set({
        'match_id': int.tryParse(matchIdStr) ?? matchIdStr,
        'match_title': matchTitle.length > 150 ? matchTitle.substring(0, 150) : matchTitle,
        'server_id': serverId.length > 50 ? serverId.substring(0, 50) : serverId,
        'server_name': serverName.length > 100 ? serverName.substring(0, 100) : serverName,
        'issue_type': issueKey,
        'user_comment': userComment.length > 250 ? userComment.substring(0, 250) : userComment,
        'status': 'pending',
        'user_id': uid,
        'created_at': FieldValue.serverTimestamp(),
      });
      debugPrint('[StreamReportService] Successfully submitted report $reportDocId');
    } on FirebaseException catch (fe) {
      debugPrint('[StreamReportService] Firebase error ${fe.code}: ${fe.message}');
      if (fe.code == 'permission-denied' || fe.code == 'already-exists') {
        throw Exception('تم الإبلاغ عن هذه المشكلة مسبقًا');
      }
      throw Exception('فشل إرسال البلاغ، يرجى المحاولة لاحقاً');
    } catch (e) {
      debugPrint('[StreamReportService] Unexpected error: $e');
      throw Exception('فشل إرسال البلاغ، يرجى المحاولة لاحقاً');
    }
  }
}

final streamReportServiceProvider = Provider<StreamReportService>((ref) {
  return StreamReportService();
});

