import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../bridge_manager.dart';

class SettingsBridgeHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'getSetting';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    return {
      'authSetting': {
        'scope.userLocation': (await Permission.location.status).isGranted,
        'scope.camera': (await Permission.camera.status).isGranted,
        'scope.writePhotosAlbum': (await Permission.photos.status).isGranted,
        'scope.record': (await Permission.microphone.status).isGranted,
        'scope.addressBook': (await Permission.contacts.status).isGranted,
        'scope.notification': (await Permission.notification.status).isGranted,
      },
    };
  }
}

class AuthorizeBridgeHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'authorize';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    final String scope = params['scope'] ?? '';
    Permission? p;
    if (scope == 'scope.userLocation') p = Permission.location;
    if (scope == 'scope.camera') p = Permission.camera;
    if (scope == 'scope.writePhotosAlbum') p = Permission.photos;
    if (scope == 'scope.record') p = Permission.microphone;
    if (scope == 'scope.addressBook') p = Permission.contacts;
    if (scope == 'scope.notification') p = Permission.notification;

    if (p == null) throw 'Scope $scope not supported';
    final s = await p.request();
    return {'status': s.isGranted ? 'authorized' : 'denied'};
  }
}

class OpenSettingBridgeHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'openSetting';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    await openAppSettings();
    return {};
  }
}
class OpenAppSettingBridgeHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'openAppSetting';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    await openAppSettings();
    return {};
  }
}

class OpenNativeStoreBridgeHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'openNativeStore';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    // This is a simplified version. Usually you'd use a package or specific URLs.
    // For now we just mock or use a generic link if provided.
    return {'success': false, 'message': 'Not implemented yet'};
  }
}
