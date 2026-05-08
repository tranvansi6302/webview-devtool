import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Bridge & Utility Imports
import '../bridge/bridge_manager.dart';
import '../bridge/bridge_injector.dart';
import '../bridge/native_logger.dart';
import '../utils/ui_utils.dart';

// Component Imports
import '../widgets/loading_view.dart';
import '../widgets/error_view.dart';

// Handler Imports
import '../bridge/handlers/location_handler.dart';
import '../bridge/handlers/image_handler.dart';
import '../bridge/handlers/scan_handler.dart';
import '../bridge/handlers/settings_handler.dart';
import '../bridge/handlers/system_handler.dart';
import '../bridge/handlers/storage_handler.dart';
import '../bridge/handlers/clipboard_handler.dart';
import '../bridge/handlers/ui_handler.dart';
import '../bridge/handlers/network_handler.dart';
import '../bridge/handlers/nav_handler.dart';
import '../bridge/handlers/auth_handler.dart';
import '../bridge/handlers/biometric_handler.dart';
import '../bridge/handlers/file_handler.dart';
import '../bridge/handlers/device_handler.dart';
import 'package:flutter/material.dart';

/**
 * Trang WebView chứa nội dung Mini App.
 * Xử lý việc hiển thị, Bridge, và các sự kiện hệ thống.
 */
class MiniAppWebView extends StatefulWidget {
  final String url;
  final String? title;
  final bool? showAppBar;
  const MiniAppWebView({super.key, required this.url, this.title, this.showAppBar});

  @override
  State<MiniAppWebView> createState() => _MiniAppWebViewState();
}

