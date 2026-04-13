import 'package:flutter/material.dart';
import 'package:my_dida/utils/TimeUtils.dart';

/// 通用UI组件工具类，提取重复的UI组件
class CommonWidgets {
  /// 创建标准的文本输入框
  static Widget buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines = 1,
    bool enabled = true,
    Widget? suffixIcon,
    void Function(String)? onChanged,
  }) => TextFormField(
    controller: controller,
    decoration: InputDecoration(
      labelText: labelText,
      hintText: hintText ?? '请输入$labelText',
      border: const OutlineInputBorder(),
      suffixIcon: suffixIcon,
    ),
    validator: validator,
    keyboardType: keyboardType,
    maxLines: maxLines,
    enabled: enabled,
    onChanged: onChanged,
  );

  /// 创建图标选择器
  static Widget buildIconSelector({
    required List<Map<String, dynamic>> icons,
    required String selectedIcon,
    required void Function(String) onIconSelected,
    double iconSize = 50,
    Color? selectedColor,
    Color? unselectedColor,
  }) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: icons.map((iconData) {
      final isSelected = selectedIcon == iconData['name'];
      return GestureDetector(
        onTap: () => onIconSelected(iconData['name']),
        child: Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: isSelected
                ? (selectedColor ?? Colors.blue)
                : (unselectedColor ?? Colors.grey[200]),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? (selectedColor ?? Colors.blue) : Colors.grey,
              width: 2,
            ),
          ),
          child: Icon(
            iconData['icon'],
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      );
    }).toList(),
  );

  /// 创建颜色选择器
  static Widget buildColorSelector({
    required List<Color> colors,
    required Color selectedColor,
    required void Function(Color) onColorSelected,
    double colorSize = 40,
  }) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: colors.map((color) {
      final isSelected = selectedColor == color;
      return GestureDetector(
        onTap: () => onColorSelected(color),
        child: Container(
          width: colorSize,
          height: colorSize,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isSelected ? Border.all(width: 3) : null,
          ),
        ),
      );
    }).toList(),
  );

  /// 创建时间选择按钮
  static Widget buildTimeSelector({
    required TimeOfDay selectedTime,
    required void Function() onTap,
    String? label,
  }) => Row(
    children: [
      if (label != null) Text('$label: '),
      TextButton(
        onPressed: onTap,
        child: Text(
          DateTimeUtils.formatTime(selectedTime),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    ],
  );

  /// 创建数值滑块
  static Widget buildNumberSlider({
    required String label,
    required int value,
    required int min,
    required int max,
    required void Function(int) onChanged,
    int? divisions,
  }) => Row(
    children: [
      Text('$label: '),
      Expanded(
        child: Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: divisions ?? (max - min),
          label: value.toString(),
          onChanged: (newValue) => onChanged(newValue.round()),
        ),
      ),
      Text(
        value.toString(),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ],
  );

  /// 创建标准的加载指示器
  static Widget buildLoadingIndicator({String? message, double size = 20}) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(fontSize: 12)),
          ],
        ],
      );

  /// 创建空状态显示
  static Widget buildEmptyState({
    required String message,
    IconData? icon,
    Widget? action,
  }) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
        ],
        Text(
          message,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        if (action != null) ...[const SizedBox(height: 16), action],
      ],
    ),
  );

  /// 创建错误状态显示
  static Widget buildErrorState({
    required String message,
    VoidCallback? onRetry,
  }) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
        const SizedBox(height: 16),
        Text(
          message,
          style: TextStyle(fontSize: 16, color: Colors.red[600]),
          textAlign: TextAlign.center,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ],
    ),
  );

  /// 创建标准的分隔线
  static Widget buildDivider({
    double height = 16,
    double thickness = 1,
    Color? color,
  }) => Divider(
    height: height,
    thickness: thickness,
    color: color ?? Colors.grey[300],
  );

  /// 创建标准的间距
  static Widget buildSpacing({double height = 16, double width = 16}) =>
      SizedBox(height: height, width: width);
}
