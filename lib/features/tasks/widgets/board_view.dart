import 'package:flutter/material.dart';
import 'package:my_dida/core/themes/theme_provider.dart';
import 'package:my_dida/features/checklist/models/checklist_vo.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/pages/task_detail_page.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:my_dida/features/tasks/widgets/add_task_bottom_sheet.dart';
import 'package:my_dida/features/tasks/widgets/task_card.dart';
import 'package:provider/provider.dart';

class BoardView extends StatelessWidget {
  const BoardView({
    required this.groupedTasks,
    required this.allChecklists,
    super.key,
  });

  final Map<String, List<Task>> groupedTasks;
  final List<ChecklistVO> allChecklists;

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final currentGroupBy = taskProvider.groupBy;

    final columns = groupedTasks.keys.toList();

    if (columns.isEmpty) {
      return const Center(
        child: Text('无任务数据', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: columns.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final columnTitle = columns[index];
        final tasks = groupedTasks[columnTitle] ?? [];

        final colorTheme = context.theme;

        return Container(
          width: 300,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 列头部
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          columnTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${tasks.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.add, color: colorTheme.iconColor),
                      onPressed: () {
                        // 点击新增任务
                        _showAddTaskDialogForColumn(
                          context,
                          columnTitle,
                          currentGroupBy,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // 任务卡片拖放目标区域
              Expanded(
                child: DragTarget<Task>(
                  onWillAcceptWithDetails: (details) => details.data.id != -1,
                  onAcceptWithDetails: (details) {
                    final task = details.data;
                    _handleTaskDropped(
                      context,
                      task,
                      columnTitle,
                      currentGroupBy,
                      taskProvider,
                    );
                  },
                  builder: (context, candidateData, rejectedData) => Container(
                    color: candidateData.isNotEmpty
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Colors.transparent,
                    child: ListView.builder(
                      itemCount: tasks.length,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemBuilder: (context, taskIndex) {
                        final task = tasks[taskIndex];

                        return LongPressDraggable<Task>(
                          data: task,
                          feedback: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 284,
                              child: TaskCard(
                                task: task,
                                checklistName: task.getChecklistName(allChecklists),
                                checklistColor: task.getChecklist(allChecklists).color,
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: TaskCard(
                              task: task,
                              checklistName: task.getChecklistName(allChecklists),
                              checklistColor: task.getChecklist(allChecklists).color,
                            ),
                          ),
                          child: TaskCard(
                            task: task,
                            checklistName: task.getChecklistName(allChecklists),
                            checklistColor: task.getChecklist(allChecklists).color,
                            onToggleDone: (value) {
                              taskProvider.execute(
                                UpdateTaskIsDone(task, value!),
                              );
                            },
                            onTap: () {
                              TaskDetailPage.show(context, task);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  void _showAddTaskDialogForColumn(
    BuildContext context,
    String columnTitle,
    TaskGroupBy groupBy,
  ) {
    // 根据当前分组列快速组装预设字段（我们之后可以通过构造函数传递给 AddTaskDialog 辅助快速填入）
    Task? presetTask;

    if (groupBy == TaskGroupBy.priority) {
      final TaskPriority priority = TaskPriority.fromLabel(columnTitle);
      presetTask = Task(name: '', isAllDay: true, priority: priority);

    } else if (groupBy == TaskGroupBy.checklist) {
      final cl = allChecklists.firstWhere(
        (c) => c.name == columnTitle,
        orElse: () => allChecklists.first,
      );
      presetTask = Task(name: '', isAllDay: true, checklistId: cl.id);

    } else if (groupBy == TaskGroupBy.tag) {
      if (columnTitle != '无标签') {
        presetTask = Task(name: '', isAllDay: true, tags: [columnTitle]);
      }
    } else if (groupBy == TaskGroupBy.date) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      DateTime? startTime;
      if (columnTitle == '今天') {
        startTime = today;
      } else if (columnTitle == '明天') {
        startTime = tomorrow;
      } else if (columnTitle == '最近7天') {
        startTime = today.add(const Duration(days: 3));
      } else if (columnTitle == '稍后') {
        startTime = today.add(const Duration(days: 8));
      }

      if (startTime != null) {
        presetTask = Task(name: '', isAllDay: true, startTime: startTime);
      }
    }

    AddTaskBottomSheet.show(
      context: context,
      initTask: presetTask,
    );
  }

  void _handleTaskDropped(
    BuildContext context,
    Task task,
    String columnTitle,
    TaskGroupBy groupBy,
    TaskProvider taskProvider,
  ) async {
    if (groupBy == TaskGroupBy.priority) {
      final TaskPriority newPriority = TaskPriority.fromLabel(columnTitle);

      if (task.priority != newPriority) {
        await taskProvider.updatePriority(task, newPriority);
      }
    } else if (groupBy == TaskGroupBy.checklist) {
      final targetChecklist = allChecklists.firstWhere(
        (cl) => cl.name == columnTitle,
        orElse: () => allChecklists.first,
      );
      if (task.checklistId != targetChecklist.id) {
        await taskProvider.execute(UpdateChecklist(task, targetChecklist.id));
      }
    } else if (groupBy == TaskGroupBy.tag) {
      if (columnTitle == '无标签') {
        if (task.tags.isNotEmpty) {
          await taskProvider.execute(UpdateTags(task, []));
        }
      } else {
        if (!task.tags.contains(columnTitle)) {
          await taskProvider.execute(UpdateTags(task, [columnTitle]));
        }
      }
    } else if (groupBy == TaskGroupBy.date) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      if (columnTitle == '今天') {
        await taskProvider.updateStartTime(task, today, isAllDay: true);
      } else if (columnTitle == '明天') {
        await taskProvider.updateStartTime(task, tomorrow, isAllDay: true);
      } else if (columnTitle == '已过期') {
        await taskProvider.updateStartTime(
          task,
          today.subtract(const Duration(days: 1)),
          isAllDay: true,
        );
      } else if (columnTitle == '最近7天') {
        await taskProvider.updateStartTime(
          task,
          today.add(const Duration(days: 3)),
          isAllDay: true,
        );
      } else if (columnTitle == '稍后') {
        await taskProvider.updateStartTime(
          task,
          today.add(const Duration(days: 8)),
          isAllDay: true,
        );
      } else if (columnTitle == '无日期') {
        await taskProvider.clearTaskSchedule(task);
      }
    }
  }
}
