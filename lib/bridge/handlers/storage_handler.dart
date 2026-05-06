import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../bridge_manager.dart';

/**
 * Quản lý lưu trữ dữ liệu thông thường (SharedPreferences).
 */
class SetStorageHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'setStorage';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    final String key = params['key'] ?? '';
    final dynamic value = params['data'] ?? params['value'];
    
    if (key.isEmpty) throw 'Key is required';
    
    final prefs = await SharedPreferences.getInstance();
    if (value is String) await prefs.setString(key, value);
    else if (value is int) await prefs.setInt(key, value);
    else if (value is bool) await prefs.setBool(key, value);
    else if (value is double) await prefs.setDouble(key, value);
    else await prefs.setString(key, value.toString());
    
    return {'success': true};
  }
}

class GetStorageHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'getStorage';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    final String key = params['key'] ?? '';
    if (key.isEmpty) throw 'Key is required';
    
    final prefs = await SharedPreferences.getInstance();
    return {'data': prefs.get(key)};
  }
}

/**
 * Quản lý lưu trữ bảo mật (Keychain/Keystore).
 */
class SetSecureStorageHandler implements BridgeMethodHandler {
  final _storage = const FlutterSecureStorage();

  @override
  String get methodName => 'setSecureStorage';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    final String key = params['key'] ?? '';
    final String value = (params['data'] ?? params['value'] ?? '').toString();
    
    if (key.isEmpty) throw 'Key is required';
    
    await _storage.write(key: key, value: value);
    return {'success': true};
  }
}

class GetSecureStorageHandler implements BridgeMethodHandler {
  final _storage = const FlutterSecureStorage();

  @override
  String get methodName => 'getSecureStorage';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    final String key = params['key'] ?? '';
    if (key.isEmpty) throw 'Key is required';
    
    final value = await _storage.read(key: key);
    return {'data': value};
  }
}

class RemoveStorageHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'removeStorage';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    final String key = params['key'] ?? '';
    if (key.isEmpty) throw 'Key is required';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    return {'success': true};
  }
}

class ClearStorageHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'clearStorage';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    return {'success': true};
  }
}

class GetStorageInfoHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'getStorageInfo';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().toList();
    return {
      'keys': keys,
      'currentSize': keys.length, // Placeholder
      'limitSize': 10 * 1024, // Placeholder 10MB
    };
  }
}
