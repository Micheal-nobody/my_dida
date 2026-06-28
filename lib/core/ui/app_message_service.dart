import 'package:flutter/material.dart';

enum AppMessageType {
  success,
  error,
  info,
  warning;

  Color get color {
    switch (this) {
      case AppMessageType.success:
        return Colors.green;
      case AppMessageType.error:
        return Colors.red;
      case AppMessageType.warning:
        return Colors.orange;
      case AppMessageType.info:
        return Colors.grey;
    }
  }
}

class AppMessageService {
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  void show(
    String message, {
    required AppMessageType type,
    Duration duration = const Duration(seconds: 2),
  }) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null || message.trim().isEmpty) {
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: type.color,
        ),
      );
  }

  void showSuccess(String message, {Duration? duration}) {
    show(
      message,
      type: AppMessageType.success,
      duration: duration ?? const Duration(seconds: 2),
    );
  }

  void showError(String message, {Duration? duration}) {
    show(
      message,
      type: AppMessageType.error,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  void showInfo(String message, {Duration? duration}) {
    show(
      message,
      type: AppMessageType.info,
      duration: duration ?? const Duration(seconds: 2),
    );
  }

  void showWarning(String message, {Duration? duration}) {
    show(
      message,
      type: AppMessageType.warning,
      duration: duration ?? const Duration(seconds: 2),
    );
  }
}
