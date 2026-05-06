import 'dart:io';
import 'package:flutter/material.dart';
import '../bridge_manager.dart';

class ExitBridgeHandler implements BridgeMethodHandler {
  final Future<void> Function() onExit;
  
  ExitBridgeHandler({required this.onExit});

  @override
  String get methodName => 'exitMiniApp';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    await onExit();
    return {};
  }
}

class SystemInfoBridgeHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'getSystemInfo';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    final media = MediaQuery.of(context);
    return {
      'brand': 'Google', // Thương hiệu thiết bị
      'model': Platform.isAndroid ? 'Android Device' : 'iOS Device', // Model thiết bị
      'system': Platform.isAndroid ? 'Android' : 'iOS', // Tên hệ điều hành
      'platform': Platform.isAndroid ? 'android' : 'ios', // Nền tảng (viết thường)
      'version': Platform.operatingSystemVersion, // Phiên bản hệ điều hành
      'app': 'EJSC MiniApp Dev', // Tên ứng dụng host
      'hostVersion': '1.0.0', // Phiên bản ứng dụng host
      'runtimeVersion': '1.0.0', // Phiên bản bộ chạy Mini App
      'currentBattery': 100, // Mức pin hiện tại
      'freeStorage': 1024 * 1024 * 1024, // Dung lượng trống (bytes)
      'screenWidth': media.size.width, // Chiều rộng màn hình
      'screenHeight': media.size.height, // Chiều cao màn hình
      'windowWidth': media.size.width, // Chiều rộng cửa sổ khả dụng
      'windowHeight': media.size.height, // Chiều cao cửa sổ khả dụng
      'statusBarHeight': media.padding.top, // Chiều cao thanh trạng thái
      'titleBarHeight': 44.0, // Chiều cao thanh tiêu đề mặc định
      'safeAreaTop': media.padding.top, // Vùng an toàn phía trên
      'safeAreaBottom': media.padding.bottom, // Vùng an toàn phía dưới
      'pixelRatio': media.devicePixelRatio, // Tỉ lệ điểm ảnh
      'locale': 'vi-VN', // Ngôn ngữ hệ thống
      'deviceId': 'mock-device-id', // Định danh thiết bị
    };
  }
}
