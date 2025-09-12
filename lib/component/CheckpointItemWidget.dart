import 'package:flutter/material.dart';
import 'package:my_dida/model/entity/Task.dart';
import 'package:my_dida/model/entity/CheckPoint.dart';

class CheckpointItemWidget extends StatefulWidget {
  final Task task;
  final int index;
  final CheckPoint checkpoint;
  final Future<void> Function(bool value) onToggle;
  final Future<void> Function(String value) onRename;
  final Future<void> Function() onRemove;

  const CheckpointItemWidget({
    super.key,
    required this.task,
    required this.index,
    required this.checkpoint,
    required this.onToggle,
    required this.onRename,
    required this.onRemove,
  });

  @override
  State<CheckpointItemWidget> createState() => _CheckpointItemWidgetState();
}

class _CheckpointItemWidgetState extends State<CheckpointItemWidget> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.checkpoint.name);
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Checkbox(
          value: widget.checkpoint.isDone,
          onChanged: (v) async {
            if (v == null) return;
            await widget.onToggle(v);
          },
        ),
        title: _isEditing
            ? TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                style: TextStyle(
                  color: widget.checkpoint.isDone ? Colors.black38 : null,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (value) async {
                  final trimmedValue = value.trim();
                  if (trimmedValue.isNotEmpty &&
                      trimmedValue != widget.checkpoint.name) {
                    await widget.onRename(trimmedValue);
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
                  widget.checkpoint.name,
                  style: TextStyle(
                    color: widget.checkpoint.isDone ? Colors.black38 : null,
                  ),
                ),
              ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () async {
            await widget.onRemove();
          },
        ),
      ),
    );
  }
}
