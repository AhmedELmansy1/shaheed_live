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

/// Diagnostics holder for the last match poll voting attempt.
///
/// Strictly stores only URL path, HTTP status, timestamp, error classification,
/// and success flag. Auth tokens, user IDs, and PII are strictly prohibited.
class PollVoteDiagnostics {
  static final PollVoteDiagnostics instance = PollVoteDiagnostics._();
  PollVoteDiagnostics._();

  DateTime? lastAttemptTime;
  String? urlPath;
  int? statusCode;
  String? errorClass;
  bool? isSuccess;

  void record({
    required String path,
    int? status,
    String? error,
    required bool success,
  }) {
    lastAttemptTime = DateTime.now();
    urlPath = path;
    statusCode = status;
    errorClass = error;
    isSuccess = success;
  }
}

/// Base typed exception for poll voting operations.
abstract class PollVoteException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorClass;

  const PollVoteException(this.message, {this.statusCode, this.errorClass});

  @override
  String toString() => message;
}

class PollAlreadyVotedException extends PollVoteException {
  const PollAlreadyVotedException([super.message = 'تم تسجيل تصويتك في هذا الاستطلاع مسبقاً'])
      : super(statusCode: 409, errorClass: 'ALREADY_VOTED');
}

class PollRateLimitedException extends PollVoteException {
  const PollRateLimitedException([super.message = 'حاول بعد قليل'])
      : super(statusCode: 429, errorClass: 'RATE_LIMITED');
}

class PollUnauthorizedException extends PollVoteException {
  const PollUnauthorizedException([super.message = 'يجب تسجيل الدخول للمشاركة في التصويت'])
      : super(statusCode: 401, errorClass: 'UNAUTHORIZED');
}

class PollServerException extends PollVoteException {
  const PollServerException([super.message = 'تعذّر تسجيل صوتك، حاول مرة أخرى', int? statusCode])
      : super(statusCode: statusCode, errorClass: 'SERVER_ERROR');
}

