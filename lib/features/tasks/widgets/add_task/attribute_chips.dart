import 'package:flutter/material.dart';
import 'package:my_dida/features/tasks/widgets/add_task_bottom_sheet.dart';

class AttributeChips extends StatelessWidget {
  const AttributeChips({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AddTaskStateScope.of(context);
    final tags = state.tags;

    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: tags.map(
          (tag) => InputChip(
            label: Text(tag, style: const TextStyle(fontSize: 11)),
            onDeleted: () => state.deleteTag(tag),
          ),
        ).toList(),
      ),
    );
  }
}
