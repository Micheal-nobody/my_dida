import 'package:flutter/material.dart';

class InlineEditableTextField extends StatefulWidget {
  const InlineEditableTextField({
    required this.value,
    required this.onSubmit,
    super.key,
    this.onFieldSubmitted,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.style,
    this.decoration = const InputDecoration(border: InputBorder.none),
  });

  final String value;
  final Future<void> Function(String value) onSubmit;
  final void Function(String value)? onFieldSubmitted;
  final EdgeInsetsGeometry padding;
  final TextStyle? style;
  final InputDecoration decoration;

  @override
  State<InlineEditableTextField> createState() => _InlineEditableTextFieldState();
}

class _InlineEditableTextFieldState extends State<InlineEditableTextField> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant InlineEditableTextField oldWidget) {
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
    if (value.isNotEmpty && value != widget.value) {
      await widget.onSubmit(value);
    }
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
    child: TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: widget.decoration,
      style:
          widget.style ??
          const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
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
  );
}
