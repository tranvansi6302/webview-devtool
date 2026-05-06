import 'package:flutter/material.dart';
import '../bridge_manager.dart';

class GetUserInfoHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'getUserInfo';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    // Mock user info
    return {
      'name': 'Antigravity User', // Tên người dùng
      'avatar': 'https://i.pravatar.cc/150?u=antigravity', // Link ảnh đại diện
      'gender': 'male', // Giới tính
      'city': 'Ho Chi Minh', // Thành phố
    };
  }
}

class GetAuthCodeHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'getAuthCode';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    return {
      'authCode': 'mock_auth_code_${DateTime.now().millisecondsSinceEpoch}',
      'authSuccessScopes': params['scopes'] ?? ['profile'],
    };
  }
}
