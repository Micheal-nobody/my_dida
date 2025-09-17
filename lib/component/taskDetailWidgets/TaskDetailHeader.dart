import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_dida/model/entity/Task.dart';
import 'package:my_dida/provider/TaskProvider.dart';
import 'package:my_dida/provider/BelongingBoxProvider.dart';
import 'package:my_dida/component/CustomDatePicker/CustomDatePicker.dart';

import '../../model/vo/BelongingBoxVO.dart';

class TaskDetailHeader extends StatelessWidget {
  final Task task;

  const TaskDetailHeader({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final taskProvider = context.read<TaskProvider>();

    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        // Get the updated task from the provider
        final updatedTask = provider.tasks.firstWhere(
          (t) => t.id == task.id,
          orElse: () => task,
        );
        final DateTime effectiveDate = updatedTask.startTime ?? now;
        final String dateText =
            "${effectiveDate.month.toString().padLeft(2, '0')}-${effectiveDate.day.toString().padLeft(2, '0')} ${effectiveDate.hour.toString().padLeft(2, '0')}:${effectiveDate.minute.toString().padLeft(2, '0')}";

        // return _buildHeader(context, updatedTask, dateText, taskProvider);
        // 不使用函数转发，直接返回Padding
        final bool canPop = Navigator.of(context).canPop();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  canPop ? Icons.arrow_back : Icons.close,
                  color: Colors.orange,
                ),
                onPressed: () {
                  if (canPop) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
              ),
              const Icon(Icons.event_note, color: Colors.orange),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => CustomDatePicker(
                      selectedDate: updatedTask.startTime ?? now,
                      startTime: null,
                      endTime: null,
                      isAllDay: false,
                      onDateChanged: (date) async {
                        await taskProvider.updateStartTime(updatedTask, date);
                      },
                      onTimeChanged: (start, end) async {
                        if (start != null) {
                          // 从Provider中获取最新任务数据，避免闭包变量过时
                          final latestTaskProvider = context
                              .read<TaskProvider>();
                          final latestTask = latestTaskProvider.tasks
                              .firstWhere(
                                (t) => t.id == task.id,
                                orElse: () => task,
                              );
                          // 获取当前任务的开始时间（如果不存在则使用当前日期时间）
                          final currentDateTime = latestTask.startTime ?? now;
                          // 使用新的时间更新开始时间的小时和分钟部分，保持年月日不变
                          final newDateTime = DateTime(
                            currentDateTime.year,
                            currentDateTime.month,
                            currentDateTime.day,
                            start.hour,
                            start.minute,
                          );
                          await latestTaskProvider.updateStartTime(
                            latestTask,
                            newDateTime,
                          );
                        }
                      },
                      onAllDayChanged: (isAllDay) {
                        //TODO: 全天变更暂不处理
                      },
                      onClear: () async {
                        await taskProvider.updateStartTime(updatedTask, null);
                      },
                    ),
                  );
                },
                onLongPress: () async {
                  await taskProvider.updateStartTime(updatedTask, null);
                },
                child: Text(
                  dateText,
                  style: const TextStyle(color: Colors.orange, fontSize: 14),
                ),
              ),
              const Spacer(),

              //通过Selector构建BelongingBoxDropdown
              Selector<BelongingBoxProvider, List<BelongingBoxVO>>(
                selector: (context, provider) => provider.all_belongingBoxes,
                builder: (context, allBoxes, child) {
                  return DropdownButton<int?>(
                    value: updatedTask.belongingBoxId,
                    underline: const SizedBox.shrink(),
                    items: [
                      for (final box in allBoxes)
                        DropdownMenuItem<int?>(
                          value: box.id,
                          child: Text(box.name),
                        ),
                    ],
                    onChanged: (v) async {
                      await taskProvider.updateBelongingBox(updatedTask, v);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