class PollNetworkException extends PollVoteException {
  const PollNetworkException([super.message = 'تعذّر تسجيل صوتك، تحقق من اتصالك بالإنترنت'])
      : super(statusCode: null, errorClass: 'NETWORK_ERROR');
}

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
  ///
  /// Strictly shows a poll ONLY if `match_polls/{matchId}` exists, has non-empty
  /// options, and `enabled == true`. Never falls back to synthesized fake options.
  Stream<PollModel?> streamPoll(String matchId) {
    if (EnvConfig.isDemoMode) {
      return Stream.value(null);
    }

    final fs = _firestore;
    if (fs == null) return Stream.value(null);

    return fs.collection('match_polls').doc(matchId).snapshots().asyncMap((snap) async {
      if (!snap.exists || snap.data() == null) return null;
      final data = snap.data()!;
      final isEnabled = data['enabled'] == true || data['enabled'] == 1;
      if (!isEnabled) return null;

      final poll = PollModel.fromMap(data, matchId);
      if (poll.options.isEmpty || !poll.enabled) return null;

      // Check user vote receipt: subcollection match_polls/{matchId}/votes/{uid} or cached vote
      String? votedOption = await getCachedVote(matchId);
      final currentUid = _auth?.currentUser?.uid;
      if (currentUid != null) {
        try {
          final receiptDoc = await fs
              .collection('match_polls')
              .doc(matchId)
              .collection('votes')
              .doc(currentUid)
              .get();
          if (receiptDoc.exists && receiptDoc.data() != null) {
            final receipt = receiptDoc.data()!;
            votedOption = receipt['option_id']?.toString() ??
                receipt['optionId']?.toString() ??
                votedOption;
          }
        } catch (_) {}
      }

      return poll.copyWith(userVotedOptionId: votedOption);
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
  ///
  /// Guarantees:
  /// - `Accept: application/json` header.
  /// - Defensive response body decoding that prevents type errors on HTML/text pages.
  /// - Status code mapping: 200 -> success; 409 -> ALREADY_VOTED; 401 -> token refresh & retry;
  ///   429 -> RATE_LIMITED; 5xx/network -> SERVER_ERROR/NETWORK_ERROR.
  /// - Diagnostic tracking without tokens or PII.
  Future<PollModel> vote({
    required String matchId,
    required String optionId,
  }) async {
    final url = '${EnvConfig.dashboardBaseUrl}/api/polls/vote';
    final parsedUri = Uri.tryParse(url);
    final diagnosticsPath = parsedUri != null && parsedUri.path.isNotEmpty ? parsedUri.path : '/api/polls/vote';

    // 1. Handle Demo Mode locally
    if (EnvConfig.isDemoMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localReceiptKey(matchId), optionId);

      PollVoteDiagnostics.instance.record(
        path: diagnosticsPath,
        status: 200,
        error: null,
        success: true,
      );

      return PollModel(
        matchId: matchId,
        question: '',
        options: [PollOption(id: optionId, label: '', votes: 1)],
        totalVotes: 1,
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
        PollVoteDiagnostics.instance.record(
          path: diagnosticsPath,
          status: 401,
          error: 'AUTH_SIGNIN_FAILED',
          success: false,
        );
        throw const PollUnauthorizedException('يجب تسجيل الدخول أو الاتصال بالإنترنت للمشاركة في التصويت');
      }
    }

    String? idToken;
    try {
      idToken = await currentUser?.getIdToken();
    } catch (_) {}

    final payload = {
      'match_id': matchId,
      'option_id': optionId,
    };

    Map<String, String> buildHeaders(String? token) => {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    Response response;
    try {
      response = await _dio.post(
        url,
        data: payload,
        options: Options(
          headers: buildHeaders(idToken),
          responseType: ResponseType.plain,
          validateStatus: (status) => true,
        ),
      );
    } catch (netErr) {
      debugPrint('[PollService] Network error posting vote: $netErr');
      PollVoteDiagnostics.instance.record(
        path: diagnosticsPath,
        status: null,
        error: 'NETWORK_ERROR',
        success: false,
      );
      throw const PollNetworkException('تعذّر تسجيل صوتك، تحقق من اتصالك بالإنترنت');
    }

    // 3. Handle 401 with Single Token Refresh & Retry
    if (response.statusCode == 401 && currentUser != null) {
      try {
        idToken = await currentUser.getIdToken(true);
        response = await _dio.post(
          url,
          data: payload,
          options: Options(
            headers: buildHeaders(idToken),
            responseType: ResponseType.plain,
            validateStatus: (status) => true,
          ),
        );
      } catch (_) {
        // If retry fails at network level, continue to response evaluation
      }
    }

    // 4. Safely parse response body (handles HTML, text, and JSON without throwing TypeError)
    Map<String, dynamic>? decodedMap;
    final rawData = response.data;
    if (rawData is Map) {
      decodedMap = Map<String, dynamic>.from(rawData);
    } else if (rawData is String) {
      final trimmed = rawData.trim();
      if (trimmed.startsWith('{')) {
        try {
          final parsed = jsonDecode(trimmed);
          if (parsed is Map) {
            decodedMap = Map<String, dynamic>.from(parsed);
          }
        } catch (_) {
          decodedMap = null;
        }
      }
    }

    final int status = response.statusCode ?? 500;
    final String? serverError = decodedMap?['error']?.toString();

    // 5. Evaluate Status Code
    if (status == 200 && decodedMap != null) {
      final rawPoll = decodedMap['poll'];
      if (rawPoll is Map) {
        // Persist local receipt on verified server success
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_localReceiptKey(matchId), optionId);

        PollVoteDiagnostics.instance.record(
          path: diagnosticsPath,
          status: 200,
          error: null,
          success: true,
        );

        final pollData = Map<String, dynamic>.from(rawPoll);
        return PollModel.fromMap(pollData, matchId, userVotedOptionId: optionId);
      }
    }

    if (status == 409) {
      // Server confirmed user has already voted
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localReceiptKey(matchId), optionId);

      PollVoteDiagnostics.instance.record(
        path: diagnosticsPath,
        status: 409,
        error: 'ALREADY_VOTED',
        success: false,
      );
      throw PollAlreadyVotedException(serverError ?? 'تم تسجيل تصويتك في هذا الاستطلاع مسبقاً');
    }

    if (status == 401) {
      PollVoteDiagnostics.instance.record(
        path: diagnosticsPath,
        status: 401,
        error: 'UNAUTHORIZED',
        success: false,
      );
      throw PollUnauthorizedException(serverError ?? 'يجب تسجيل الدخول للمشاركة في التصويت');
    }

    if (status == 429) {
      PollVoteDiagnostics.instance.record(
        path: diagnosticsPath,
        status: 429,
        error: 'RATE_LIMITED',
        success: false,
      );
      throw PollRateLimitedException(serverError ?? 'حاول بعد قليل');
    }

    // 5xx or unhandled status
    PollVoteDiagnostics.instance.record(
      path: diagnosticsPath,
      status: status,
      error: 'SERVER_ERROR',
      success: false,
    );
    throw PollServerException(
      serverError ?? 'تعذّر تسجيل صوتك، حاول مرة أخرى',
      status,
    );
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
