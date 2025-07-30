class ServerException implements Exception {
  final String message;
  final int? code;

  const ServerException({
    required this.message,
    this.code,
  });
}

class NetworkException implements Exception {
  final String message;
  final int? code;

  const NetworkException({
    required this.message,
    this.code,
  });
}

class CacheException implements Exception {
  final String message;
  final int? code;

  const CacheException({
    required this.message,
    this.code,
  });
}

class ValidationException implements Exception {
  final String message;
  final Map<String, String>? errors;

  const ValidationException({
    required this.message,
    this.errors,
  });
}

class AuthException implements Exception {
  final String message;
  final int? code;

  const AuthException({
    required this.message,
    this.code,
  });
}
