import 'package:my_dida/core/errors/exceptions.dart';
import 'package:my_dida/features/tasks/models/repeat_pattern.dart';

/// Validator for task-related operations
class TaskValidator {
  /// Validates task name
  static void validateTaskName(String? name) {
    if (name == null || name.trim().isEmpty) {
      throw const ValidationException('Task name cannot be empty');
    }

    if (name.trim().length > 100) {
      throw const ValidationException('Task name cannot exceed 100 characters');
    }
  }

  /// Validates task description
  static void validateTaskDescription(String? description) {
    if (description != null && description.length > 500) {
      throw const ValidationException(
        'Task description cannot exceed 500 characters',
      );
    }
  }

  /// Validates task time range
  static void validateTaskTimeRange(DateTime? startTime, DateTime? endTime) {
    if (startTime != null && endTime != null) {
      if (endTime.isBefore(startTime)) {
        throw const ValidationException('End time cannot be before start time');
      }
    }
  }

  /// Validates belonging box ID
  static void validateChecklistId(int? checklistId) {
    if (checklistId != null && checklistId < 1) {
      throw const ValidationException('Invalid belonging box ID');
    }
  }

  /// Validates checkpoint name
  static void validateCheckpointName(String? name) {
    if (name == null || name.trim().isEmpty) {
      throw const ValidationException('Checkpoint name cannot be empty');
    }

    if (name.trim().length > 50) {
      throw const ValidationException(
        'Checkpoint name cannot exceed 50 characters',
      );
    }
  }

  /// Validates RRule string
  static void validateRRule(RepeatPattern? rrule) {
    if (rrule != null && !rrule.isNone) {
      final rruleStr = rrule.toRRuleString();
      if (rruleStr != null && !rruleStr.startsWith('CUSTOM:')) {
        // Basic validation - should start with RRULE:FREQ= or FREQ=
        final clean = rruleStr.replaceFirst('RRULE:', '');
        if (!clean.toUpperCase().startsWith('FREQ=')) {
          throw const ValidationException('Invalid RRule format');
        }
      }
    }
  }

  /// Validates task reminder configuration
  static void validateTaskReminderConfiguration({
    required bool notificationEnabled,
    required int? reminderOffsetMinutes,
    required DateTime? startTime,
    required bool isAllDay,
  }) {
    if (!notificationEnabled) {
      if (reminderOffsetMinutes != null) {
        throw const ValidationException(
          'Reminder offset must be null when notification is disabled',
        );
      }
      return;
    }

    if (startTime == null) {
      throw const ValidationException(
        'Tasks without a start time cannot enable reminders',
      );
    }

    if (isAllDay) {
      throw const ValidationException('All-day tasks cannot enable reminders');
    }

    if (reminderOffsetMinutes == null) {
      throw const ValidationException(
        'Reminder offset is required when notification is enabled',
      );
    }

    if (reminderOffsetMinutes < 0 || reminderOffsetMinutes > 10080) {
      throw const ValidationException(
        'Reminder offset must be between 0 and 10080 minutes',
      );
    }
  }
}
