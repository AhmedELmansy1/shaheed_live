import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env_config.dart';
import 'app_exception.dart';

/// Provider exposing the singleton instance of [DioClient].
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

/// Client wrapper around [Dio] for fetching live scores and match statistics.
///
/// Supported Query Parameter Combinations:
/// - `type=matches_today`: Fetches today's matches list.
/// - `type=matches_tomorrow`: Fetches tomorrow's scheduled matches.
/// - `type=matches_yesterday`: Fetches yesterday's completed matches.
/// - `type=matches_by_date&date=YYYY-MM-DD`: Fetches matches for a specific date.
/// - `type=match_info&id={id}`: Fetches general information for a specific match.
/// - `type=statics_match&id={id}`: Fetches detailed match statistics.
/// - `type=matches_event&id={id}`: Fetches match timeline events (goals, cards, subs).
/// - `type=matches_lineup&id={id}`: Fetches starting lineups and substitutes.
class DioClient {
  late Dio _dio;
  String _baseUrl;

  DioClient({String? baseUrl, Dio? dio})
      : _baseUrl = baseUrl ?? EnvConfig.baseApiUrl {
    _dio = dio ??
        Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

    // Only log in debug mode to protect performance and avoid sensitive exposure
    if (kDebugMode) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint(
              '[DioClient] 🌐 REQ: ${options.method} ${options.baseUrl}?${options.queryParameters}',
            );
            handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint(
              '[DioClient] ✅ RES [${response.statusCode}] for ${response.requestOptions.queryParameters}',
            );
            handler.next(response);
          },
          onError: (error, handler) {
            debugPrint(
              '[DioClient] ❌ ERR [${error.response?.statusCode ?? error.type}] for ${error.requestOptions.queryParameters}: ${error.message}',
            );
            handler.next(error);
          },
        ),
      );
    }
  }

  /// Updates the Base URL dynamically at runtime (e.g. from Remote Config override).
  void updateBaseUrl(String newBaseUrl) {
    _baseUrl = newBaseUrl;
    _dio.options.baseUrl = newBaseUrl;
  }

  /// Current active base URL.
  String get baseUrl => _baseUrl;

  /// Internal Dio instance for testing overrides.
  @visibleForTesting
  Dio get dioInstance => _dio;

  /// Sends a GET request with query parameters and extracts the "data" payload key.
  /// Automatically retries once with exponential backoff on transient network/server failures.
  Future<dynamic> get({
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    int attempts = 0;
    const maxAttempts = 2; // 1 initial try + 1 retry

    while (true) {
      attempts++;
      try {
        final response = await _dio.get(
          '',
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
        );

        final responseData = response.data;
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('data')) {
            return responseData['data'];
          }
          return responseData;
        } else if (responseData is List) {
          return responseData;
        } else if (responseData == null) {
          return null;
        } else {
          throw ParseException(message: 'تنسيق الاستجابة غير متوقع');
        }
      } on DioException catch (e) {
        final isRetryable = _isTransientError(e);
        if (attempts < maxAttempts &&
            isRetryable &&
            cancelToken?.isCancelled != true) {
          if (kDebugMode) {
            debugPrint(
              '[DioClient] Transient network glitch (${e.type}), retrying GET in 1000ms... (attempt $attempts/$maxAttempts)',
            );
          }
          await Future.delayed(const Duration(milliseconds: 1000));
          continue;
        }
        throw _handleDioError(e);
      } catch (e) {
        if (e is AppException) rethrow;
        throw ParseException(
          message: 'حدث خطأ غير متوقع أثناء معالجة البيانات',
          originalError: e,
        );
      }
    }
  }

  bool _isTransientError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return true;
    }
    final status = e.response?.statusCode;
    if (status != null &&
        (status == 500 || status == 502 || status == 503 || status == 504)) {
      return true;
    }
    return false;
  }

  AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(
          message: 'انتهت مهلة الاتصال بالخادم. يرجى التحقق من الشبكة والمحاولة مجدداً.',
          originalError: error,
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        String userMsg = 'حدث خطأ من الخادم (كود: ${statusCode ?? "غير معروف"})';
        if (statusCode == 404) {
          userMsg = 'لم يتم العثور على البيانات المطلوبة من الخادم (404)';
        } else if (statusCode != null && statusCode >= 500) {
          userMsg = 'الخادم يواجه ضغطاً أو مشكلة مؤقتة. يرجى المحاولة لاحقاً (كود: $statusCode)';
        }
        return ServerException(
          statusCode: statusCode,
          message: userMsg,
          originalError: error,
        );
      case DioExceptionType.connectionError:
        if (error.error is SocketException) {
          return NetworkException(
            message: 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصال الشبكة.',
            originalError: error,
          );
        }
        return NetworkException(
          message: 'فشل في الاتصال بالشبكة',
          originalError: error,
        );
      case DioExceptionType.cancel:
        return AppException(message: 'تم إلغاء الطلب', originalError: error);
      default:
        return AppException(
          message: 'تعذر الاتصال بالخادم. يرجى المحاولة ثانية.',
          originalError: error,
        );
    }
  }
}
