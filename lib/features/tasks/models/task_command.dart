import 'package:my_dida/features/tasks/models/repeat_pattern.dart';
import 'package:my_dida/features/tasks/models/task.dart';

abstract class TaskCommand {
  TaskCommand(this.task);
  final Task task;
}

class AddTask extends TaskCommand {
  AddTask(super.task);
}

class UpdateTaskIsDone extends TaskCommand {
  UpdateTaskIsDone(super.task, this.value);
  final bool value;
}

class UpdatePriority extends TaskCommand {
  UpdatePriority(super.task, this.newPriority);
  final TaskPriority newPriority;
}

class UpdateTags extends TaskCommand {
  UpdateTags(super.task, this.newTags);
  final List<String> newTags;
}

class UpdateTitle extends TaskCommand {
  UpdateTitle(super.task, this.newTitle);
  final String newTitle;
}

class UpdateDescription extends TaskCommand {
  UpdateDescription(super.task, this.newDesc);
  final String newDesc;
}

class ToggleCheckpoint extends TaskCommand {
  ToggleCheckpoint(super.task, this.index, this.value);
  final int index;
  final bool value;
}

class RenameCheckpoint extends TaskCommand {
  RenameCheckpoint(super.task, this.index, this.newName);
  final int index;
  final String newName;
}

class AddCheckpoint extends TaskCommand {
  AddCheckpoint(super.task);
}

class RemoveCheckpoint extends TaskCommand {
  RemoveCheckpoint(super.task, this.index);
  final int index;
}

class CreateSubTask extends TaskCommand {
  CreateSubTask(super.task, {required this.name});
  final String name;
}

class DeleteSubTask extends TaskCommand {
  DeleteSubTask(super.task, this.subTaskId);
  final int subTaskId;
}

class UpdateChecklist extends TaskCommand {
  UpdateChecklist(super.task, this.newChecklistId);
  final int? newChecklistId;
}

class UpdateStartTime extends TaskCommand {
  UpdateStartTime(super.task, this.newStartTime, {this.isAllDay});
  final DateTime? newStartTime;
  final bool? isAllDay;
}

class UpdateEndTime extends TaskCommand {
  UpdateEndTime(super.task, this.newEndTime, {this.isAllDay});
  final DateTime? newEndTime;
  final bool? isAllDay;
}

class UpdateTimeRange extends TaskCommand {
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

class ClearTaskSchedule extends TaskCommand {
  ClearTaskSchedule(super.task);
}

class UpdateRRule extends TaskCommand {
  UpdateRRule(super.task, this.rrule);
  final RepeatPattern? rrule;
}

class UpdateTaskReminder extends TaskCommand {
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

class DeleteTask extends TaskCommand {
  DeleteTask(super.task);
}

class DeletePermanently extends TaskCommand {
  DeletePermanently(super.task);
}

class RestoreTask extends TaskCommand {
  RestoreTask(super.task);
}

class AssociateMainTask extends TaskCommand {
  AssociateMainTask(super.task, this.mainTask);
  final Task mainTask;
}

class CopyTask extends TaskCommand {
  CopyTask(super.task);
}
