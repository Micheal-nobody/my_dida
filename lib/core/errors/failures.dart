/// Base failure class for error handling
abstract class Failure {
  const Failure(this.message, {this.code});
  final String message;
  final String? code;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ code.hashCode;

  @override
  String toString() =>
      'Failure: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Database operation failures
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.code});
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code, this.fieldErrors});
  final Map<String, String>? fieldErrors;
}

/// Network operation failures
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

/// Task operation failures
class TaskFailure extends Failure {
  const TaskFailure(super.message, {super.code});
}

/// Habit operation failures
class HabitFailure extends Failure {
  const HabitFailure(super.message, {super.code});
}

/// BelongingBox operation failures
class ChecklistFailure extends Failure {
  const ChecklistFailure(super.message, {super.code});
}
