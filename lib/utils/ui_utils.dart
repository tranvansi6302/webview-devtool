import 'package:flutter/material.dart';

/**
 * Các hàm tiện ích xử lý giao diện (UI) và chuyển đổi dữ liệu từ Web/CSS.
 */
class UIUtils {
  /**
   * Phân tích chuỗi CSS linear-gradient và chuyển đổi thành Flutter Gradient.
   * Hỗ trợ các mã màu Hex (3, 6, 8 ký tự).
   */
  static Gradient? getGradientFromCSS(String css) {
    if (!css.contains('linear-gradient')) return null;

    try {
      // RegExp mạnh mẽ để bắt mã Hex (3, 6, hoặc 8 ký tự)
      final regExp = RegExp(r'#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3}|[A-Fa-f0-9]{8})');
      final matches = regExp.allMatches(css);

      final List<Color> colors = [];
      for (var match in matches) {
        colors.add(parseHexColor(match.group(0)!));
      }

      if (colors.length >= 2) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        );
      }
    } catch (e) {
      debugPrint('Lỗi khi phân tích Gradient CSS: $e');
    }
    return null;
  }

  /**
   * Chuyển đổi mã màu Hex (chuỗi) sang đối tượng Color của Flutter.
   * Chấp nhận các định dạng #RGB, #RRGGBB, #AARRGGBB.
   */
  static Color parseHexColor(String hex) {
    hex = hex.toUpperCase().replaceAll('#', '');
    if (hex.length == 3) {
      // Chuyển #ABC thành #AABBCC
      hex = hex.split('').map((c) => '$c$c').join('');
    }
    if (hex.length == 6) {
      hex = 'FF$hex'; // Thêm Alpha mặc định là FF (opaque)
    }
    return Color(int.parse(hex, radix: 16));
  }
}
