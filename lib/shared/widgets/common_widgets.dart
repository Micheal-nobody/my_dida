import 'package:flutter/material.dart';
import 'package:my_dida/core/utils/time_utils.dart';

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

  /// 创建标准的间距
  static Widget buildSpacing({double height = 16, double width = 16}) =>
      SizedBox(height: height, width: width);
}
