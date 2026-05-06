import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/material.dart';

/**
 * Quản lý việc tiêm (inject) các đoạn mã JavaScript vào WebView 
 * để thiết lập môi trường Bridge và đồng bộ giao diện.
 */
class BridgeInjector {
  /**
   * Inject mã nguồn Core của Bridge vào WebView.
   * Định nghĩa đối tượng window.ejsc và các phương thức giao tiếp Native.
   */
  static void injectCore(WebViewController controller) {
    const String script = """
      (function() {
        /** Hệ thống callback để khớp nối Promise */
        const callbacks = {};
        let callbackId = 0;

        window.ejsc = {
          /** Xử lý phản hồi từ Native gửi về Web */
          _onNativeResponse: (id, res) => {
            const cb = callbacks[id];
            if (cb) {
              if (res && res.success) {
                if (cb.success) cb.success(res.data);
                cb.resolve(res.data);
              } else {
                const errorData = res?.data || 'Unknown error';
                if (cb.fail) cb.fail(errorData);
                cb.reject(errorData);
              }
              if (cb.complete) cb.complete(res?.data);
              delete callbacks[id];
            }
          },

          /** Xử lý sự kiện chủ động từ Native (Event Emitter) */
          _onNativeEvent: (eventName, data) => {
             const event = new CustomEvent('ejsc:native-event', { detail: { eventName, data } });
             window.dispatchEvent(event);
          },

          /** Hàm gốc để gọi lệnh từ Web sang Native thông qua JavascriptChannel */
          _invokeNative: (method, opts) => {
            return new Promise((resolve, reject) => {
              const id = callbackId++;
              callbacks[id] = { ...opts, resolve, reject };
              window.EjscBridge.postMessage(JSON.stringify({method, id, params: opts || {}}));
            });
          }
        };

        // Đăng ký danh sách các API hỗ trợ
        const methods = [
          'getLocation', 'getUserLocation', 'openNativeMap',
          'chooseImage', 'captureImage', 'chooseMedia', 
          'scan', 'getSetting', 'authorize', 'openSetting', 'exitMiniApp', 'getSystemInfo', 
          'setStorage', 'getStorage', 'setSecureStorage', 'getSecureStorage', 
          'removeStorage', 'clearStorage', 'getStorageInfo', 
          'setClipboard', 'getClipboard', 
          'showToast', 'alert', 'confirm', 'prompt', 'showActionSheet', 'showLoading', 'hideLoading', 
          'request', 'openInAppBrowser', 'triggerHapticFeedback',
          'setNavigationBar', 'getUserInfo', 'getAuthCode', 
          'downloadFile', 'uploadFile', 'makePhoneCall', 'choosePhoneContact', 
          'addCalendarEvent', 'openDeeplink', 'openPublicDeepLink', 
          'shareApp', 'previewImage', 'saveImage', 'getImageInfo'
        ];        
        methods.forEach(m => {
          window.ejsc[m] = (opts) => window.ejsc._invokeNative(m, opts);
        });

        // Alias để tương thích ngược
        window.ejscAsync = window.ejsc;

        // Cấu trúc lồng nhau cho Biometric
        window.ejsc.bioMetrics = {
          isSupported: (opts) => window.ejsc._invokeNative('bioMetrics', { ...opts, action: 'isSupported' }),
          localAuth: (opts) => window.ejsc._invokeNative('bioMetrics', { ...opts, action: 'localAuth' }),
          keyExists: (opts) => window.ejsc._invokeNative('bioMetrics', { ...opts, action: 'keyExists' }),
          createKey: (opts) => window.ejsc._invokeNative('bioMetrics', { ...opts, action: 'createKey' }),
          createSignature: (opts) => window.ejsc._invokeNative('bioMetrics', { ...opts, action: 'createSignature' }),
          deleteKey: (opts) => window.ejsc._invokeNative('bioMetrics', { ...opts, action: 'deleteKey' }),
        };
      })();
    """;
    controller.runJavaScript(script);
  }

  /**
   * Đồng bộ trạng thái Navigation Bar của Native xuống phía Web (React Router).
   */
  static void syncNavigationBar(
    WebViewController controller, {
    required String title,
    required String bgColorStr,
    required Color textColor,
    required bool visible,
    required bool immersive,
    required String backIcon,
  }) {
    final jsCode = """
      window.dispatchEvent(new CustomEvent('mock:setNavigationBar', {
        detail: {
          title: '$title',
          backgroundColor: '$bgColorStr',
          frontColor: '#${textColor.value.toRadixString(16).substring(2)}',
          visible: $visible,
          immersive: $immersive,
          backIcon: '$backIcon'
        }
      }));
    """;
    controller.runJavaScript(jsCode);
  }

  /**
   * Tiêm các biến CSS Safe Area (biến môi trường) vào trình duyệt 
   * để giao diện Web có thể né các phần tai thỏ, status bar.
   */
  static void injectSafeAreas(WebViewController controller, BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final double bottomHeight = MediaQuery.of(context).padding.bottom;

    final jsCode = """
      document.documentElement.style.setProperty('--safe-top', '${statusBarHeight}px');
      document.documentElement.style.setProperty('--safe-bottom', '${bottomHeight}px');
    """;
    controller.runJavaScript(jsCode);
  }
}
