class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException(this.message, {this.code, this.originalError, this.stackTrace});

  // ========== Factory Constructors ==========

  factory AppException.error(String message, {String? code, dynamic originalError, StackTrace? stackTrace}) {
    return AppException(message, code: code ?? 'ERROR', originalError: originalError, stackTrace: stackTrace);
  }

  /// Database operation failed
  factory AppException.database(String message, {String? code, dynamic originalError, StackTrace? stackTrace}) {
    return AppException(message, code: code ?? 'DATABASE_ERROR', originalError: originalError, stackTrace: stackTrace);
  }

  /// Validation failed
  factory AppException.validation(String message, {String? code, dynamic originalError, StackTrace? stackTrace}) {
    return AppException(
      message,
      code: code ?? 'VALIDATION_ERROR',
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  /// Resource not found
  factory AppException.notFound(String message, {String? code, dynamic originalError, StackTrace? stackTrace}) {
    return AppException(message, code: code ?? 'NOT_FOUND', originalError: originalError, stackTrace: stackTrace);
  }

  /// Permission denied
  factory AppException.permission(String message, {String? code, dynamic originalError, StackTrace? stackTrace}) {
    return AppException(
      message,
      code: code ?? 'PERMISSION_DENIED',
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  /// Unexpected/unknown error
  factory AppException.unknown(String message, {String? code, dynamic originalError, StackTrace? stackTrace}) {
    return AppException(message, code: code ?? 'UNKNOWN_ERROR', originalError: originalError, stackTrace: stackTrace);
  }

  @override
  String toString() => message;
}
