import 'package:flutter/material.dart';

mixin LightTheme{
  // Background colors
  Color get background => Colors.white;
  Color get surface => const Color(0xFFF5F5F5);

  // taskCard Color
  Color get cardBackground => Colors.white;
  Color get cardTagBackground => Colors.grey[200]!;
  Color get cardTagLabel => Colors.grey;

  // Dialog Color
  Color get dialogConfirm => Colors.black;
  Color get dialogCancel => Colors.grey;
  Color get deleteButton => Colors.red;
}

// enum TaskPriority 中已内置，此处废弃
mixin PriorityTheme {
  Color get highPriority => Colors.red;
  Color get mediumPriority => Colors.orange;
  Color get lowPriority => Colors.blue;
  Color get nonePriority => Colors.grey;
}


/// ColorTheme interface/base class with default values
abstract class ColorTheme with LightTheme{

  // Primary colors
  Color get primary => Colors.orange;

  // Status colors
  Color get success => Colors.green;
  Color get error => Colors.red;
  Color get warning => Colors.orange;
  Color get info => Colors.grey;

  // 动态 colors
  Color get selectedColor => Colors.orange;
  Color get unselectedLabelColor => Colors.grey;
  Color get iconColor => Colors.orange;
  @override
  Color get dialogConfirm => Colors.orange;

  // Text colors
  Color get textPrimary => Colors.black87;
  Color get textSecondary => Colors.black54;
  Color get textDisabled => Colors.black38;
  Color get textOnPrimary => Colors.white;

  // Border colors
  Color get border => const Color(0xFFE0E0E0);
  Color get divider => const Color(0xFFBDBDBD);

  // Gradient colors
  LinearGradient get primaryGradient => LinearGradient(
        colors: [Colors.blue.shade50, Colors.blue.shade100],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

/// Default theme implementation
class DefaultColorTheme extends ColorTheme {}