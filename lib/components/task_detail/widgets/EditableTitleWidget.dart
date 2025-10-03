import 'package:flutter/material.dart';
import 'package:my_dida/model/entity/Task.dart';

class EditableTitleWidget extends StatefulWidget {
  const EditableTitleWidget({
    required this.task,
    required this.onSubmit,
    super.key,
    this.onFieldSubmitted,
  });
  final Task task;
  final Future<void> Function(String value) onSubmit;
  final void Function(String value)? onFieldSubmitted;

  @override
  State<EditableTitleWidget> createState() => _EditableTitleWidgetState();
}

class _EditableTitleWidgetState extends State<EditableTitleWidget> {
  late final TextEditingController _controller;
  late final Task task;
  late final Future<void> Function(String value) onSubmit;
  late final void Function(String value)? onFieldSubmitted;
  final FocusNode _focusNode = FocusNode();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    task = widget.task;
    onSubmit = widget.onSubmit;
    onFieldSubmitted = widget.onFieldSubmitted;
    _controller = TextEditingController(text: task.name);
  }

  @override
  void didUpdateWidget(covariant EditableTitleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && _controller.text != widget.task.name) {
      _controller.text = widget.task.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: const InputDecoration(border: InputBorder.none),
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.orange,
        decoration: TextDecoration.underline,
      ),
      onTap: () {
        if (!_isEditing) {
          setState(() {
            _isEditing = true;
          });
          _focusNode.requestFocus();
        }
      },
      onSubmitted: (v) async {
        final value = v.trim();
        if (value.isNotEmpty && value != task.name) {
          await onSubmit(value);
        }
        onFieldSubmitted?.call(value);
        if (mounted) {
          setState(() {
            _isEditing = false;
          });
        }
      },
      onEditingComplete: () async {
        final value = _controller.text.trim();
        if (value.isNotEmpty && value != task.name) {
          await onSubmit(value);
          onFieldSubmitted?.call(value);
        }
        if (mounted) {
          setState(() {
            _isEditing = false;
          });
        }
      },
    ),
  );
}
