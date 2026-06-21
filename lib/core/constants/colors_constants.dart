import 'package:flutter/material.dart';

/// Color constants for consistent theming
class AppColors {
  // Primary colors
  static const Color primary = Colors.blue;
  static const Color primaryLight = Color(0xFFE3F2FD);
  static const Color primaryDark = Color(0xFF1976D2);

  // Status colors
  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color warning = Colors.orange;
  static const Color info = Colors.blue;

  // Background colors
  static const Color background = Colors.white;
  static const Color surface = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;

  // Text colors
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
  static const Color textDisabled = Colors.black38;
  static const Color textOnPrimary = Colors.white;

  // Border colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFBDBDBD);

  // Gradient colors
  static final LinearGradient primaryGradient = LinearGradient(
    colors: [Colors.blue.shade50, Colors.blue.shade100],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 预定义的选择器颜色列表（用于清单、标签等）
  static const List<Color> selectorColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  /// 获取颜色的十六进制字符串表示
  static String colorToHex(Color color) =>
      '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';

  /// 从十六进制字符串创建颜色
  static Color colorFromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// 获取颜色的对比色（用于文本显示）
  static Color getContrastColor(Color color) {
    // 计算亮度
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
