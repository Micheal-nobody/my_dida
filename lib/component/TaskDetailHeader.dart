import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:my_dida/model/entity/Task.dart';
import 'package:my_dida/provider/TaskProvider.dart';
import 'package:my_dida/provider/BelongingBoxProvider.dart';

import '../model/vo/BelongingBoxVO.dart';

class TaskDetailHeader extends StatelessWidget {
  final Task task;

  const TaskDetailHeader({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime effectiveDate = task.startTime ?? now;
    final String dateText = "${effectiveDate.month}月${effectiveDate.day}日";
    final taskProvider = context.read<TaskProvider>();

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
            onTap: () async {
              final DateTime initial = task.startTime ?? now;
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                await taskProvider.updateStartTime(task, picked);
              }
            },
            onLongPress: () async {
              await taskProvider.updateStartTime(task, null);
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
                value: task.belongingBoxId,
                underline: const SizedBox.shrink(),
                items: [
                  for (final box in allBoxes)
                    DropdownMenuItem<int?>(
                      value: box.id,
                      child: Text(box.name),
                    ),
                ],
                onChanged: (v) async {
                  await taskProvider.updateBelongingBox(task, v);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
