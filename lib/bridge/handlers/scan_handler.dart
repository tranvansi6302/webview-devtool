import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../widgets/qr_overlay.dart';
import '../bridge_manager.dart';
import '../bridge_constants.dart';

Future<bool> _showPermissionDialog(
  BuildContext context, {
  required String message,
  String? title,
  String? cancelText,
  String? confirmText,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title ?? 'Cấp quyền truy cập'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(cancelText ?? 'Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmText ?? 'Mở Cài đặt'),
            ),
          ],
        ),
      ) ??
      false;
}

class ScanBridgeHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'scan';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    PermissionStatus status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        final openSettings = await _showPermissionDialog(
          context,
          message: params['permissionMessage'] ?? 'Ứng dụng cần quyền sử dụng Camera để quét mã QR. Vui lòng cấp quyền trong Cài đặt.',
          title: params['permissionTitle'],
          cancelText: params['cancelText'],
          confirmText: params['confirmText'],
        );
        if (openSettings) {
          await openAppSettings();
        }
        throw params['deniedMessage'] ?? 'Bạn cần cấp quyền Camera để thực hiện quét mã QR';
      }
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QrScannerPage(
          title: params['title'] ?? 'Quét mã QR',
          hintText: params['hintText'] ?? 'Căn chỉnh mã QR vào giữa khung hình',
          scanAreaSize: (params['scanAreaSize'] as num?)?.toDouble() ?? 260.0,
        ),
      ),
    );

    if (result == null) {
      throw BridgeException(
        BridgeError.userCancelled, 
        params['cancelMessage'] ?? 'Người dùng đã hủy quét mã.'
      );
    }
    return result;
  }
}

