import '../errors/exceptions.dart';

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
    if (checklistId != null && checklistId < -1) {
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
  static void validateRRule(String? rrule) {
    if (rrule != null && rrule.isNotEmpty) {
      // Basic validation - should start with FREQ=
      if (!rrule.toUpperCase().startsWith('FREQ=')) {
        throw const ValidationException('Invalid RRule format');
      }
    }
  }
}
