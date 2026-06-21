import 'package:flutter/material.dart';

class BaseBottomSheetLayout extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onReset;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Color confirmButtonColor;
  final String confirmText;
  final String cancelText;
  final bool expandChild;
  final bool useFullWidthButtons;

  const BaseBottomSheetLayout({
    required this.title,
    required this.child,
    this.onReset,
    this.onConfirm,
    this.onCancel,
    this.confirmButtonColor = Colors.orange,
    this.confirmText = '确定',
    this.cancelText = '取消',
    this.expandChild = false,
    this.useFullWidthButtons = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget header = Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          Center(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (onReset != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onReset,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('重置'),
              ),
            ),
        ],
      ),
    );

    Widget content = child;
    if (expandChild) {
      content = Expanded(child: child);
    }

    Widget? bottomBar;
    if (onConfirm != null) {
      final cancelPressed = onCancel ?? () => Navigator.pop(context);
      if (useFullWidthButtons) {
        bottomBar = Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: cancelPressed,
                  child: Text(cancelText),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmButtonColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onConfirm,
                  child: Text(confirmText),
                ),
              ),
            ],
          ),
        );
      } else {
        bottomBar = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: cancelPressed,
                child: Text(
                  cancelText,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmButtonColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  confirmText,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        );
      }
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const Divider(height: 1),
          content,
          if (bottomBar != null) ...[
            const Divider(height: 1),
            bottomBar,
          ],
        ],
      ),
    );
  }
}
