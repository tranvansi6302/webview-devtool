import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:add_2_calendar/add_2_calendar.dart' as cal;
import 'package:permission_handler/permission_handler.dart';
import '../bridge_manager.dart';

import '../bridge_constants.dart';

class MakePhoneCallHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'makePhoneCall';

  @override
  Future<dynamic> handle(
    BuildContext context,
    Map<String, dynamic> params,
  ) async {
    final String number = params['phoneNumber'] ?? params['number'] ?? '';
    if (number.isEmpty) {
      throw BridgeException(BridgeError.invalidParams, 'Số điện thoại không được để trống.');
    }

    final String sanitizedNumber = number.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri url = Uri.parse('tel:$sanitizedNumber');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      return {'success': true};
    } else {
      throw BridgeException(
        BridgeError.notSupported, 
        params['errorMessage'] ?? 'Thiết bị không hỗ trợ gọi điện.'
      );
    }
  }
}

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

class ChoosePhoneContactHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'choosePhoneContact';

  @override
  Future<dynamic> handle(
    BuildContext context,
    Map<String, dynamic> params,
  ) async {
    PermissionStatus status = await Permission.contacts.status;
    if (!status.isGranted) {
      status = await Permission.contacts.request();
      if (!status.isGranted) {
        final openSettings = await _showPermissionDialog(
          context,
          message: params['permissionMessage'] ?? 'Ứng dụng cần quyền truy cập Danh bạ để chọn liên hệ. Vui lòng cấp quyền trong Cài đặt.',
          title: params['permissionTitle'],
          cancelText: params['cancelText'],
          confirmText: params['confirmText'],
        );
        if (openSettings) {
          await openAppSettings();
        }
        throw BridgeException(
          BridgeError.permissionDenied, 
          params['deniedMessage'] ?? 'Quyền truy cập danh bạ bị từ chối.'
        );
      }
    }

    final String? contactId = await fc.FlutterContacts.native.showPicker();
    if (contactId == null) {
      throw BridgeException(
        BridgeError.userCancelled, 
        params['cancelMessage'] ?? 'Hủy chọn danh bạ.'
      );
    }

    final contact = await fc.FlutterContacts.get(contactId);
    if (contact == null) {
      throw BridgeException(BridgeError.internalError, 'Không lấy được thông tin liên hệ.');
    }

    final String phone = contact.phones.isNotEmpty
        ? contact.phones.first.number
        : '';
    return {
      'fullName': contact.displayName,
      'phoneNumber': phone,
    };
  }
}

class AddCalendarEventHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'addCalendarEvent';

  @override
  Future<dynamic> handle(
    BuildContext context,
    Map<String, dynamic> params,
  ) async {
    if (params['startDate'] == null || params['endDate'] == null) {
      throw BridgeException(BridgeError.invalidParams, 'startDate và endDate là bắt buộc.');
    }

    PermissionStatus status = await Permission.calendarFullAccess.status;
    if (!status.isGranted) {
      status = await Permission.calendarFullAccess.request();
      if (!status.isGranted) {
        status = await Permission.calendar.request();
        if (!status.isGranted) {
          final openSettings = await _showPermissionDialog(
            context,
            message: params['permissionMessage'] ?? 'Ứng dụng cần quyền truy cập Lịch để thêm sự kiện. Vui lòng cấp quyền trong Cài đặt.',
            title: params['permissionTitle'],
            cancelText: params['cancelText'],
            confirmText: params['confirmText'],
          );
          if (openSettings) {
            await openAppSettings();
          }
          throw BridgeException(
            BridgeError.permissionDenied, 
            params['deniedMessage'] ?? 'Quyền truy cập lịch bị từ chối.'
          );
        }
      }
    }

    final cal.Event event = cal.Event(
      title: params['title'] ?? '365 Mini App Event',
      description: params['description'] ?? params['notes'] ?? '',
      location: params['location'] ?? '',
      startDate: DateTime.parse(params['startDate']).toLocal(),
      endDate: DateTime.parse(params['endDate']).toLocal(),
      allDay: params['allDay'] ?? false,
    );

    final bool result = await cal.Add2Calendar.addEvent2Cal(event);
    if (!result) throw BridgeException(BridgeError.internalError, params['errorMessage'] ?? 'Không thể thêm sự kiện vào lịch.');
    return {'success': true};
  }
}


class TriggerHapticFeedbackHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'triggerHapticFeedback';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    final String style = params['style'] ?? 'medium';
    switch (style) {
      case 'light':
        await HapticFeedback.selectionClick();
      case 'medium':
        await HapticFeedback.mediumImpact();
      case 'heavy':
        await HapticFeedback.heavyImpact();
      case 'success':
        // Success feedback (simulated)
        await HapticFeedback.mediumImpact();
        await Future.delayed(const Duration(milliseconds: 100));
        await HapticFeedback.lightImpact();
      case 'error':
        // Error feedback (simulated)
        await HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 50));
        await HapticFeedback.heavyImpact();
      default:
        await HapticFeedback.vibrate();
    }
    return {'success': true};
  }
}

class OpenInAppBrowserHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'openInAppBrowser';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    final String? url = params['url'];
    if (url == null) throw 'URL is required';
    
    final Uri uri = Uri.parse(url);
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
    );
    if (!launched) {
      throw BridgeException(BridgeError.internalError, params['errorMessage'] ?? 'Không thể mở trình duyệt cho: $url');
    }
    return {'success': true};
  }
}
