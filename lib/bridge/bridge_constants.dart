/**
 * Định nghĩa các mã lỗi chuẩn cho hệ thống Bridge.
 * Giúp đồng nhất việc xử lý lỗi giữa Native và Web.
 */
class BridgeError {
  static const String unknown = 'UNKNOWN_ERROR';
  static const String invalidParams = 'INVALID_PARAMS';
  static const String permissionDenied = 'PERMISSION_DENIED';
  static const String notSupported = 'NOT_SUPPORTED';
  static const String userCancelled = 'USER_CANCELLED';
  static const String timeout = 'TIMEOUT';
  static const String networkError = 'NETWORK_ERROR';
  static const String storageError = 'STORAGE_ERROR';
  static const String internalError = 'INTERNAL_ERROR';
}

/**
 * Ngoại lệ tùy chỉnh cho các lỗi trong Bridge.
 */
class BridgeException implements Exception {
  final String code;
  final String message;

  BridgeException(this.code, this.message);

  @override
  String toString() => message;
}
