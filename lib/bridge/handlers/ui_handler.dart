import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../bridge_manager.dart';

class ToastHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'showToast';

  @override
  Future<dynamic> handle(
    BuildContext context,
    Map<String, dynamic> params,
  ) async {
    final String content = params['content'] ?? '';
    final String type = params['type'] ?? 'info';
    final int duration = params['duration'] ?? 2000;

    final String position = params['position'] ?? 'bottom';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(content),
        duration: Duration(milliseconds: duration),
        behavior: SnackBarBehavior.floating,
        margin: position == 'top' 
            ? EdgeInsets.only(bottom: MediaQuery.of(context).size.height - 100, left: 10, right: 10)
            : (position == 'center' 
                ? EdgeInsets.only(bottom: MediaQuery.of(context).size.height / 2, left: 10, right: 10)
                : const EdgeInsets.all(10)),
        backgroundColor: type == 'success'
            ? Colors.green
            : (type == 'fail' ? Colors.red : Colors.black87),
      ),
    );
    return {'success': true};
  }
}

class AlertHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'alert';

  @override
  Future<dynamic> handle(
    BuildContext context,
    Map<String, dynamic> params,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(params['title'] ?? '365 Mini App Debugger'),
        content: Text(params['content'] ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(params['confirmButtonText'] ?? params['buttonText'] ?? 'OK'),
          ),
        ],
      ),
    );
    return {'success': true};
  }
}

class ConfirmHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'confirm';

  @override
  Future<dynamic> handle(
    BuildContext context,
    Map<String, dynamic> params,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(params['title'] ?? 'Xác nhận hệ thống'),
        content: Text(params['content'] ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(params['cancelButtonText'] ?? 'Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(params['confirmButtonText'] ?? 'Đồng ý'),
          ),
        ],
      ),
    );
    return {'confirm': result ?? false};
  }
}

class PromptHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'prompt';

  @override
  Future<dynamic> handle(
    BuildContext context,
    Map<String, dynamic> params,
  ) async {
    final controller = TextEditingController(
      text: params['defaultValue'] ?? '',
    );
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(params['title'] ?? 'Yêu cầu nhập liệu'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: params['placeholder'] ?? ''),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, {'ok': false, 'inputValue': ''}),
            child: Text(params['cancelButtonText'] ?? 'Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'ok': true,
              'inputValue': controller.text,
            }),
            child: Text(params['confirmButtonText'] ?? params['okButtonText'] ?? 'Xác nhận'),
          ),
        ],
      ),
    );
    return result ?? {'ok': false, 'inputValue': ''};
  }
}

class ActionSheetHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'showActionSheet';

  @override
  Future<dynamic> handle(
    BuildContext context,
    Map<String, dynamic> params,
  ) async {
    final List<String> items = List<String>.from(params['items'] ?? []);
    final int? destructiveIndex = params['destructiveBtnIndex'];

    final result = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (params['title'] != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  params['title'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ...items.asMap().entries.map(
              (entry) => ListTile(
                title: Text(
                  entry.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: entry.key == destructiveIndex ? Colors.red : null,
                  ),
                ),
                onTap: () => Navigator.pop(context, entry.key),
              ),
            ),
            const Divider(),
            ListTile(
              title: Text(
                params['cancelButtonText'] ?? params['cancelButton'] ?? 'Hủy',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () => Navigator.pop(context, -1),
            ),
          ],
        ),
      ),
    );
    return {'index': result ?? -1};
  }
}

class LoadingHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'showLoading';

  @override
  Future<dynamic> handle(
    BuildContext context,
    Map<String, dynamic> params,
  ) async {
    final String content = params['content'] ?? 'Đang tải...';
    EasyLoading.show(status: content, maskType: EasyLoadingMaskType.black);
    return {'success': true};
  }
}

class HideLoadingHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'hideLoading';

  @override
  Future<dynamic> handle(
    BuildContext context,
    Map<String, dynamic> params,
  ) async {
    EasyLoading.dismiss();
    return {'success': true};
  }
}

class ConfirmBeforeExitHandler implements BridgeMethodHandler {
  final Function(bool, String) onUpdate;

  ConfirmBeforeExitHandler({required this.onUpdate});

  @override
  String get methodName => 'confirmBeforeExit';

  @override
  Future<dynamic> handle(
    BuildContext context,
    Map<String, dynamic> params,
  ) async {
    final bool enable = params['enable'] ?? true;
    final String message =
        params['message'] ?? params['content'] ?? 'Bạn có chắc chắn muốn thoát?';

    onUpdate(enable, message);
    return {'success': true, 'enabled': enable};
  }
}

