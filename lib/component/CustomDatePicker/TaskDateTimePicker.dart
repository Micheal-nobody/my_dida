import 'package:flutter/material.dart';
import 'package:my_dida/model/entity/Task.dart';
import 'package:my_dida/utils/TimeUtils.dart';
import 'package:my_dida/provider/TaskProvider.dart';
import 'package:provider/provider.dart';
import 'CustomDateTimePicker.dart';

/// 专门用于处理 Task 对象的日期时间选择器包装器
///
/// 这个组件封装了 CustomDateTimePicker 的复杂逻辑，
/// 基于 TaskDetailPage 的正确实现，直接处理任务的持久化更新
class TaskDateTimePicker {
  /// 显示任务日期时间选择器 - 用于编辑现有任务
  ///
  /// 基于 TaskDetailPage 的实现，直接处理任务的持久化更新
  ///
  /// [context] - 上下文
  /// [task] - 要编辑的任务对象
  /// [onUpdated] - 更新完成回调（可选，用于UI刷新）
  static Future<void> showForTask({
    required BuildContext context,
    required Task task,
    VoidCallback? onUpdated,
  }) async {
    // 从 Task 对象中提取时间信息
    final timeInfo = TaskTimeInfo.fromTask(task);
    final taskProvider = context.read<TaskProvider>();

    await CustomDateTimePickerModal.show(
      context: context,
      selectedDate: timeInfo.selectedDate,
      startTime: timeInfo.startTime,
      endTime: timeInfo.endTime,
      isAllDay: timeInfo.isAllDay,
      initialRRule: task.rrule,
      isTimeOnlyDate: timeInfo.isTimeOnlyDate,
      onDateChanged: (date) {
        timeInfo.selectedDate = date;
      },
      onTimeChanged: (start, end) {
        timeInfo.startTime = start;
        timeInfo.endTime = end;
      },
      onDateTimeChanged: (startDateTime, endDateTime) {
        timeInfo.startDateTime = startDateTime;
        timeInfo.endDateTime = endDateTime;
      },
      onAllDayChanged: (isAllDay) {
        timeInfo.isAllDay = isAllDay;
      },
      onClear: () async {
        // 直接清除任务时间并持久化
        await taskProvider.updateStartTime(task, null);
        await taskProvider.updateEndTime(task, null);
        await taskProvider.updateRRule(task, null);
      },
      onRepeatChanged: (rrule) {
        timeInfo.rrule = rrule;
      },
      onStartEndDateChanged: (startDate, endDate) {
        timeInfo.startDate = startDate;
        timeInfo.endDate = endDate;
      },
    );

    // 根据 TaskDetailPage 的逻辑处理时间更新和持久化
    final startTime = timeInfo.getFinalStartTime();
    final endTime = timeInfo.getFinalEndTime();

    // 使用 updateTimeRange 方法同时更新开始和结束时间
    await taskProvider.updateTimeRange(task, startTime, endTime);

    // 更新重复规则
    if (timeInfo.rrule != task.rrule) {
      await taskProvider.updateRRule(task, timeInfo.rrule);
    }

    // 调用更新完成回调
    onUpdated?.call();
  }

  /// 显示任务日期时间选择器 - 用于创建新任务
  ///
  /// 返回时间信息，供调用者创建新任务时使用
  ///
  /// [context] - 上下文
  /// [initialTask] - 初始任务信息（可选）
  /// [onTimeInfoUpdated] - 时间信息更新回调
  static Future<TaskTimeInfo?> showForNewTask({
    required BuildContext context,
    Task? initialTask,
    required Function(TaskTimeInfo) onTimeInfoUpdated,
  }) async {
    // 从 Task 对象中提取时间信息，或使用默认值
    final timeInfo = TaskTimeInfo.fromTask(initialTask);

    await CustomDateTimePickerModal.show(
      context: context,
      selectedDate: timeInfo.selectedDate,
      startTime: timeInfo.startTime,
      endTime: timeInfo.endTime,
      isAllDay: timeInfo.isAllDay,
      initialRRule: initialTask?.rrule,
      isTimeOnlyDate: timeInfo.isTimeOnlyDate,
      onDateChanged: (date) {
        timeInfo.selectedDate = date;
      },
      onTimeChanged: (start, end) {
        timeInfo.startTime = start;
        timeInfo.endTime = end;
      },
      onDateTimeChanged: (startDateTime, endDateTime) {
        timeInfo.startDateTime = startDateTime;
        timeInfo.endDateTime = endDateTime;
      },
      onAllDayChanged: (isAllDay) {
        timeInfo.isAllDay = isAllDay;
      },
      onClear: () {
        // 清除时间信息
        timeInfo.clear();
      },
      onRepeatChanged: (rrule) {
        timeInfo.rrule = rrule;
      },
      onStartEndDateChanged: (startDate, endDate) {
        timeInfo.startDate = startDate;
        timeInfo.endDate = endDate;
      },
    );

    // 调用回调并返回结果
    onTimeInfoUpdated(timeInfo);
    return timeInfo;
  }

