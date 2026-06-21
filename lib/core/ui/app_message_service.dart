import 'package:flutter/material.dart';
import 'package:my_dida/core/constants/colors_constants.dart';

import 'app_message_type.dart';

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
          backgroundColor: _backgroundColor(type),
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

  Color _backgroundColor(AppMessageType type) {
    switch (type) {
      case AppMessageType.success:
        return AppColors.success;
      case AppMessageType.error:
        return AppColors.error;
      case AppMessageType.info:
        return AppColors.info;
      case AppMessageType.warning:
        return AppColors.warning;
    }
  }
}
