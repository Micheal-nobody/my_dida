/// 通用表单验证器
class FormValidators {
  /// 验证必填字段
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '请输入${fieldName ?? '内容'}';
    }
    return null;
  }

  /// 验证名称字段（习惯名称、任务名称等）
  static String? name(String? value, {String? fieldName}) {
    final requiredResult = required(value, fieldName: fieldName);
    if (requiredResult != null) return requiredResult;

    if (value!.trim().length < 2) {
      return '${fieldName ?? '名称'}至少需要2个字符';
    }

    if (value.trim().length > 50) {
      return '${fieldName ?? '名称'}不能超过50个字符';
    }

    return null;
  }

  /// 验证数字范围
  static String? numberRange(
    int? value, {
    required int min,
    required int max,
    String? fieldName,
  }) {
    if (value == null) {
      return '请选择${fieldName ?? '数值'}';
    }

    if (value < min || value > max) {
      return '${fieldName ?? '数值'}必须在$min-$max之间';
    }

    return null;
  }

  /// 验证邮箱格式
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '请输入邮箱地址';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return '请输入有效的邮箱地址';
    }

    return null;
  }

  /// 验证密码强度
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入密码';
    }

    if (value.length < 6) {
      return '密码至少需要6个字符';
    }

    return null;
  }

  /// 组合验证器
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) => (value) {
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) return result;
    }
    return null;
  };
}
