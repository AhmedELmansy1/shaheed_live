import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/poll_model.dart';
import '../config/env_config.dart';

/// Service managing Match Poll real-time observations and atomic server-side voting.
class PollService {
  final FirebaseFirestore? _explicitFirestore;
  final FirebaseAuth? _explicitAuth;
  final Dio _dio;

  PollService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    Dio? dio,
  })  : _explicitFirestore = firestore,
        _explicitAuth = auth,
        _dio = dio ?? Dio();

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

  static String _localReceiptKey(String matchId) => 'poll_voted_option_$matchId';

  /// Returns locally cached vote option ID if user already voted in this session/device.
  Future<String?> getCachedVote(String matchId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_localReceiptKey(matchId));
    } catch (_) {
      return null;
    }
  }

  /// Listens to real-time updates for a single match poll from Firestore.
  Stream<PollModel?> streamPoll(String matchId) {
    if (EnvConfig.isDemoMode) {
      // Demo mock poll
      return Stream.value(
        PollModel(
          matchId: matchId,
          question: 'من تتوقع أن يفوز بمباراة اليوم؟',
          options: const [
            PollOption(id: 'opt_1', label: 'الفريق المستضيف', votes: 142),
            PollOption(id: 'opt_2', label: 'التعادل', votes: 45),
            PollOption(id: 'opt_3', label: 'الفريق الضيف', votes: 118),
          ],
          totalVotes: 305,
          enabled: true,
        ),
      );
    }

    final fs = _firestore;
    if (fs == null) return Stream.value(null);

    return fs.collection('match_polls').doc(matchId).snapshots().asyncMap((snap) async {
      if (!snap.exists || snap.data() == null) return null;
      final cachedVote = await getCachedVote(matchId);
      return PollModel.fromMap(snap.data()!, matchId, userVotedOptionId: cachedVote);
    }).handleError((err) {
      if (err is FirebaseException && err.code == 'permission-denied') {
        debugPrint('[PollService] 🔒 PERMISSION DENIED reading match_polls/$matchId. Firestore rules must allow read.');
      } else {
        debugPrint('[PollService] Stream error for match $matchId: $err');
      }
      return null;
    });
  }

  /// Casts a vote through the secure backend route `POST /api/polls/vote`.
  /// Guarantees token verification, atomic transaction, and local receipt persistence.
  Future<PollModel> vote({
    required String matchId,
    required String optionId,
  }) async {
    // 1. Handle Demo Mode locally
    if (EnvConfig.isDemoMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localReceiptKey(matchId), optionId);

      return PollModel(
        matchId: matchId,
        question: 'من تتوقع أن يفوز بمباراة اليوم؟',
        options: [
          PollOption(id: 'opt_1', label: 'الفريق المستضيف', votes: optionId == 'opt_1' ? 143 : 142),
          PollOption(id: 'opt_2', label: 'التعادل', votes: optionId == 'opt_2' ? 46 : 45),
          PollOption(id: 'opt_3', label: 'الفريق الضيف', votes: optionId == 'opt_3' ? 119 : 118),
        ],
        totalVotes: 306,
        enabled: true,
        userVotedOptionId: optionId,
      );
    }

    // 2. Ensure User is Authenticated (Auto anonymous sign-in if needed)
    final auth = _auth;
    User? currentUser = auth?.currentUser;
    if (currentUser == null && auth != null) {
      try {
        final credential = await auth.signInAnonymously();
        currentUser = credential.user;
      } catch (authErr) {
        debugPrint('[PollService] Anonymous sign-in failed: $authErr');
        throw Exception('يجب تسجيل الدخول أو الاتصال بالإنترنت للمشاركة في التصويت');
      }
    }

    if (currentUser == null) {
      throw Exception('تعذر الحصول على حساب مستخدم نشط');
    }

    final idToken = await currentUser.getIdToken();
    final url = '${EnvConfig.dashboardBaseUrl}/api/polls/vote';

    debugPrint('[PollService] Submitting vote to: $url for match: $matchId, opt: $optionId');

    Response response;
    try {
      response = await _dio.post(
        url,
        data: {
          'match_id': matchId,
          'option_id': optionId,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.json,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
    } catch (netErr) {
      debugPrint('[PollService] Network error posting vote: $netErr');
      throw Exception('تعذر الاتصال بخادم التصويت، يرجى التحقق من اتصالك بالإنترنت');
    }

    // Safely parse response data whether returned as Map, String, or dynamic
    dynamic responseBody = response.data;
    if (responseBody is String) {
      try {
        responseBody = jsonDecode(responseBody);
      } catch (_) {
        responseBody = null;
      }
    }

    if (response.statusCode == 200 && responseBody is Map) {
      // Save local receipt to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localReceiptKey(matchId), optionId);

      final rawPoll = responseBody['poll'];
      if (rawPoll is Map) {
        final pollData = Map<String, dynamic>.from(rawPoll);
        return PollModel.fromMap(pollData, matchId, userVotedOptionId: optionId);
      }
    }

    String errorMsg = 'حدث خطأ أثناء تسجيل التصويت (كود ${response.statusCode})';
    if (responseBody is Map && responseBody['error'] != null) {
      errorMsg = responseBody['error'].toString();
    } else if (response.statusCode == 409) {
      errorMsg = 'تم تسجيل تصويتك في هذا الاستطلاع مسبقاً';
    } else if (response.statusCode == 403) {
      errorMsg = 'هذا الاستطلاع مغلق حالياً';
    } else if (response.statusCode == 401) {
      errorMsg = 'يجب تسجيل الدخول للمشاركة في التصويت';
    }

    throw Exception(errorMsg);
  }
}

final pollServiceProvider = Provider<PollService>((ref) {
  return PollService();
});

/// Stream provider for a given match's live poll.
final matchPollStreamProvider = StreamProvider.family<PollModel?, String>((ref, matchId) {
  final service = ref.watch(pollServiceProvider);
  return service.streamPoll(matchId);
});

