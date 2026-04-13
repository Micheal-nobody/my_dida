import 'package:flutter/material.dart';

/// 通用表单对话框基类，提取对话框的通用逻辑
abstract class BaseFormDialog extends StatefulWidget {
  const BaseFormDialog({super.key});
}

abstract class BaseFormDialogState<T extends BaseFormDialog> extends State<T> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool isLoading = false;

  /// 对话框标题
  String get dialogTitle;

  /// 确认按钮文本
  String get confirmButtonText => '确认';

  /// 取消按钮文本
  String get cancelButtonText => '取消';

  /// 对话框内容高度比例（相对于屏幕高度）
  double get contentHeightRatio => 0.6;

  /// 构建表单内容
  Widget buildFormContent(BuildContext context);

  /// 验证表单并执行保存操作
  Future<void> onConfirm();

  /// 设置加载状态
  void setLoading(bool loading) {
    if (mounted) {
      setState(() {
        isLoading = loading;
      });
    }
  }

  /// 显示错误消息
  void showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  /// 显示成功消息
  void showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
    }
  }

  /// 执行确认操作
  Future<void> _handleConfirm() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setLoading(true);
    try {
      await onConfirm();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      showError('操作失败: $e');
    } finally {
      setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(dialogTitle),
    content: SizedBox(
      width: double.maxFinite,
      height: MediaQuery.of(context).size.height * contentHeightRatio,
      child: Form(
        key: formKey,
        child: SingleChildScrollView(child: buildFormContent(context)),
      ),
    ),
    actions: [
      TextButton(
        onPressed: isLoading ? null : () => Navigator.of(context).pop(),
        child: Text(cancelButtonText),
      ),
      ElevatedButton(
        onPressed: isLoading ? null : _handleConfirm,
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(confirmButtonText),
      ),
    ],
  );
}