class _MiniAppWebViewState extends State<MiniAppWebView>
    with WidgetsBindingObserver {
  late final WebViewController _controller;
  late final BridgeManager _bridgeManager;

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Trạng thái cấu hình Navigation Bar
  late bool _showAppBar;
  bool _isImmersive = false;
  late String _appBarTitle;
  Color _appBarBgColor = const Color(0xFF5856D6);
  String _appBarBgColorStr = '#5856d6';
  Color _appBarTextColor = Colors.white;
  String _backIcon = 'arrow';

  // Điều hướng từ xa (NavSync)
  WebSocket? _navSyncWs;
  Timer? _navSyncRetryTimer;
  bool _isRemoteNavigating = false;

  // Xác nhận thoát
  bool _confirmExit = false;
  String _confirmExitMessage = 'Bạn có chắc chắn muốn thoát?';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _showAppBar = widget.showAppBar ?? false;
    _appBarTitle = widget.title ?? '';
    _initWebView();
    _initBridge();
    _connectNavSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _navSyncRetryTimer?.cancel();
    _navSyncWs?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Gửi sự kiện onAppStatusChange về phía Web khi trạng thái thay đổi
    _bridgeManager.sendEvent('onAppStatusChange', {
      'status': state.name
          .toLowerCase(), // 'active', 'inactive', 'paused', 'detached'
    });
    NativeLogger.info('App Lifecycle State: ${state.name}');
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'EjscBridge',
        onMessageReceived: (message) =>
            _bridgeManager.handleMessage(context, message.message),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _isLoading = true;
            _hasError = false;
          }),
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            _syncNavBar();
            BridgeInjector.injectCore(_controller);
          },
          onWebResourceError: (error) => setState(() {
            _hasError = true;
            _isLoading = false;
            _errorMessage = error.description;
          }),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _initBridge() {
    _bridgeManager = BridgeManager(_controller);
    NativeLogger.init(_bridgeManager);
    _registerAllHandlers();

    // Gửi log từ Native về máy tính qua WebSocket nếu đang kết nối
    NativeLogger.onLog = (msg) {
      if (_navSyncWs?.readyState == WebSocket.open) {
        _navSyncWs!.add(
          jsonEncode({
            'eventName': 'native_log',
            'data': {
              'message': msg,
              'level': msg.contains('Error') ? 'error' : 'info',
            },
          }),
        );
      }
    };
  }

  void _registerAllHandlers() {
    _bridgeManager.register(LocationBridgeHandler());
    _bridgeManager.register(GetUserLocationHandler());
    _bridgeManager.register(OpenNativeMapHandler());
    _bridgeManager.register(ImageBridgeHandler());
    _bridgeManager.register(CaptureImageHandler());
    _bridgeManager.register(MediaBridgeHandler());
    _bridgeManager.register(PreviewImageHandler());
    _bridgeManager.register(SaveImageHandler());
    _bridgeManager.register(GetImageInfoHandler());
    _bridgeManager.register(CompressImageHandler());
    _bridgeManager.register(ScanBridgeHandler());
    _bridgeManager.register(SettingsBridgeHandler());
    _bridgeManager.register(AuthorizeBridgeHandler());
    _bridgeManager.register(OpenSettingBridgeHandler());
    _bridgeManager.register(OpenAppSettingBridgeHandler());
    _bridgeManager.register(OpenNativeStoreBridgeHandler());

    // Handler đặc biệt để cập nhật UI Navigation Bar
    _bridgeManager.register(
      SetNavigationBarHandler(
        onTitleChanged: (t) => setState(() {
          _appBarTitle = t;
          _syncNavBar();
        }),
        onBgColorChanged: (c) => setState(() {
          _appBarBgColor = c;
          _syncNavBar();
        }),
        onBgColorStrChanged: (s) => setState(() {
          _appBarBgColorStr = s;
        }),
        onTextColorChanged: (c) => setState(() {
          _appBarTextColor = c;
          _syncNavBar();
        }),
        onVisibleChanged: (v) => setState(() {
          _showAppBar = v;
          _syncNavBar();
        }),
        onImmersiveChanged: (i) => setState(() {
          _isImmersive = i;
          _syncNavBar();
        }),
        onBackIconChanged: (i) => setState(() {
          _backIcon = i;
          _syncNavBar();
        }),
      ),
    );

    _bridgeManager.register(
      ExitBridgeHandler(
        onExit: () async {
          if (await _requestExitConfirmation()) Navigator.pop(context);
        },
      ),
    );

    _bridgeManager.register(SystemInfoBridgeHandler());
    _bridgeManager.register(
      ConfirmBeforeExitHandler(
        onUpdate: (e, m) => setState(() {
          _confirmExit = e;
          _confirmExitMessage = m;
        }),
      ),
    );

    _bridgeManager.register(SetClipboardHandler());
    _bridgeManager.register(GetClipboardHandler());
    _bridgeManager.register(ToastHandler());
    _bridgeManager.register(AlertHandler());
    _bridgeManager.register(ConfirmHandler());
    _bridgeManager.register(PromptHandler());
    _bridgeManager.register(ActionSheetHandler());
    _bridgeManager.register(LoadingHandler());
    _bridgeManager.register(HideLoadingHandler());
    _bridgeManager.register(RequestHandler());
    _bridgeManager.register(OpenPublicDeepLinkHandler());
    _bridgeManager.register(OpenNativeWindowHandler());
    _bridgeManager.register(ShareAppHandler());
    _bridgeManager.register(GetUserInfoHandler());
    _bridgeManager.register(GetAuthCodeHandler());
    _bridgeManager.register(BiometricBridgeHandler());
    _bridgeManager.register(DownloadFileHandler());
    _bridgeManager.register(UploadFileHandler());
    _bridgeManager.register(MakePhoneCallHandler());
    _bridgeManager.register(ChoosePhoneContactHandler());
    _bridgeManager.register(AddCalendarEventHandler());
    _bridgeManager.register(TriggerHapticFeedbackHandler());
    _bridgeManager.register(OpenInAppBrowserHandler());
    _bridgeManager.register(SetStorageHandler());
    _bridgeManager.register(GetStorageHandler());
    _bridgeManager.register(SetSecureStorageHandler());
    _bridgeManager.register(GetSecureStorageHandler());
    _bridgeManager.register(RemoveStorageHandler());
    _bridgeManager.register(ClearStorageHandler());
    _bridgeManager.register(GetStorageInfoHandler());
  }

  void _syncNavBar() {
    BridgeInjector.syncNavigationBar(
      _controller,
      title: _appBarTitle,
      bgColorStr: _appBarBgColorStr,
      textColor: _appBarTextColor,
      visible: _showAppBar,
      immersive: _isImmersive,
      backIcon: _backIcon,
    );
  }

  Future<void> _connectNavSync() async {
    try {
      final host = Uri.parse(widget.url).host;
      _navSyncWs = await WebSocket.connect('ws://$host:8085?role=sender');

      // Gửi thông tin thiết bị khi kết nối thành công
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final ratio = view.devicePixelRatio;
      final size = view.physicalSize / ratio;
      _navSyncWs!.add(
        jsonEncode({
          'eventName': 'device_info',
          'data': {
            'platform': Platform.operatingSystem,
            'screenWidth': size.width,
            'screenHeight': size.height,
          },
        }),
      );

      _navSyncWs!.listen((msg) {
        final payload = jsonDecode(msg);
        if (payload['eventName'] == 'remote_navigate' && !_isRemoteNavigating) {
          final path = (payload['data']?['hash'] as String? ?? '').replaceFirst(
            '#',
            '',
          );
          _isRemoteNavigating = true;
          _controller.runJavaScript(
            "if(window.__ejsc_navigate) window.__ejsc_navigate('$path'); else window.location.hash = '#$path';",
          );
          Future.delayed(
            const Duration(milliseconds: 500),
            () => _isRemoteNavigating = false,
          );
        }
      }, onDone: _retryConnectNavSync);
    } catch (_) {
      _retryConnectNavSync();
    }
  }

  void _retryConnectNavSync() {
    _navSyncRetryTimer?.cancel();
    _navSyncRetryTimer = Timer(const Duration(seconds: 5), _connectNavSync);
  }

  Future<bool> _requestExitConfirmation() async {
    if (!_confirmExit) return true;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận thoát'),
        content: Text(_confirmExitMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ở lại'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
    return res == true;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => BridgeInjector.injectSafeAreas(_controller, context),
    );

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: _isImmersive ? Colors.transparent : Colors.black12,
        statusBarIconBrightness: _appBarTextColor == Colors.white
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: _isImmersive,
      appBar: (_showAppBar && !_isLoading) ? _buildAppBar() : null,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop && await _requestExitConfirmation() && mounted)
            Navigator.of(context).pop();
        },
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_hasError)
              ConnectionErrorView(
                errorMessage: _errorMessage,
                onRetry: () {
                  setState(() {
                    _hasError = false;
                    _isLoading = true;
                  });
                  _controller.reload();
                },
                onBack: () => Navigator.pop(context),
              ),
            if (_isLoading) const MiniAppLoadingView(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 46,
      title: Text(
        _appBarTitle,
        style: TextStyle(
          color: _appBarTextColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: _backIcon == 'none'
          ? null
          : IconButton(
              icon: Icon(
                _backIcon == 'close'
                    ? Icons.close
                    : (_backIcon == 'exit'
                          ? Icons.logout
                          : Icons.arrow_back_ios_new),
                color: _appBarTextColor,
                size: 20,
              ),
              onPressed: () async {
                if (_backIcon == 'exit') {
                  if (await _requestExitConfirmation()) Navigator.pop(context);
                  return;
                }
                _controller.runJavaScript(
                  "window.dispatchEvent(new CustomEvent('nav:back'))",
                );
              },
            ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: UIUtils.getGradientFromCSS(_appBarBgColorStr),
          color: UIUtils.getGradientFromCSS(_appBarBgColorStr) == null
              ? _appBarBgColor
              : null,
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }
}
