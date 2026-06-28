import 'package:flutter/material.dart';
import 'package:my_dida/features/tasks/widgets/add_task_bottom_sheet.dart';

class CustomFloatingActionButton extends StatelessWidget {
  const CustomFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) => FloatingActionButton(
    backgroundColor: Colors.orange,
    child: const Icon(Icons.add, color: Colors.white),
    onPressed: () {
      AddTaskBottomSheet.show(
        context: context,
      );
    },
  );
}
