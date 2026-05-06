import 'package:flutter/material.dart';

/**
 * Widget hiển thị màn hình thông báo lỗi khi không thể kết nối tới Mini App.
 */
class ConnectionErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const ConnectionErrorView({
    super.key,
    required this.errorMessage,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 80,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 24),
          const Text(
            'Kết nối thất bại',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Không thể kết nối tới máy chủ. Vui lòng kiểm tra lại địa chỉ IP và Cổng kết nối.\n\nChi tiết: $errorMessage',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          // Nút quay lại trang chủ
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1460C1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Quay lại & Chỉnh sửa',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Nút thử tải lại trang hiện tại
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1460C1),
            ),
            child: const Text(
              'Thử lại',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
