/// Base exception class for the application
abstract class AppException implements Exception {
  const AppException(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() =>
      'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Database related exceptions
class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code});
}

/// Validation related exceptions
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, this.fieldErrors});
  final Map<String, String>? fieldErrors;
}

/// Network related exceptions
class NetworkException extends AppException {
  const NetworkException(super.message, {super.code});
}

/// Task related exceptions
class TaskException extends AppException {
  const TaskException(super.message, {super.code});
}

/// Habit related exceptions
class HabitException extends AppException {
  const HabitException(super.message, {super.code});
}

/// BelongingBox related exceptions
class ChecklistException extends AppException {
  const ChecklistException(super.message, {super.code});
}
