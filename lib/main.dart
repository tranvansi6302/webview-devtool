import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'screens/landing_screen.dart';

/**
 * Điểm khởi đầu của ứng dụng EJSC DevTool.
 * Thực hiện cấu hình giao diện hệ thống và các plugin cơ bản.
 */
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Cấu hình thanh trạng thái (Status Bar) mặc định
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Cấu hình plugin EasyLoading (thông báo/loading toàn cục)
  _configureEasyLoading();

  runApp(const MyApp());
}

void _configureEasyLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.ripple
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorSize = 45.0
    ..radius = 16.0
    ..progressColor = Colors.indigo
    ..backgroundColor = Colors.white.withOpacity(0.9)
    ..indicatorColor = Colors.indigo
    ..textColor = Colors.indigo
    ..maskType = EasyLoadingMaskType.black
    ..userInteractions = false
    ..dismissOnTap = false;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EJSC DevTool',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1460C1),
        // Sử dụng font Inter cho toàn bộ ứng dụng
        textTheme: GoogleFonts.interTextTheme(),
      ),
      // Màn hình khởi đầu là LandingPage
      home: const LandingPage(),
      // Khởi tạo EasyLoading
      builder: EasyLoading.init(),
    );
  }
}
