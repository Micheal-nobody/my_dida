import 'package:flutter/material.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/model/vo/repeat_pattern.dart';
import 'package:my_dida/provider/task_provider.dart';
import 'package:my_dida/shared/widgets/datetime/custom_date_time_picker.dart';
import 'package:my_dida/utils/TimeUtils.dart';
import 'package:provider/provider.dart';

/// 专门用于处理 Task 对象的日期时间选择器包装器
///
/// 这个组件封装了 CustomDateTimePicker 的复杂逻辑，
/// 基于 TaskDetailPage 的正确实现，直接处理任务的持久化更新
class TaskDateTimePicker {
  static Future<void> showForTask({
    required BuildContext context,
    required Task task,
    VoidCallback? onUpdated,
  }) async {
    final initialTimeInfo = TaskTimeInfo.fromTask(task);
    final taskProvider = context.read<TaskProvider>();

    final result = await CustomDateTimePickerModal.show(
      context: context,
      initialValue: _toPickerValue(initialTimeInfo),
    );
    if (result == null) return;

    final timeInfo = _toTaskTimeInfo(result, fallback: initialTimeInfo);
    final startTime = timeInfo.getFinalStartTime();
    final endTime = timeInfo.getFinalEndTime();

    if (timeInfo.rrule != task.rrule) {
      await taskProvider.updateRRule(task, timeInfo.rrule);
    }
    await taskProvider.updateTimeRange(task, startTime, endTime);
    onUpdated?.call();
  }

  static Future<TaskTimeInfo?> showForNewTask({
    required BuildContext context,
    Task? initialTask,
    TaskTimeInfo? initialTimeInfo,
  }) async {
    final timeInfo = initialTimeInfo ?? TaskTimeInfo.fromTask(initialTask);

    final result = await CustomDateTimePickerModal.show(
      context: context,
      initialValue: _toPickerValue(timeInfo),
    );
    if (result == null) return null;

    return _toTaskTimeInfo(result, fallback: timeInfo);
  }

  /// 兼容性方法 - 保持向后兼容
  @Deprecated(
    'Use showForTask for existing tasks or showForNewTask for new tasks instead',
  )
  static Future<TaskTimeInfo?> show({
    required BuildContext context,
    required Function(TaskTimeInfo) onTaskUpdated,
    Task? task,
    VoidCallback? onClear,
  }) async {
    if (task != null) {
      await showForTask(context: context, task: task, onUpdated: onClear);
      return TaskTimeInfo.fromTask(task);
    } else {
      final timeInfo = await showForNewTask(context: context);
      if (timeInfo != null) {
        onTaskUpdated(timeInfo);
      }
      return timeInfo;
    }
  }

  static CustomDateTimePickerValue _toPickerValue(TaskTimeInfo timeInfo) =>
      CustomDateTimePickerValue(
        selectedDate: timeInfo.selectedDate,
        startTime: timeInfo.startTime,
        endTime: timeInfo.endTime,
        startDate: timeInfo.startDate ?? timeInfo.selectedDate,
        endDate: timeInfo.endDate ?? timeInfo.selectedDate,
        isAllDay: timeInfo.isAllDay,
        rrule: timeInfo.rrule,
        isTimeOnlyDate: timeInfo.isTimeOnlyDate,
      );

  static TaskTimeInfo _toTaskTimeInfo(
    CustomDateTimePickerValue value, {
    required TaskTimeInfo fallback,
  }) {
    DateTime? startDateTime;
    DateTime? endDateTime;

    if (value.startDate != null && value.startTime != null) {
      startDateTime = DateTime(
        value.startDate!.year,
        value.startDate!.month,
        value.startDate!.day,
        value.startTime!.hour,
        value.startTime!.minute,
      );
    }

    if (value.endDate != null && value.endTime != null) {
      endDateTime = DateTime(
        value.endDate!.year,
        value.endDate!.month,
        value.endDate!.day,
        value.endTime!.hour,
        value.endTime!.minute,
      );
    }

    return TaskTimeInfo(
      selectedDate: value.selectedDate,
      startTime: value.startTime,
      endTime: value.endTime,
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      isAllDay: value.isAllDay,
      rrule: value.rrule,
      startDate: value.startDate ?? fallback.startDate,
      endDate: value.endDate ?? fallback.endDate,
    );
  }
}

/// 任务时间信息封装类
///
/// 封装了任务相关的所有时间信息，简化了时间处理逻辑
class TaskTimeInfo {
  TaskTimeInfo({
    this.selectedDate,
    this.startTime,
    this.endTime,
    this.startDateTime,
    this.endDateTime,
    this.isAllDay = false,
    RepeatPattern? rrule,
    this.startDate,
    this.endDate,
  }) : rrule = rrule ?? const RepeatPattern.none();

