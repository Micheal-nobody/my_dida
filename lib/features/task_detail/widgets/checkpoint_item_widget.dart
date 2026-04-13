import 'package:flutter/material.dart';
import 'package:my_dida/model/entity/check_point.dart';
import 'package:my_dida/model/entity/task.dart';
import 'package:my_dida/provider/task_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';

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
  final FocusNode _focusNode = FocusNode();
  Timer? _renameDebounce;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.checkpoint.name);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _flushRename();
      }
    });
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
    _renameDebounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scheduleRename() {
    _renameDebounce?.cancel();
    _renameDebounce = Timer(const Duration(milliseconds: 400), _flushRename);
  }

  Future<void> _flushRename() async {
    _renameDebounce?.cancel();
    final trimmedValue = _controller.text.trim();
    if (trimmedValue.isEmpty || trimmedValue == widget.checkpoint.name) {
      if (mounted) {
        setState(() {
          _isEditing = false;
        });
      }
      return;
    }

    await context.read<TaskProvider>().renameCheckpoint(
      widget.task,
      widget.index,
      trimmedValue,
    );
    if (mounted) {
      setState(() {
        _isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.read<TaskProvider>();
    final checkpoint = widget.checkpoint;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Checkbox(
          value: checkpoint.isDone,
          onChanged: (v) async {
            if (v == null) return;
            await taskProvider.toggleCheckpoint(widget.task, widget.index, v);
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
                  await _flushRename();
                },
                onChanged: (_) {
                  _scheduleRename();
                },
                onEditingComplete: () async {
                  await _flushRename();
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
            await taskProvider.removeCheckpoint(widget.task, widget.index);
          },
        ),
      ),
    );
  }
}
