import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../bridge_manager.dart';
import '../bridge_constants.dart';

class SetNavigationBarHandler implements BridgeMethodHandler {
  final Function(String) onTitleChanged;
  final Function(Color) onBgColorChanged;
  final Function(String) onBgColorStrChanged;
  final Function(Color) onTextColorChanged;
  final Function(bool) onVisibleChanged;
  final Function(bool) onImmersiveChanged;
  final Function(String) onBackIconChanged; // 'arrow', 'close', 'none'

  SetNavigationBarHandler({
    required this.onTitleChanged,
    required this.onBgColorChanged,
    required this.onBgColorStrChanged,
    required this.onTextColorChanged,
    required this.onVisibleChanged,
    required this.onImmersiveChanged,
    required this.onBackIconChanged,
  });

  @override
  String get methodName => 'setNavigationBar';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    if (params.containsKey('title')) {
      onTitleChanged(params['title']);
    }
    if (params.containsKey('backgroundColor')) {
      final String colorStr = params['backgroundColor'];
      onBgColorStrChanged(colorStr);
      
      // Chỉ parse và gọi callback Color nếu là mã Hex hợp lệ
      if (colorStr.startsWith('#')) {
        onBgColorChanged(_parseColor(colorStr));
      } else {
        // Nếu là Gradient, gửi màu mặc định hoặc giữ nguyên màu cũ để tránh crash
        // Lưu ý: màu này chỉ dùng làm fallback cho các phần chưa hỗ trợ Gradient
        onBgColorChanged(Colors.indigo); 
      }
    }
    if (params.containsKey('frontColor')) {
      final String colorStr = params['frontColor'];
      onTextColorChanged(colorStr.toLowerCase() == '#ffffff' ? Colors.white : Colors.black);
    }
    if (params.containsKey('visible')) {
      onVisibleChanged(params['visible']);
    }
    if (params.containsKey('immersive')) {
      onImmersiveChanged(params['immersive']);
    }
    if (params.containsKey('backIcon')) {
      onBackIconChanged(params['backIcon']);
    }
    return {'success': true};
  }

  Color _parseColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}

class OpenDeeplinkHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'openDeeplink';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    final String urlStr = params['url'] ?? '';
    final Uri url = Uri.parse(urlStr);

    // If it's a known internal scheme, show a simulated native screen
    if (urlStr.startsWith('ejsc://')) {
      final String displayTitle = params['title'] ?? 'Native Screen';
      final String? description = params['description'] ?? params['desc'];
      
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.indigo,
          title: Text(displayTitle, style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.rocket_launch, size: 64, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                description ?? 'Opening Native Screen:\n$urlStr',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              if (description != null) ...[
                const SizedBox(height: 8),
                Text(
                  'URL: $urlStr',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return {'success': true, 'simulated': true};
    }

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      return {'success': true};
    }
    throw 'Could not launch $urlStr';
  }
}

class OpenPublicDeepLinkHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'openPublicDeepLink';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    final String urlStr = params['url'] ?? '';
    final bool inApp = params['inAppBrowser'] ?? true;
    final Uri url = Uri.parse(urlStr);
    
    try {
      await launchUrl(
        url, 
        mode: inApp ? LaunchMode.inAppWebView : LaunchMode.externalApplication
      );
      return {'success': true};
    } catch (e) {
      throw BridgeException(BridgeError.internalError, params['errorMessage'] ?? 'Không thể mở liên kết: $urlStr');
    }
  }
}

class ShareAppHandler implements BridgeMethodHandler {
  @override
  String get methodName => 'shareApp';

  @override
  Future<dynamic> handle(BuildContext context, Map<String, dynamic> params) async {
    final String title = params['title'] ?? 'Chia sẻ';
    final String desc = params['desc'] ?? params['description'] ?? '';
    final String url = params['url'] ?? params['path'] ?? '';
    
    String shareContent = title;
    if (desc.isNotEmpty) shareContent += '\n$desc';
    if (url.isNotEmpty) shareContent += '\nLink: $url';
    
    await Share.share(shareContent);
    return {'success': true};
  }
}
