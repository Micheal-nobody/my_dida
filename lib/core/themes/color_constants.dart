import 'package:flutter/material.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/ui/app_message_service.dart';
import 'package:provider/provider.dart';

/// ColorTheme interface/base class with default values
abstract class ColorTheme {
  // Primary colors
  Color get primary => Colors.blue;
  Color get primaryLight => const Color(0xFFE3F2FD);
  Color get primaryDark => const Color(0xFF1976D2);

  // Status colors
  Color get success => Colors.green;
  Color get error => Colors.red;
  Color get warning => Colors.orange;
  Color get info => Colors.blue;

  // Background colors
  Color get background => Colors.white;
  Color get surface => const Color(0xFFF5F5F5);
  Color get cardBackground => Colors.white;

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