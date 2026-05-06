import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:image/image.dart' as img;
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import '../bridge_manager.dart';

class PreviewImageHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'previewImage';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    final List<String> urls = List<String>.from(params['urls'] ?? []);
    final int current = params['current'] ?? 0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
          backgroundColor: Colors.black,
          body: PhotoViewGallery.builder(
            itemCount: urls.length,
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: urls[index].startsWith('http') ? NetworkImage(urls[index]) : FileImage(File(urls[index])) as ImageProvider,
                initialScale: PhotoViewComputedScale.contained,
              );
            },
            pageController: PageController(initialPage: current),
          ),
        ),
      ),
    );
    return {'success': true};
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

class SaveImageHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'saveImage';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    final String url = params['url'] ?? '';
    if (url.isEmpty) throw 'URL is required';

    // Kiểm tra quyền lưu ảnh
    final hasAccess = await Gal.hasAccess();
    if (!hasAccess) {
      final request = await Gal.requestAccess();
      if (!request) {
        final openSettings = await _showPermissionDialog(
          context,
          message: params['permissionMessage'] ?? 'Ứng dụng cần quyền truy cập Thư viện ảnh để lưu ảnh. Vui lòng cấp quyền trong Cài đặt.',
          title: params['permissionTitle'],
          cancelText: params['cancelText'],
          confirmText: params['confirmText'],
        );
        if (openSettings) {
          await openAppSettings();
        }
        throw params['deniedMessage'] ?? 'Bạn cần cấp quyền truy cập thư viện để lưu ảnh';
      }
    }

    final response = await Dio().get(url, options: Options(responseType: ResponseType.bytes));
    final bytes = Uint8List.fromList(response.data);
    await Gal.putImageBytes(bytes);
    return {'success': true};
  }
}

class GetImageInfoHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'getImageInfo';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    final String src = params['src'] ?? '';
    if (src.isEmpty) throw 'Source is required';

    final File file = File(src);
    if (!await file.exists()) throw 'File not found';

    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw 'Could not decode image';

    return {
      'width': image.width,
      'height': image.height,
      'type': src.split('.').last,
      'path': src,
    };
  }
}

class CompressImageHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'compressImage';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    final String src = params['src'] ?? '';
    final int quality = params['quality'] ?? 80;
    
    if (src.isEmpty) throw 'Source is required';
    final file = File(src);
    if (!await file.exists()) throw 'File not found';

    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw 'Could not decode image';

    final compressedBytes = img.encodeJpg(image, quality: quality);
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(compressedBytes);

    return {
      'tempFilePath': tempFile.path,
      'size': compressedBytes.length,
    };
  }
}
