import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/qr_overlay.dart';
import 'miniapp_screen.dart';

/**
 * Trang chào mừng (Landing Page):
 * Nơi người dùng nhập địa chỉ IP hoặc quét mã QR để bắt đầu kết nối Mini App.
 */
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final TextEditingController _urlController = TextEditingController();
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _initUrl();
  }

  /** Khởi tạo URL từ bộ nhớ shared_preferences */
  Future<void> _initUrl() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedUrl = prefs.getString('mini_app_url');
    // Mặc định gợi ý IP cục bộ nếu chưa có dữ liệu
    _urlController.text = savedUrl ?? 'http://10.158.180.57:8080';
    _history = prefs.getStringList('mini_app_history') ?? [];
    setState(() {});
  }

  /** Mở màn hình WebView để truy cập Mini App */
  Future<void> _openMiniApp() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUrl = _urlController.text.trim();
    if (currentUrl.isNotEmpty) {
      await prefs.setString('mini_app_url', currentUrl);
      if (!_history.contains(currentUrl)) {
        _history.add(currentUrl);
        await prefs.setStringList('mini_app_history', _history);
      }
    }

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MiniAppWebView(url: currentUrl)),
    );
  }

  /** Xử lý quét mã QR để lấy địa chỉ IP */
  Future<void> _scanQRCode() async {
    PermissionStatus status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        if (!mounted) return;
        final openSettings = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cấp quyền truy cập'),
            content: const Text('Ứng dụng cần quyền sử dụng Camera để quét mã QR.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
              TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Mở Cài đặt')),
            ],
          ),
        ) ?? false;
        if (openSettings) await openAppSettings();
        return;
      }
    }

    if (!mounted) return;
    final String? scannedUrl = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerPage(title: 'Quét mã QR Network IP')),
    );

    if (scannedUrl != null && scannedUrl.isNotEmpty) {
      setState(() => _urlController.text = scannedUrl);
      _openMiniApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              // Header branding nhỏ phía trên
              _buildCompactHeader(),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('lib/images/logo.png', width: 70, height: 70),
                        const SizedBox(height: 16),
                        const Text(
                          'EJSC DEVTOOL',
                          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Môi trường phát triển Mini App',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 30),
                        _buildIpInputField(),
                        const SizedBox(height: 20),
                        _buildConnectButton(),
                        if (_history.isNotEmpty) _buildHistorySection(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(30)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset('lib/images/logo365.png', height: 22, fit: BoxFit.contain),
          Text('v1.0.0 • © 365Teams', style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildIpInputField() {
    return TextField(
      controller: _urlController,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: 'Network IP',
        suffixIcon: IconButton(
          icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF1460C1)),
          onPressed: _scanQRCode,
        ),
        hintText: 'http://192.168.1.x:8080',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
      ),
    );
  }

  Widget _buildConnectButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _openMiniApp,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1460C1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 4,
        ),
        child: const Text('Kết nối', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      children: [
        const SizedBox(height: 32),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Lịch sử kết nối', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600])),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8, runSpacing: 8,
            children: _history.reversed.map((url) {
              final displayUrl = url.replaceAll('http://', '').replaceAll('https://', '');
              return ActionChip(
                label: Text(displayUrl, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.grey[100],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onPressed: () => setState(() => _urlController.text = url),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
