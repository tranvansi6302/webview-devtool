import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'native_logger.dart';
import 'bridge_constants.dart';

/**
 * Lớp trừu tượng định nghĩa cấu trúc của một Handler xử lý phương thức bridge.
 */
abstract class BridgeMethodHandler {
  /** Tên phương thức được gọi từ phía Web (ví dụ: 'getLocation') */
  String get methodName;

  /** Hàm xử lý logic nghiệp vụ phía Native và trả về kết quả */
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params);
}

/**
 * Quản lý việc giao tiếp giữa WebView (JavaScript) và Flutter (Native).
 */
class BridgeManager {
  final WebViewController controller;
  /** Danh sách các handler đã đăng ký, map theo tên phương thức */
  final Map<String, BridgeMethodHandler> _handlers = {};

  BridgeManager(this.controller);

  /** Đăng ký một handler mới vào hệ thống bridge */
  void register(BridgeMethodHandler handler) {
    _handlers[handler.methodName] = handler;
  }

  /** Đăng ký một handler với tên gọi khác (alias) để hỗ trợ tương thích ngược */
  void registerWithAlias(String alias, BridgeMethodHandler handler) {
    _handlers[alias] = handler;
  }

  /**
   * Xử lý tin nhắn đến từ phía Web.
   * Tin nhắn có dạng JSON: { method, id, params }
   */
  Future<void> handleMessage(BuildContext context, String message) async {
    try {
      final Map<String, dynamic> data = jsonDecode(message);
      final String method = data['method'];
      final int id = data['id'];
      final Map<String, dynamic> params = data['params'] ?? {};

      NativeLogger.info('Web -> Native: $method (id: $id)', data: params);

      if (_handlers.containsKey(method)) {
        try {
          // Gọi handler tương ứng và lấy kết quả
          final result = await _handlers[method]!.handle(context, params);
          _sendSuccess(id, result);
        } on BridgeException catch (e) {
          // Xử lý lỗi Bridge cụ thể có kèm mã lỗi
          _sendError(id, e.message, code: e.code);
        } catch (e) {
          // Gửi thông báo lỗi chung nếu handler ném ra ngoại lệ không xác định
          _sendError(id, e.toString(), code: BridgeError.unknown);
        }
      } else {
        // Gửi lỗi nếu phương thức chưa được đăng ký
        _sendError(id, 'Method $method not supported', code: BridgeError.notSupported);
      }
    } catch (e) {
      debugPrint('Bridge Manager Error: $e');
    }
  }

  /** Gửi kết quả thành công về phía Web qua JavaScript */
  void _sendSuccess(int id, dynamic data) {
    NativeLogger.info('Native -> Web: Success (id: $id)', data: data);
    final response = jsonEncode({
      'success': true,
      'data': data ?? {},
    });
    // Thực thi hàm callback trên Web
    controller.runJavaScript('window.ejsc._onNativeResponse($id, $response)');
  }

  /** Gửi thông báo lỗi về phía Web qua JavaScript */
  void _sendError(int id, String message, {String code = 'UNKNOWN_ERROR'}) {
    NativeLogger.error('Native -> Web: Error (id: $id)', data: message);
    final response = jsonEncode({
      'success': false,
      'data': {
        'code': code,
        'message': message,
      },
    });
    // Thực thi hàm callback trên Web
    controller.runJavaScript('window.ejsc._onNativeResponse($id, $response)');
  }

  /**
   * Gửi một sự kiện chủ động từ Native về phía Web (Event Emit).
   * Web sẽ lắng nghe qua sự kiện 'ejsc:native-event'.
   */
  void sendEvent(String eventName, dynamic data) {
    final payload = jsonEncode(data);
    controller.runJavaScript('window.ejsc._onNativeEvent("$eventName", $payload)');
  }
}
