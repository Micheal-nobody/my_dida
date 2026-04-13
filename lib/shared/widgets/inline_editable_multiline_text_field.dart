import 'package:flutter/material.dart';

class InlineEditableMultilineTextField extends StatefulWidget {
  const InlineEditableMultilineTextField({
    required this.value,
    required this.onSubmit,
    super.key,
    this.onFieldSubmitted,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.minLines = 1,
    this.maxLines = 3,
    this.hintText = '添加备注...',
    this.decoration = const InputDecoration(
      hintText: '添加备注...',
      border: InputBorder.none,
    ),
    this.clearIcon = const Icon(Icons.clear, color: Colors.black38),
  });

  final String value;
  final Future<void> Function(String value) onSubmit;
  final void Function(String value)? onFieldSubmitted;
  final EdgeInsetsGeometry padding;
  final int minLines;
  final int maxLines;
  final String hintText;
  final InputDecoration decoration;
  final Widget clearIcon;

  @override
  State<InlineEditableMultilineTextField> createState() =>
      _InlineEditableMultilineTextFieldState();
}

class _InlineEditableMultilineTextFieldState
    extends State<InlineEditableMultilineTextField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _commit(_controller.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant InlineEditableMultilineTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _commit(String rawValue) async {
    final value = rawValue.trim();
    await widget.onSubmit(value);
    widget.onFieldSubmitted?.call(value);
    if (mounted) {
      setState(() {
        _isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: widget.padding,
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            decoration: widget.decoration.copyWith(hintText: widget.hintText),
            onTap: () {
              if (!_isEditing) {
                setState(() {
                  _isEditing = true;
                });
                _focusNode.requestFocus();
              }
            },
            onSubmitted: _commit,
            onEditingComplete: () async {
              await _commit(_controller.text);
            },
          ),
        ),
        if (widget.value.isNotEmpty)
          IconButton(
            icon: widget.clearIcon,
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