  /// 兼容性方法 - 保持向后兼容
  @Deprecated(
    'Use showForTask for existing tasks or showForNewTask for new tasks instead',
  )
  static Future<TaskTimeInfo?> show({
    required BuildContext context,
    Task? task,
    required Function(TaskTimeInfo) onTaskUpdated,
    VoidCallback? onClear,
  }) async {
    if (task != null) {
      // 对于现有任务，使用新的 showForTask 方法
      await showForTask(context: context, task: task, onUpdated: onClear);
      // 返回更新后的时间信息
      return TaskTimeInfo.fromTask(task);
    } else {
      // 对于新任务，使用新的 showForNewTask 方法
      return await showForNewTask(
        context: context,
        onTimeInfoUpdated: onTaskUpdated,
      );
    }
  }
}

/// 任务时间信息封装类
///
/// 封装了任务相关的所有时间信息，简化了时间处理逻辑
class TaskTimeInfo {
  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  DateTime? startDateTime;
  DateTime? endDateTime;
  bool isAllDay;
  String? rrule;

  // 独立的开始和结束日期（用于时间段模式）
  DateTime? startDate;
  DateTime? endDate;

  /// 是否只有日期（没有具体时间）
  bool get isTimeOnlyDate {
    return startDateTime != null &&
        startDateTime!.hour == 0 &&
        startDateTime!.minute == 0;
  }

  TaskTimeInfo({
    this.selectedDate,
    this.startTime,
    this.endTime,
    this.startDateTime,
    this.endDateTime,
    this.isAllDay = false,
    this.rrule,
    this.startDate,
    this.endDate,
  });

  /// 从 Task 对象创建 TaskTimeInfo
  factory TaskTimeInfo.fromTask(Task? task) {
    if (task == null) {
      // 为新任务提供默认的开始和结束时间，确保时长计算正常工作
      final now = DateTime.now().toBeijingTime();
      return TaskTimeInfo(
        selectedDate: now.dateOnly,
        startTime: TimeOfDay(hour: now.hour, minute: now.minute),
        endTime: TimeOfDay(hour: (now.hour + 1) % 24, minute: now.minute),
      );
    }

    DateTime? selectedDate =
        task.startTime ?? DateTime.now().toBeijingTime().dateOnly;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    // 处理开始时间
    if (task.startTime != null) {
      if (task.startTime!.hour == 0 && task.startTime!.minute == 0) {
        // 只有日期信息，使用当前时间作为默认时间
        final now = DateTime.now().toBeijingTime();
        startTime = TimeOfDay(hour: now.hour, minute: now.minute);
      } else {
        startTime = TimeOfDay(
          hour: task.startTime!.hour,
          minute: task.startTime!.minute,
        );
      }
    }

    // 处理结束时间
    if (task.endTime != null) {
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
      isAllDay: false,
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

  /// 清除所有时间信息
  void clear() {
    selectedDate = DateTime.now().toBeijingTime().dateOnly;
    startTime = null;
    endTime = null;
    startDateTime = null;
    endDateTime = null;
    isAllDay = false;
    rrule = null;
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
        return "${start.month}月${start.day}日";
      } else {
        final startStr =
            "${start.month}月${start.day}日 ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}";
        final endStr =
            "${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}";
        return "$startStr --> $endStr";
      }
    } else if (start != null) {
      // 只显示开始时间
      if (start.hour == 0 && start.minute == 0) {
        // 只有日期信息，不显示时间
        return "${start.month}月${start.day}日";
      } else {
        return "${start.month}月${start.day}日 ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}";
      }
    } else {
      return "选择日期";
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
    if (start == null) return "选择日期";

    if (start.isToday()) {
      if (start.hasTime()) {
        return '今天 ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
      }
      return '今天';
    }

    return getDisplayText();
  }

  @override
  String toString() {
    return 'TaskTimeInfo{selectedDate: $selectedDate, startTime: $startTime, endTime: $endTime, startDateTime: $startDateTime, endDateTime: $endDateTime, isAllDay: $isAllDay, rrule: $rrule, startDate: $startDate, endDate: $endDate}';
  }
}
