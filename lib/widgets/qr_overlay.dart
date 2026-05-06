import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/**
 * Trang quét mã QR: Sử dụng camera để quét và nhận diện mã QR.
 */
class QrScannerPage extends StatefulWidget {
  final String title;
  final String hintText;
  final double scanAreaSize;

  const QrScannerPage({
    super.key, 
    this.title = 'Quét mã QR',
    this.hintText = 'Căn chỉnh mã QR vào giữa khung hình',
    this.scanAreaSize = 260.0,
  });

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  late MobileScannerController controller;
  bool _isPopped = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(widget.title),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Widget camera quét mã QR
          MobileScanner(
            controller: controller,
            onDetect: (cap) {
              if (_isPopped) return;
              if (cap.barcodes.isNotEmpty) {
                final code = cap.barcodes.first.rawValue;
                if (code != null) {
                  _isPopped = true;
                  // Trả về kết quả mã quét được
                  Navigator.pop(context, code);
                }
              }
            },
          ),
          // Lớp phủ (Overlay) tạo khung quét
          QrScannerOverlay(size: widget.scanAreaSize),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.hintText,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/**
 * Lớp phủ tạo hiệu ứng làm mờ xung quanh và khung ngắm ở giữa.
 */
class QrScannerOverlay extends StatelessWidget {
  final double size;
  const QrScannerOverlay({super.key, this.size = 260.0});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Tạo lớp phủ mờ với vùng cắt (cutout) ở giữa
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.6),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Vẽ 4 góc khung ngắm
        Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _CornerBorderPainter(),
            ),
          ),
        ),
      ],
    );
  }
}

/**
 * CustomPainter để vẽ các đường bo góc cho khung quét QR.
 */
class _CornerBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1460C1) // Màu xanh thương hiệu EJSC
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double radius = 30.0;
    const double length = 40.0;

    final path = Path();

    // Góc trên bên trái
    path.moveTo(0, length);
    path.lineTo(0, radius);
    path.arcToPoint(
      const Offset(radius, 0),
      radius: const Radius.circular(radius),
    );
    path.lineTo(length, 0);

    // Góc trên bên phải
    path.moveTo(size.width - length, 0);
    path.lineTo(size.width - radius, 0);
    path.arcToPoint(
      Offset(size.width, radius),
      radius: const Radius.circular(radius),
    );
    path.lineTo(size.width, length);

    // Góc dưới bên phải
    path.moveTo(size.width, size.height - length);
    path.lineTo(size.width, size.height - radius);
    path.arcToPoint(
      Offset(size.width - radius, size.height),
      radius: const Radius.circular(radius),
    );
    path.lineTo(size.width - length, size.height);

    // Góc dưới bên trái
    path.moveTo(length, size.height);
    path.lineTo(radius, size.height);
    path.arcToPoint(
      Offset(0, size.height - radius),
      radius: const Radius.circular(radius),
    );
    path.lineTo(0, size.height - length);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
