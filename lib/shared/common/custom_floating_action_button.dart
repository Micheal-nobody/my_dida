import 'package:flutter/material.dart';

import '../../features/dialogs/add_task_dialog.dart';

class CustomFloatingActionButton extends StatelessWidget {
  const CustomFloatingActionButton({super.key});

  @override
  Widget build(BuildContext context) => FloatingActionButton(
    backgroundColor: Colors.orange,
    child: const Icon(Icons.add, color: Colors.white),
    onPressed: () {
      showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: const AddTaskDialog(),
        ),
      );
    },
  );
}