  /// 从 Task 对象创建 TaskTimeInfo
  factory TaskTimeInfo.fromTask(Task? task) {
    if (task == null) {
      // 为新任务不设置默认时间，让用户主动选择
      final now = DateTime.now().toBeijingTime();
      return TaskTimeInfo(
        selectedDate: now.dateOnly,
        startTime: null, // 不设置默认时间
        endTime: null, // 不设置默认时间
      );
    }

    final DateTime selectedDate =
        task.startTime ?? DateTime.now().toBeijingTime().dateOnly;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    // 处理开始时间
    if (task.startTime != null) {
      if (task.startTime!.justDate()) {
        // 只有日期信息，不设置时间，让CalendarWidget显示"无"
        startTime = null;
      } else {
        startTime = TimeOfDay(
          hour: task.startTime!.hour,
          minute: task.startTime!.minute,
        );
      }
    }

    // 处理结束时间
    if (task.endTime != null && !task.endTime!.justDate()) {
      endTime = TimeOfDay(
        hour: task.endTime!.hour,
        minute: task.endTime!.minute,
      );
    }

    return TaskTimeInfo(
      selectedDate: selectedDate,
      startTime: startTime,
      endTime: endTime,
      startDateTime: task.startTime,
      endDateTime: task.endTime,
      rrule: task.rrule,
      startDate: task.startTime != null
          ? DateTime(
              task.startTime!.year,
              task.startTime!.month,
              task.startTime!.day,
            )
          : null,
      endDate: task.endTime != null
          ? DateTime(task.endTime!.year, task.endTime!.month, task.endTime!.day)
          : null,
    );
  }

  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  DateTime? startDateTime;
  DateTime? endDateTime;
  bool isAllDay;
  RepeatPattern rrule;

  // 独立的开始和结束日期（用于时间段模式）
  DateTime? startDate;
  DateTime? endDate;

  /// 是否只有日期（没有具体时间）
  bool get isTimeOnlyDate =>
      startDateTime != null &&
      startDateTime!.hour == 0 &&
      startDateTime!.minute == 0;

  /// 清除所有时间信息
  void clear() {
    selectedDate = DateTime.now().toBeijingTime().dateOnly;
    startTime = null;
    endTime = null;
    startDateTime = null;
    endDateTime = null;
    isAllDay = false;
    rrule = const RepeatPattern.none();
    startDate = null;
    endDate = null;
  }

  /// 获取最终的开始时间
  DateTime? getFinalStartTime() {
    // 优先使用完整的DateTime信息
    if (startDateTime != null) {
      return startDateTime;
    }

    // 使用独立的开始日期和时间
    if (startDate != null && startTime != null) {
      return DateTime(
        startDate!.year,
        startDate!.month,
        startDate!.day,
        startTime!.hour,
        startTime!.minute,
      );
    }

    // 回退到使用统一的日期和时间信息
    if (selectedDate != null && startTime != null) {
      return DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        startTime!.hour,
        startTime!.minute,
      );
    }

    // 如果只有独立开始日期，返回日期（时间为00:00）
    if (startDate != null) {
      return startDate;
    }

    // 如果只有日期，返回日期（时间为00:00）
    return selectedDate;
  }

  /// 获取最终的结束时间
  DateTime? getFinalEndTime() {
    // 优先使用完整的DateTime信息
    if (endDateTime != null) {
      return endDateTime;
    }

    // 使用独立的结束日期和时间
    if (endDate != null && endTime != null) {
      return DateTime(
        endDate!.year,
        endDate!.month,
        endDate!.day,
        endTime!.hour,
        endTime!.minute,
      );
    }

    // 回退到使用统一的日期和时间信息
    if (selectedDate != null && endTime != null) {
      return DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        endTime!.hour,
        endTime!.minute,
      );
    }

    return null;
  }

  /// 格式化显示文本
  String getDisplayText() {
    final start = getFinalStartTime();
    final end = getFinalEndTime();

    if (start != null && end != null) {
      // 显示 startTime --> endTime 格式
      if (start.hour == 0 && start.minute == 0) {
        // 只有日期信息，不显示时间
        return '${start.month}月${start.day}日';
      } else {
        final startStr =
            "${start.month}月${start.day}日 ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}";
        final endStr =
            "${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}";
        return '$startStr --> $endStr';
      }
    } else if (start != null) {
      // 只显示开始时间
      if (start.hour == 0 && start.minute == 0) {
        // 只有日期信息，不显示时间
        return '${start.month}月${start.day}日';
      } else {
        return "${start.month}月${start.day}日 ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}";
      }
    } else {
      return '选择日期';
    }
  }

  /// 检查是否是今天
  bool isToday() {
    final start = getFinalStartTime();
    if (start == null) return false;
    return start.isToday();
  }

  /// 获取今天的显示文本
  String getTodayDisplayText() {
    final start = getFinalStartTime();
    if (start == null) return '选择日期';

    if (start.isToday()) {
      if (start.hasTime()) {
        return '今天 ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
      }
      return '今天';
    }

    return getDisplayText();
  }

  @override
  String toString() =>
      'TaskTimeInfo{selectedDate: $selectedDate, startTime: $startTime, endTime: $endTime, startDateTime: $startDateTime, endDateTime: $endDateTime, isAllDay: $isAllDay, rrule: $rrule, startDate: $startDate, endDate: $endDate}';
}
