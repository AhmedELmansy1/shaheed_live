/// Custom exception hierarchy for network and application errors.
class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  AppException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message (StatusCode: $statusCode)';
}

class NetworkException extends AppException {
  NetworkException({super.message = 'لا يوجد اتصال بالإنترنت', super.originalError});
}

class TimeoutException extends AppException {
  TimeoutException({super.message = 'انتهت مهلة الاتصال بالخادم', super.originalError});
}

class ServerException extends AppException {
  ServerException({super.message = 'حدث خطأ في الخادم', super.statusCode, super.originalError});
}

class ParseException extends AppException {
  ParseException({super.message = 'خطأ في معالجة البيانات', super.originalError});
}
