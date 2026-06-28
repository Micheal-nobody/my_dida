import 'package:flutter/material.dart';
import 'package:my_dida/core/di/locator.dart';
import 'package:my_dida/core/ui/app_message_service.dart';
import 'package:my_dida/core/utils/time_formatter.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:my_dida/shared/widgets/datetime/custom_date_time_picker.dart';
import 'package:provider/provider.dart';

class TaskTimeSection extends StatelessWidget {
  const TaskTimeSection({required this.task, super.key});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.read<TaskProvider>();
    final messageService = getIt<AppMessageService>();

    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        final updatedTask = provider.tasks.firstWhere(
          (t) => t.id == task.id,
          orElse: () => task,
        );

        return Row(
          children: [
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () async {
                await taskProvider.updateTaskIsDone(
                  updatedTask,
                  !updatedTask.isDone,
                );
                if (!context.mounted) return;
                if (updatedTask.isDone) {
                  messageService.showInfo('任务已取消完成');
                } else {
                  messageService.showSuccess('任务已完成！');
                }
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: updatedTask.isDone ? Colors.green : Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  color: updatedTask.isDone ? Colors.green : Colors.transparent,
                ),
                child: updatedTask.isDone
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () =>
                    _showDatePicker(context, updatedTask, taskProvider),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule, color: Colors.orange, size: 14),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        updatedTask.startTime != null
                            ? _formatDateTime(updatedTask.startTime!)
                            : '选择时间或重复',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) =>
      TimeFormatter.formatTaskDateTime(dateTime);

  Future<void> _showDatePicker(
    BuildContext context,
    Task task,
    TaskProvider taskProvider,
  ) async {
    final initialStartDate = task.startTime != null
        ? DateTime(
            task.startTime!.year,
            task.startTime!.month,
            task.startTime!.day,
          )
        : DateTime.now();
    final initialEndDate = task.endTime != null
        ? DateTime(task.endTime!.year, task.endTime!.month, task.endTime!.day)
        : initialStartDate;

    final result = await CustomDateTimePickerModal.show(
      context: context,
      initialValue: CustomDateTimePickerValue(
        selectedDate: initialStartDate,
        startTime: task.startTime != null
            ? TimeOfDay.fromDateTime(task.startTime!)
            : null,
        endTime: task.endTime != null
            ? TimeOfDay.fromDateTime(task.endTime!)
            : null,
        startDate: initialStartDate,
        endDate: initialEndDate,
        isAllDay: task.isAllDay,
        rrule: task.rrule,
        isTimeOnlyDate:
            task.startTime != null &&
            task.startTime!.hour == 0 &&
            task.startTime!.minute == 0,
      ),
    );
    if (result == null) {
      return;
    }

    final DateTime? newStartTime = _buildDateTime(
      date: result.startDate ?? result.selectedDate,
      time: result.startTime,
      isAllDay: result.isAllDay,
    );
    final DateTime? newEndTime = _buildDateTime(
      date: result.endDate ?? result.selectedDate,
      time: result.endTime,
      isAllDay: false,
    );

    if (result.rrule != task.rrule) {
      await taskProvider.execute(UpdateRRule(task, result.rrule));
    }
    await taskProvider.execute(
      UpdateTimeRange(
        task,
        newStartTime,
        newEndTime,
        isAllDay: result.isAllDay,
      ),
    );
  }

  DateTime? _buildDateTime({
    required DateTime? date,
    required TimeOfDay? time,
    required bool isAllDay,
  }) {
    if (date == null) {
      return null;
    }
    if (isAllDay) {
      return DateTime(date.year, date.month, date.day);
    }
    if (time == null) {
      return null;
    }
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}
