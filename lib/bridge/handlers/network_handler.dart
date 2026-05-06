import 'dart:convert';
import 'package:http/http.dart' as http;
import '../bridge_manager.dart';
import 'package:flutter/material.dart';

class RequestHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'request';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    final String url = params['url'];
    final String method = (params['method'] ?? 'GET').toUpperCase();
    final Map<String, String> headers = Map<String, String>.from(params['headers'] ?? {});
    final dynamic data = params['data'];

    late http.Response response;

    switch (method) {
      case 'GET':
        response = await http.get(Uri.parse(url), headers: headers);
        break;
      case 'POST':
        response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: data is String ? data : jsonEncode(data),
        );
        break;
      case 'PUT':
        response = await http.put(
          Uri.parse(url),
          headers: headers,
          body: data is String ? data : jsonEncode(data),
        );
        break;
      case 'DELETE':
        response = await http.delete(Uri.parse(url), headers: headers);
        break;
      default:
        throw 'Method $method not supported';
    }

    dynamic responseData;
    try {
      responseData = jsonDecode(response.body);
    } catch (_) {
      responseData = response.body;
    }

    return {
      'data': responseData,
      'statusCode': response.statusCode,
      'header': response.headers,
    };
  }
}
