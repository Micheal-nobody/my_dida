import 'package:flutter/material.dart';
import 'package:my_dida/features/checklist/models/checklist_vo.dart';
import 'package:my_dida/features/checklist/providers/checklist_provider.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/pages/task_detail_page.dart';
import 'package:my_dida/features/tasks/providers/task_provider.dart';
import 'package:my_dida/features/tasks/widgets/task_card.dart';
import 'package:provider/provider.dart';

class CalendarTaskListBottom extends StatelessWidget {
  const CalendarTaskListBottom({
    required this.selectedDate,
    required this.tasks,
    super.key,
  });

  final DateTime selectedDate;
  final List<Task> tasks;

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return '一';
      case 2:
        return '二';
      case 3:
        return '三';
      case 4:
        return '四';
      case 5:
        return '五';
      case 6:
        return '六';
      case 7:
        return '日';
      default:
        return '';
    }
  }

  String _getChecklistName(int? id, List<ChecklistVO> allChecklists) {
    if (id == null) return '';
    final cl = allChecklists.firstWhere(
      (c) => c.id == id,
      orElse: () => allChecklists.first,
    );
    return cl.name;
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final checklistProvider = Provider.of<ChecklistProvider>(context);
    final allChecklists = checklistProvider.allCheckLists;

    final dateStr =
        "${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日 星期${_getWeekdayName(selectedDate.weekday)}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            dateStr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: tasks.isEmpty
              ? const Center(
                  child: Text(
                    '当天没有任务',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return TaskCard(
                      task: task,
                      checklistName: _getChecklistName(
                        task.checklistId,
                        allChecklists,
                      ),
                      onToggleDone: (value) {
                        taskProvider.execute(UpdateTaskIsDone(task, value!));
                      },
                      onTap: () {
                        TaskDetailPage.show(context, task);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
