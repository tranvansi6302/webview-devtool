import 'package:flutter/material.dart';

/**
 * Widget hiển thị màn hình Loading (Splash) khi Mini App đang tải dữ liệu.
 */
class MiniAppLoadingView extends StatelessWidget {
  const MiniAppLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hiệu ứng scale logo nhẹ nhàng
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.0),
              duration: const Duration(seconds: 1),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                final double opacity = ((value - 0.8) / 0.2).clamp(0.0, 1.0);
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: opacity,
                    child: Image.asset(
                      'lib/images/logo.png',
                      width: 100,
                      height: 100,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            const Text(
              'EJSC DEVTOOL',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đang tải dữ liệu...',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 40),
            // Thanh tiến trình Linear mảnh theo phong cách hiện đại
            SizedBox(
              width: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  backgroundColor: Color(0xFFF2F2F7),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
                  minHeight: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
