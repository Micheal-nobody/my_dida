import 'package:flutter/material.dart';
import 'package:my_dida/core/themes/theme_provider.dart';
import 'package:my_dida/features/tasks/models/check_point.dart';
import 'package:my_dida/features/tasks/widgets/add_task_bottom_sheet.dart';

class CheckpointListView extends StatelessWidget {
  const CheckpointListView({
    this.isFullScreen = false,
    super.key,
  });

  final bool isFullScreen;

  @override
  Widget build(BuildContext context) {
    final state = AddTaskStateScope.of(context);
    final checkpoints = state.checkpoints;
    final checkpointFocusNodes = state.checkpointFocusNodes;

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: checkpoints.length,
      itemBuilder: (context, index) {
        final cp = checkpoints[index];
        FocusNode? focusNode;
        if (isFullScreen) {
          focusNode = checkpointFocusNodes.length > index ? checkpointFocusNodes[index] : null;
        }

        return Row(
          key: isFullScreen ? ObjectKey(cp) : null,
          children: [
            Checkbox(
              value: cp.isDone,
              activeColor: context.theme.primary,
              onChanged: (val) {
                state.setCheckpoint(
                  index,
                  CheckPoint(name: cp.name, isDone: val ?? false),
                );
              },
            ),
            Expanded(
              child: TextFormField(
                focusNode: focusNode,
                initialValue: cp.name,
                textInputAction: isFullScreen ? TextInputAction.next : null,
                decoration: InputDecoration(
                  hintText: isFullScreen ? '添加步骤' : '步骤内容',
                  border: InputBorder.none,
                  isDense: isFullScreen ? true : null,
                  contentPadding: isFullScreen ? const EdgeInsets.symmetric(vertical: 8) : null,
                ),
                onChanged: (val) {
                  state.setCheckpoint(
                    index,
                    CheckPoint(name: val, isDone: cp.isDone),
                  );
                },
                onFieldSubmitted: isFullScreen
                    ? (_) => state.addCheckpoint(index: index)
                    : null,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                color: context.theme.unselectedLabelColor,
                size: isFullScreen ? 20 : 24,
              ),
              onPressed: () => state.removeCheckpoint(index),
            ),
          ],
        );
      },
    );
  }
}
