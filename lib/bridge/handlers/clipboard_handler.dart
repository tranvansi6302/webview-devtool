import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../bridge_manager.dart';

class SetClipboardHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'setClipboard';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    final String text = params['text'] ?? '';
    await Clipboard.setData(ClipboardData(text: text));
    return {'success': true}; // Trả về thành công
  }
}

class GetClipboardHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'getClipboard';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return {'text': data?.text ?? ''}; // Trả về nội dung clipboard
  }
}
