import 'package:flutter/material.dart';

extension ColorUtil on Color{
  Color get lighter => withValues(alpha: 1.5);

  Color get darker => withValues(alpha: 0.6);
}

class ColorUtils {

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