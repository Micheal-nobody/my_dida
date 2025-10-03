import 'package:flutter/material.dart';
import 'package:my_dida/components/pickers/CustomDatePicker/CustomDateTimePicker.dart';
import 'package:my_dida/model/entity/Task.dart';
import 'package:my_dida/provider/TaskProvider.dart';
import 'package:provider/provider.dart';

class TaskTimeSection extends StatelessWidget {
  const TaskTimeSection({required this.task, super.key});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.read<TaskProvider>();

    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        // Get the updated task from the provider
        final updatedTask = provider.tasks.firstWhere(
          (t) => t.id == task.id,
          orElse: () => task,
        );

        return Row(
          children: [
            const SizedBox(width: 12),

            // 完成任务按钮（方框样式）
            GestureDetector(
              onTap: () async {
                await taskProvider.updateTaskIsDone(
                  updatedTask,
                  !updatedTask.isDone,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(updatedTask.isDone ? '任务已取消完成' : '任务已完成！'),
                    backgroundColor: updatedTask.isDone
                        ? Colors.orange
                        : Colors.green,
                  ),
                );
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

            // 时间显示区域
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
      "${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";

  void _showDatePicker(
    BuildContext context,
    Task task,
    TaskProvider taskProvider,
  ) {
    final DateTime now = DateTime.now();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomDateTimePicker(
        selectedDate: task.startTime ?? now,
        startTime: null,
        endTime: null,
        isAllDay: false,
        initialRRule: task.rrule,
        onDateChanged: (date) async {
          await taskProvider.updateStartTime(task, date);
        },
        onTimeChanged: (start, end) async {
          if (start != null) {
            final currentDateTime = task.startTime ?? now;
            final newDateTime = DateTime(
              currentDateTime.year,
              currentDateTime.month,
              currentDateTime.day,
              start.hour,
              start.minute,
            );
            await taskProvider.updateStartTime(task, newDateTime);
          }
        },
        onAllDayChanged: (isAllDay) {
          //TODO: 全天变更暂不处理
        },
        onClear: () async {
          await taskProvider.updateStartTime(task, null);
        },
      ),
    );
  }
}
