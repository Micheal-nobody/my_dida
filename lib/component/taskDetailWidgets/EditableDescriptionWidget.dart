import 'package:flutter/material.dart';
import 'package:my_dida/model/entity/Task.dart';

class EditableDescriptionWidget extends StatefulWidget {
  final Task task;
  final Future<void> Function(String value) onSubmit;
  final void Function(String value)? onFieldSubmitted;

  const EditableDescriptionWidget({
    super.key,
    required this.task,
    required this.onSubmit,
    this.onFieldSubmitted,
  });

  @override
  State<EditableDescriptionWidget> createState() =>
      _EditableDescriptionWidgetState();
}

class _EditableDescriptionWidgetState extends State<EditableDescriptionWidget> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.task.description);
    _focusNode.addListener(() {
      // 焦点丢失时提交（即使为空也提交），保证内容更新
      if (!_focusNode.hasFocus && _isEditing) {
        final value = _controller.text.trim();
        widget.onSubmit(value).then((_) {
          if (!mounted) return;
          setState(() {
            _isEditing = false;
          });
        });
        widget.onFieldSubmitted?.call(value);
      }
    });
  }

  @override
  void didUpdateWidget(covariant EditableDescriptionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && _controller.text != widget.task.description) {
      _controller.text = widget.task.description;
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '添加备注...',
                border: InputBorder.none,
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
                await widget.onSubmit(value);
                widget.onFieldSubmitted?.call(value);
                if (mounted) {
                  setState(() {
                    _isEditing = false;
                  });
                }
              },
              onEditingComplete: () async {
                final value = _controller.text.trim();
                await widget.onSubmit(value);
                widget.onFieldSubmitted?.call(value);
                if (mounted) {
                  setState(() {
                    _isEditing = false;
                  });
                }
              },
            ),
          ),

          // 清空按钮
          if (widget.task.description.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.black38),
              onPressed: () async {
                await widget.onSubmit('');
                if (mounted) {
                  setState(() {
                    _controller.clear();
                  });
                }
              },
            ),
        ],
      ),
    );
  }
}
