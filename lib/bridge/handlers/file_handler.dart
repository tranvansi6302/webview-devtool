import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../bridge_manager.dart';

class DownloadFileHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'downloadFile';

  @override
  Future<dynamic> handle(
    BuildContext context,
    Map<String, dynamic> params,
  ) async {
    final String url = params['url'];
    if (url == null) throw 'URL is required';

    final dio = Dio();
    final directory = await getApplicationDocumentsDirectory();
    final fileName = url.split('/').last;
    final savePath = '${directory.path}/$fileName';

    await dio.download(url, savePath);

    return {'filePath': savePath, 'statusCode': 200};
  }
}

class UploadFileHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'uploadFile';

  @override
  Future<dynamic> handle(
    BuildContext context,
    Map<String, dynamic> params,
  ) async {
    final String url = params['url'];
    final String filePath = params['filePath'];
    final String fileName = params['fileName'] ?? 'file';

    if (url == null || filePath == null) throw 'URL and filePath are required';

    final dio = Dio();
    final formData = FormData.fromMap({
      fileName: await MultipartFile.fromFile(filePath),
      ...(params['formData'] ?? {}),
    });

    final response = await dio.post(url, data: formData);

    return {'data': response.data, 'statusCode': response.statusCode};
  }
}
