import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/models/repeat_pattern.dart';

abstract class TaskOperation {
  final Task task;
  TaskOperation(this.task);
}

class AddTask extends TaskOperation {
  AddTask(super.task);
}

class UpdateTaskIsDone extends TaskOperation {
  final bool value;
  UpdateTaskIsDone(super.task, this.value);
}

class UpdatePriority extends TaskOperation {
  final TaskPriority newPriority;
  UpdatePriority(super.task, this.newPriority);
}

class UpdateTags extends TaskOperation {
  final List<String> newTags;
  UpdateTags(super.task, this.newTags);
}

class UpdateTitle extends TaskOperation {
  final String newTitle;
  UpdateTitle(super.task, this.newTitle);
}

class UpdateDescription extends TaskOperation {
  final String newDesc;
  UpdateDescription(super.task, this.newDesc);
}

class ToggleCheckpoint extends TaskOperation {
  final int index;
  final bool value;
  ToggleCheckpoint(super.task, this.index, this.value);
}

class RenameCheckpoint extends TaskOperation {
  final int index;
  final String newName;
  RenameCheckpoint(super.task, this.index, this.newName);
}

class AddCheckpoint extends TaskOperation {
  AddCheckpoint(super.task);
}

class RemoveCheckpoint extends TaskOperation {
  final int index;
  RemoveCheckpoint(super.task, this.index);
}

class CreateSubTask extends TaskOperation {
  final String name;
  CreateSubTask(super.task, {required this.name});
}

class DeleteSubTask extends TaskOperation {
  final int subTaskId;
  DeleteSubTask(super.task, this.subTaskId);
}

class UpdateChecklist extends TaskOperation {
  final int? newChecklistId;
  UpdateChecklist(super.task, this.newChecklistId);
}

class UpdateStartTime extends TaskOperation {
  final DateTime? newStartTime;
  final bool? isAllDay;
  UpdateStartTime(super.task, this.newStartTime, {this.isAllDay});
}

class UpdateEndTime extends TaskOperation {
  final DateTime? newEndTime;
  final bool? isAllDay;
  UpdateEndTime(super.task, this.newEndTime, {this.isAllDay});
}

class UpdateTimeRange extends TaskOperation {
  final DateTime? newStartTime;
  final DateTime? newEndTime;
  final bool? isAllDay;
  UpdateTimeRange(
    super.task,
    this.newStartTime,
    this.newEndTime, {
    this.isAllDay,
  });
}

class ClearTaskSchedule extends TaskOperation {
  ClearTaskSchedule(super.task);
}

class UpdateRRule extends TaskOperation {
  final RepeatPattern? rrule;
  UpdateRRule(super.task, this.rrule);
}

class UpdateTaskReminder extends TaskOperation {
  final bool enabled;
  final int? offsetMinutes;
  UpdateTaskReminder(super.task, {required this.enabled, this.offsetMinutes});
}

class DeleteTask extends TaskOperation {
  DeleteTask(super.task);
}

class DeletePermanently extends TaskOperation {
  DeletePermanently(super.task);
}

class RestoreTask extends TaskOperation {
  RestoreTask(super.task);
}

class AssociateMainTask extends TaskOperation {
  final Task mainTask;
  AssociateMainTask(super.task, this.mainTask);
}

class CopyTask extends TaskOperation {
  CopyTask(super.task);
}
