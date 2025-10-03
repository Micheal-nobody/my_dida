import 'package:flutter/foundation.dart';
import '../config/logger.dart';

/// 通用Provider基类，提取Provider中的重复逻辑
abstract class BaseProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  /// 获取加载状态
  bool get isLoading => _isLoading;

  /// 获取错误信息
  String? get errorMessage => _errorMessage;

  /// 是否有错误
  bool get hasError => _errorMessage != null;

  /// 设置加载状态
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// 设置错误信息
  void setError(String? error) {
    if (_errorMessage != error) {
      _errorMessage = error;
      notifyListeners();
    }
  }

  /// 清除错误
  void clearError() {
    setError(null);
  }

  /// 执行异步操作的通用方法
  Future<T?> executeAsync<T>(
    Future<T> Function() operation, {
    String? errorMessage,
    bool showLoading = true,
    bool clearErrorOnStart = true,
  }) async {
    try {
      if (clearErrorOnStart) clearError();
      if (showLoading) setLoading(true);

      final result = await operation();
      return result;
    } catch (e) {
      logger.e('Provider operation failed: $e');
      setError(errorMessage ?? e.toString());
      return null;
    } finally {
      if (showLoading) setLoading(false);
    }
  }

  /// 执行异步操作并通知监听器
  Future<bool> executeAsyncWithNotification(
    Future<void> Function() operation, {
    String? errorMessage,
    bool showLoading = true,
    bool clearErrorOnStart = true,
  }) async {
    try {
      if (clearErrorOnStart) clearError();
      if (showLoading) setLoading(true);

      await operation();
      return true;
    } catch (e) {
      logger.e('Provider operation failed: $e');
      setError(errorMessage ?? e.toString());
      return false;
    } finally {
      if (showLoading) setLoading(false);
    }
  }

  /// 安全地通知监听器（检查是否已销毁）
  void safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
