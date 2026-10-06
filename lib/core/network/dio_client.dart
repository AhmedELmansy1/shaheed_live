import 'dart:io';

import 'package:dio/dio.dart';
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

  DioClient({String? baseUrl}) : _baseUrl = baseUrl ?? EnvConfig.baseApiUrl {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  /// Updates the Base URL dynamically at runtime (e.g. from Remote Config override).
  void updateBaseUrl(String newBaseUrl) {
    _baseUrl = newBaseUrl;
    _dio.options.baseUrl = newBaseUrl;
  }

  /// Current active base URL.
  String get baseUrl => _baseUrl;

  /// Sends a GET request with query parameters and extracts the "data" payload key.
  Future<dynamic> get({
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
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
      } else {
        throw ParseException(message: 'تنسيق الاستجابة غير متوقع');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw ParseException(
        message: 'حدث خطأ غير متوقع أثناء معالجة البيانات',
        originalError: e,
      );
    }
  }

  AppException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(originalError: error);
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        return ServerException(
          statusCode: statusCode,
          message: 'خطأ من الخادم (كود: ${statusCode ?? "غير معروف"})',
          originalError: error,
        );
      case DioExceptionType.connectionError:
        if (error.error is SocketException) {
          return NetworkException(originalError: error);
        }
        return NetworkException(
          message: 'فشل في الاتصال بالشبكة',
          originalError: error,
        );
      case DioExceptionType.cancel:
        return AppException(message: 'تم إلغاء الطلب', originalError: error);
      default:
        return AppException(
          message: 'حدث خطأ غير متوقع في الشبكة',
          originalError: error,
        );
    }
  }
}
