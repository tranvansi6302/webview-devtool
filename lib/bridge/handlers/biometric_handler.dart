import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_ios/local_auth_ios.dart';
import '../bridge_manager.dart';
import '../bridge_constants.dart';

class BiometricBridgeHandler implements BridgeMethodHandler {
  final LocalAuthentication auth = LocalAuthentication();

  @override
  String get methodName => 'bioMetrics'; // namespace as method name for ease

  @override
  Future<dynamic> handle(
    BuildContext context,
    Map<String, dynamic> params,
  ) async {
    final String action = params['action'] ?? 'isSupported';

    switch (action) {
      case 'isSupported':
        return await _isSupported();
      case 'localAuth':
        final bool result = await _localAuth(
          params['reason'] ?? params['content'] ?? 'Xác nhận danh tính',
          title: params['title'],
          hint: params['hint'],
          cancelText: params['cancelText'],
        );
        if (!result) {
          throw BridgeException(
            BridgeError.userCancelled, 
            params['cancelMessage'] ?? 'Người dùng đã hủy hoặc xác thực thất bại.'
          );
        }
        return {'success': true};
      default:
        throw 'Action $action not supported for bioMetrics';
    }
  }

  Future<Map<String, dynamic>> _isSupported() async {
    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    final bool canAuthenticate =
        canAuthenticateWithBiometrics || await auth.isDeviceSupported();
    final List<BiometricType> availableBiometrics = await auth
        .getAvailableBiometrics();

    return {
      'isSupported': canAuthenticate,
      'mode': availableBiometrics
          .map((e) => e.toString().split('.').last)
          .toList(),
    };
  }

  Future<bool> _localAuth(
    String reason, {
    String? title,
    String? hint,
    String? cancelText,
  }) async {
    try {
      final bool success = await auth.authenticate(
        localizedReason: reason,
        authMessages: <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: title ?? 'Xác thực sinh trắc học',
            biometricHint: hint ?? 'Vui lòng xác nhận danh tính',
            cancelButton: cancelText ?? 'Hủy',
          ),
          IOSAuthMessages(),
        ],
      );
      return success;
    } catch (e) {
      debugPrint('Biometric Error: $e');
      throw BridgeException(BridgeError.internalError, e.toString());
    }
  }
}
