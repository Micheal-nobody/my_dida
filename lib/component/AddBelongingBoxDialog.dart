import 'package:flutter/material.dart';
import 'package:my_dida/config/logger.dart';
import 'package:provider/provider.dart';
import '../model/vo/BelongingBoxVO.dart';
import '../provider/BelongingBoxProvider.dart';

class AddBelongingBoxDialog extends StatefulWidget {
  final BelongingBoxVO? belongingBox; // null for create, not null for edit

  const AddBelongingBoxDialog({super.key, this.belongingBox});

  @override
  State<AddBelongingBoxDialog> createState() => _AddBelongingBoxDialogState();
}

class _AddBelongingBoxDialogState extends State<AddBelongingBoxDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Color _selectedColor = Colors.blue;
  bool _isLoading = false;

  // Predefined colors for selection
  final List<Color> _availableColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.belongingBox != null) {
      _nameController.text = widget.belongingBox!.name;
      _selectedColor = widget.belongingBox!.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveBelongingBox() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<BelongingBoxProvider>(
        context,
        listen: false,
      );

      // widget 指的是 当前组件，_AddBelongingBoxDialogState
      if (widget.belongingBox == null) {
        // Create new belonging box
        await provider.createBelongingBox(
          _nameController.text.trim(),
          _selectedColor,
        );
      } else {
        // Update existing belonging box
        final updatedBox = widget.belongingBox!;
        updatedBox.name = _nameController.text.trim();
        updatedBox.color = _selectedColor;
        await provider.updateBelongingBox(updatedBox);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.belongingBox != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Belonging Box' : 'Add Belonging Box'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            const Text('Select Color:', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableColors.map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: _selectedColor == color
                          ? Border.all(color: Colors.black, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveBelongingBox,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
