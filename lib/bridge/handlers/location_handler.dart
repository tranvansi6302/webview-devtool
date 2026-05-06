import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../bridge_manager.dart';
import '../native_logger.dart';
import '../bridge_constants.dart';

/**
 * Hiển thị thông báo yêu cầu cấp quyền.
 */
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

/**
 * Lấy vị trí cơ bản (Chỉ tọa độ).
 */
class LocationBridgeHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'getLocation';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    final bool highAccuracy = params['type'] == 1;
    
    // Kiểm tra quyền
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        final openSettings = await _showPermissionDialog(
          context,
          message: params['permissionMessage'] ?? 'Ứng dụng cần quyền truy cập vị trí để lấy tọa độ. Vui lòng cấp quyền trong Cài đặt.',
          title: params['permissionTitle'],
          cancelText: params['cancelText'],
          confirmText: params['confirmText'],
        );
        if (openSettings) {
          await openAppSettings();
        }
        throw BridgeException(
          BridgeError.permissionDenied, 
          params['deniedMessage'] ?? 'Quyền truy cập vị trí bị từ chối.'
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw BridgeException(
        BridgeError.permissionDenied, 
        params['deniedForeverMessage'] ?? 'Quyền truy cập vị trí bị chặn vĩnh viễn.'
      );
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: highAccuracy ? LocationAccuracy.high : LocationAccuracy.medium,
    );
    
    return {
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'accuracy': pos.accuracy,
      'altitude': pos.altitude,
      'altitudeAccuracy': pos.altitudeAccuracy,
      'heading': pos.heading,
      'speed': pos.speed,
      'timestamp': pos.timestamp.millisecondsSinceEpoch,
    };
  }
}

/**
 * Lấy vị trí nâng cao (Tọa độ + Địa chỉ).
 */
class GetUserLocationHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'getUserLocation';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    final bool enableHighAccuracy = params['enableHighAccuracy'] ?? true;
    
    // Kiểm tra quyền
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        final openSettings = await _showPermissionDialog(
          context,
          message: params['permissionMessage'] ?? 'Ứng dụng cần quyền truy cập vị trí để lấy địa chỉ. Vui lòng cấp quyền trong Cài đặt.',
          title: params['permissionTitle'],
          cancelText: params['cancelText'],
          confirmText: params['confirmText'],
        );
        if (openSettings) {
          await openAppSettings();
        }
        throw BridgeException(
          BridgeError.permissionDenied, 
          params['deniedMessage'] ?? 'Quyền truy cập vị trí bị từ chối.'
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw BridgeException(
        BridgeError.permissionDenied, 
        params['deniedForeverMessage'] ?? 'Quyền truy cập vị trí bị chặn vĩnh viễn.'
      );
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: enableHighAccuracy ? LocationAccuracy.high : LocationAccuracy.medium,
    );

    String address = params['fallbackAddress'] ?? 'Unknown Address';
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        address = "${p.street}, ${p.subAdministrativeArea}, ${p.administrativeArea}, ${p.country}";
      }
    } catch (e) {
      NativeLogger.error('Lỗi khi lấy địa chỉ: $e');
    }

    return {
      'lat': position.latitude,
      'lng': position.longitude,
      'address': address,
    };
  }
}

/**
 * Mở bản đồ Native.
 */
class OpenNativeMapHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'openNativeMap';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    double? lat = params['lat'] != null ? (params['lat'] as num).toDouble() : null;
    double? lng = params['lng'] != null ? (params['lng'] as num).toDouble() : null;
    String? address = params['address'];
    final String label = params['label'] ?? 'Vị trí của tôi';

    // Nếu không truyền gì, tự động lấy vị trí hiện tại
    if (lat == null && lng == null && address == null) {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      lat = position.latitude;
      lng = position.longitude;
    }

    Uri googleMapsAppUri;
    Uri appleMapsAppUri;
    Uri googleMapsWebUri;

    if (lat != null && lng != null) {
      // Mở theo tọa độ (Vị trí truyền vào hoặc vị trí hiện tại vừa lấy được)
      googleMapsAppUri = Uri.parse("geo:$lat,$lng?q=$lat,$lng($label)");
      appleMapsAppUri = Uri.parse("maps://?q=$label&ll=$lat,$lng");
      googleMapsWebUri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$lat,$lng");
    } else {
      // Mở theo địa chỉ (Search)
      final encodedAddress = Uri.encodeComponent(address!);
      googleMapsAppUri = Uri.parse("geo:0,0?q=$encodedAddress");
      appleMapsAppUri = Uri.parse("maps://?q=$encodedAddress");
      googleMapsWebUri = Uri.parse("https://www.google.com/maps/search/?api=1&query=$encodedAddress");
    }

    try {
      if (Platform.isIOS) {
        if (await canLaunchUrl(appleMapsAppUri)) {
          await launchUrl(appleMapsAppUri);
        } else {
          await launchUrl(googleMapsWebUri, mode: LaunchMode.externalApplication);
        }
      } else {
        if (await canLaunchUrl(googleMapsAppUri)) {
          await launchUrl(googleMapsAppUri);
        } else {
          await launchUrl(googleMapsWebUri, mode: LaunchMode.externalApplication);
        }
      }
      return {'success': true};
    } catch (e) {
      NativeLogger.error('Lỗi mở bản đồ: $e');
      try {
        await launchUrl(googleMapsWebUri, mode: LaunchMode.externalApplication);
        return {'success': true};
      } catch (innerE) {
        throw params['errorMessage'] ?? 'Không thể mở bản đồ: $innerE';
      }
    }
  }
}

