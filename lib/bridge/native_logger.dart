import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'bridge_manager.dart';

/// Utility giúp đẩy log từ Native Flutter về phía Web application (WebView)
class NativeLogger {
  static BridgeManager? _manager;
  static void Function(String message)? onLog;

  /// Khởi tạo Logger với BridgeManager để có thể gọi runJavaScript
  static void init(BridgeManager manager) {
    _manager = manager;
    log('NativeLogger initialized');
  }

  /// Gửi log về phía Web
  /// - message: Nội dung log
  /// - level: info, warn, error
  /// - data: Dữ liệu đính kèm (optional)
  static void log(String message, {String level = 'info', dynamic data}) {
    // 1. In ra Console của Flutter/Xcode/Android Studio
    debugPrint('[EJSC-NATIVE] [$level] $message');
    if (data != null) debugPrint('   Data: $data');

    if (onLog != null) {
      final String fullMsg = data != null ? '$message | Data: ${jsonEncode(data)}' : message;
      onLog!('[NativeBridge] $fullMsg');
    }

    // 2. Đẩy về phía Web qua Bridge Event
    if (_manager != null) {
      _manager!.sendEvent('native_log', {
        'timestamp': DateTime.now().toIso8601String(),
        'level': level,
        'message': message,
        'data': data,
      });
    }
  }

  static void info(String msg, {dynamic data}) => log(msg, level: 'info', data: data);
  static void warn(String msg, {dynamic data}) => log(msg, level: 'warn', data: data);
  static void error(String msg, {dynamic data}) => log(msg, level: 'error', data: data);
}
