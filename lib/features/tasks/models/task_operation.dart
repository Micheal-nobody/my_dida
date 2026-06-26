import 'package:my_dida/features/tasks/models/repeat_pattern.dart';
import 'package:my_dida/features/tasks/models/task.dart';

abstract class TaskOperation {
  TaskOperation(this.task);
  final Task task;
}

class AddTask extends TaskOperation {
  AddTask(super.task);
}

class UpdateTaskIsDone extends TaskOperation {
  UpdateTaskIsDone(super.task, this.value);
  final bool value;
}

class UpdatePriority extends TaskOperation {
  UpdatePriority(super.task, this.newPriority);
  final TaskPriority newPriority;
}

class UpdateTags extends TaskOperation {
  UpdateTags(super.task, this.newTags);
  final List<String> newTags;
}

class UpdateTitle extends TaskOperation {
  UpdateTitle(super.task, this.newTitle);
  final String newTitle;
}

class UpdateDescription extends TaskOperation {
  UpdateDescription(super.task, this.newDesc);
  final String newDesc;
}

class ToggleCheckpoint extends TaskOperation {
  ToggleCheckpoint(super.task, this.index, this.value);
  final int index;
  final bool value;
}

class RenameCheckpoint extends TaskOperation {
  RenameCheckpoint(super.task, this.index, this.newName);
  final int index;
  final String newName;
}

class AddCheckpoint extends TaskOperation {
  AddCheckpoint(super.task);
}

class RemoveCheckpoint extends TaskOperation {
  RemoveCheckpoint(super.task, this.index);
  final int index;
}

class CreateSubTask extends TaskOperation {
  CreateSubTask(super.task, {required this.name});
  final String name;
}

class DeleteSubTask extends TaskOperation {
  DeleteSubTask(super.task, this.subTaskId);
  final int subTaskId;
}

class UpdateChecklist extends TaskOperation {
  UpdateChecklist(super.task, this.newChecklistId);
  final int? newChecklistId;
}

class UpdateStartTime extends TaskOperation {
  UpdateStartTime(super.task, this.newStartTime, {this.isAllDay});
  final DateTime? newStartTime;
  final bool? isAllDay;
}

class UpdateEndTime extends TaskOperation {
  UpdateEndTime(super.task, this.newEndTime, {this.isAllDay});
  final DateTime? newEndTime;
  final bool? isAllDay;
}

class UpdateTimeRange extends TaskOperation {
  UpdateTimeRange(
    super.task,
    this.newStartTime,
    this.newEndTime, {
    this.isAllDay,
  });
  final DateTime? newStartTime;
  final DateTime? newEndTime;
  final bool? isAllDay;
}

class ClearTaskSchedule extends TaskOperation {
  ClearTaskSchedule(super.task);
}

class UpdateRRule extends TaskOperation {
  UpdateRRule(super.task, this.rrule);
  final RepeatPattern? rrule;
}

class UpdateTaskReminder extends TaskOperation {
  UpdateTaskReminder(
    super.task, {
    required this.enabled,
    this.offsetMinutes,
    this.reminderOffsets,
  });
  final bool enabled;
  final int? offsetMinutes;
  final List<int>? reminderOffsets;
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
  AssociateMainTask(super.task, this.mainTask);
  final Task mainTask;
}

class CopyTask extends TaskOperation {
  CopyTask(super.task);
}
