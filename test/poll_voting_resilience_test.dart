import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoot_live/core/services/poll_service.dart';
import 'package:shoot_live/data/models/poll_model.dart';

/// Fake Dio HTTP client adapter for mocking server responses deterministically.
class FakeDioAdapter implements HttpClientAdapter {
  int statusCode;
  String responseBody;
  Map<String, List<String>> headers;

  FakeDioAdapter({
    required this.statusCode,
    required this.responseBody,
    this.headers = const {
      'content-type': ['application/json'],
    },
  });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      responseBody,
      statusCode,
      headers: headers,
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PollService Resilience Tests - Strict Type and Body Mapping', () {
    test('(a) HTML 404 response maps to PollServerException without TypeError', () async {
      const htmlBody = '<!DOCTYPE html><html><head><title>404 Not Found</title></head><body><h1>404 Not Found</h1><p>The requested URL was not found.</p></body></html>';
      final dio = Dio();
      dio.httpClientAdapter = FakeDioAdapter(
        statusCode: 404,
        responseBody: htmlBody,
        headers: {
          'content-type': ['text/html; charset=utf-8'],
        },
      );

      final service = PollService(dio: dio);

      await expectLater(
        () => service.vote(matchId: 'match_404', optionId: 'opt_1'),
        throwsA(isA<PollServerException>().having(
          (e) => e.statusCode,
          'statusCode',
          404,
        )),
      );

      // Verify diagnostics
      expect(PollVoteDiagnostics.instance.statusCode, 404);
      expect(PollVoteDiagnostics.instance.errorClass, 'SERVER_ERROR');
      expect(PollVoteDiagnostics.instance.isSuccess, false);
    });

    test('(b) text/plain 500 response maps to PollServerException without TypeError', () async {
      const plainTextBody = 'Internal Server Error: Vercel function crashed or service unavailable.';
      final dio = Dio();
      dio.httpClientAdapter = FakeDioAdapter(
        statusCode: 500,
        responseBody: plainTextBody,
        headers: {
          'content-type': ['text/plain; charset=utf-8'],
        },
      );

      final service = PollService(dio: dio);

      await expectLater(
        () => service.vote(matchId: 'match_500', optionId: 'opt_1'),
        throwsA(isA<PollServerException>().having(
          (e) => e.statusCode,
          'statusCode',
          500,
        )),
      );

      expect(PollVoteDiagnostics.instance.statusCode, 500);
      expect(PollVoteDiagnostics.instance.errorClass, 'SERVER_ERROR');
    });

    test('(c) JSON 401 response maps to PollUnauthorizedException without TypeError', () async {
      const json401 = '{"error": "غير مصرح: يجب تسجيل الدخول وإرسال توكن المصادقة"}';
      final dio = Dio();
      dio.httpClientAdapter = FakeDioAdapter(
        statusCode: 401,
        responseBody: json401,
      );

      final service = PollService(dio: dio);

      await expectLater(
        () => service.vote(matchId: 'match_401', optionId: 'opt_1'),
        throwsA(isA<PollUnauthorizedException>().having(
          (e) => e.statusCode,
          'statusCode',
          401,
        )),
      );

      expect(PollVoteDiagnostics.instance.statusCode, 401);
      expect(PollVoteDiagnostics.instance.errorClass, 'UNAUTHORIZED');
    });

    test('(d) 409 {error: "ALREADY_VOTED"} maps to PollAlreadyVotedException without TypeError', () async {
      const json409 = '{"error": "تم تسجيل تصويتك في هذا الاستطلاع مسبقاً"}';
      final dio = Dio();
      dio.httpClientAdapter = FakeDioAdapter(
        statusCode: 409,
        responseBody: json409,
      );

      final service = PollService(dio: dio);

      await expectLater(
        () => service.vote(matchId: 'match_409', optionId: 'opt_1'),
        throwsA(isA<PollAlreadyVotedException>().having(
          (e) => e.statusCode,
          'statusCode',
          409,
        )),
      );

      expect(PollVoteDiagnostics.instance.statusCode, 409);
      expect(PollVoteDiagnostics.instance.errorClass, 'ALREADY_VOTED');
    });

    test('(e) 429 response maps to PollRateLimitedException without TypeError', () async {
      const json429 = '{"error": "تجاوزت الحد المسموح من الطلبات، يرجى المحاولة بعد قليل"}';
      final dio = Dio();
      dio.httpClientAdapter = FakeDioAdapter(
        statusCode: 429,
        responseBody: json429,
      );

      final service = PollService(dio: dio);

      await expectLater(
        () => service.vote(matchId: 'match_429', optionId: 'opt_1'),
        throwsA(isA<PollRateLimitedException>().having(
          (e) => e.statusCode,
          'statusCode',
          429,
        )),
      );

      expect(PollVoteDiagnostics.instance.statusCode, 429);
      expect(PollVoteDiagnostics.instance.errorClass, 'RATE_LIMITED');
    });

    test('(f) 200 with poll JSON maps successfully to PollModel without TypeError', () async {
      final json200 = jsonEncode({
        'success': true,
        'poll': {
          'match_id': 'match_200',
          'question': 'من تتوقع أن يفوز؟',
          'options': [
            {'id': 'opt_1', 'label': 'الأهلي', 'votes': 25},
            {'id': 'opt_2', 'label': 'الزمالك', 'votes': 15},
          ],
          'total_votes': 40,
          'enabled': true,
        },
      });

      final dio = Dio();
      dio.httpClientAdapter = FakeDioAdapter(
        statusCode: 200,
        responseBody: json200,
      );

      final service = PollService(dio: dio);

      final PollModel result = await service.vote(matchId: 'match_200', optionId: 'opt_1');

      expect(result.matchId, 'match_200');
      expect(result.totalVotes, 40);
      expect(result.options.length, 2);
      expect(result.userVotedOptionId, 'opt_1');
      expect(result.hasUserVoted, true);

      // Verify receipt was saved
      final cached = await service.getCachedVote('match_200');
      expect(cached, 'opt_1');

      // Verify diagnostics
      expect(PollVoteDiagnostics.instance.statusCode, 200);
      expect(PollVoteDiagnostics.instance.isSuccess, true);
      expect(PollVoteDiagnostics.instance.errorClass, null);
    });
  });
}
