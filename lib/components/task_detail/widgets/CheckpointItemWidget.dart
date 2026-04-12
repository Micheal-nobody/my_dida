import 'package:flutter/material.dart';
import 'package:my_dida/model/entity/CheckPoint.dart';
import 'package:my_dida/model/entity/Task.dart';
import 'package:my_dida/provider/task_provider.dart';
import 'package:provider/provider.dart';

class CheckpointItemWidget extends StatefulWidget {
  const CheckpointItemWidget({
    required this.task,
    required this.index,
    required this.checkpoint,
    super.key,
  });

  final Task task;
  final int index;
  final CheckPoint checkpoint;

  @override
  State<CheckpointItemWidget> createState() => _CheckpointItemWidgetState();
}

class _CheckpointItemWidgetState extends State<CheckpointItemWidget> {
  late final TextEditingController _controller;
  late final Task task;
  late final int index;
  late final CheckPoint checkpoint;
  final FocusNode _focusNode = FocusNode();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    task = widget.task;
    index = widget.index;
    checkpoint = widget.checkpoint;
    _controller = TextEditingController(text: checkpoint.name);
  }

  @override
  void didUpdateWidget(covariant CheckpointItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && _controller.text != widget.checkpoint.name) {
      _controller.text = widget.checkpoint.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.read<TaskProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Checkbox(
          value: checkpoint.isDone,
          onChanged: (v) async {
            if (v == null) return;
            await taskProvider.toggleCheckpoint(task, index, v);
          },
        ),
        title: _isEditing
            ? TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                style: TextStyle(
                  color: checkpoint.isDone ? Colors.black38 : null,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (value) async {
                  final trimmedValue = value.trim();
                  if (trimmedValue.isNotEmpty &&
                      trimmedValue != checkpoint.name) {
                    await taskProvider.renameCheckpoint(
                      task,
                      index,
                      trimmedValue,
                    );
                  }
                  if (mounted) {
                    setState(() {
                      _isEditing = false;
                    });
                  }
                },
                onEditingComplete: () {
                  setState(() {
                    _isEditing = false;
                  });
                },
              )
            : GestureDetector(
                onTap: () {
                  setState(() {
                    _isEditing = true;
                  });
                  _focusNode.requestFocus();
                },
                child: Text(
                  checkpoint.name,
                  style: TextStyle(
                    color: checkpoint.isDone ? Colors.black38 : null,
                  ),
                ),
              ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () async {
            await taskProvider.removeCheckpoint(task, index);
          },
        ),
      ),
    );
  }
}
