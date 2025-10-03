import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/colors.dart';
import '../../core/validators/form_validators.dart';
import '../../model/vo/BelongingBoxVO.dart';
import '../../provider/BelongingBoxProvider.dart';
import '../common/BaseFormDialog.dart';
import '../common/CommonWidgets.dart';

class AddBelongingBoxDialog extends BaseFormDialog {
  // null for create, not null for edit

  const AddBelongingBoxDialog({super.key, this.belongingBox});
  final BelongingBoxVO? belongingBox;

  @override
  State<AddBelongingBoxDialog> createState() => _AddBelongingBoxDialogState();
}

class _AddBelongingBoxDialogState
    extends BaseFormDialogState<AddBelongingBoxDialog> {
  final _nameController = TextEditingController();
  late final BelongingBoxVO? belongingBox;
  Color _selectedColor = Colors.blue;

  @override
  String get dialogTitle =>
      belongingBox == null ? 'Add Belonging Box' : 'Edit Belonging Box';

  @override
  String get confirmButtonText => belongingBox == null ? 'Add' : 'Update';

  @override
  void initState() {
    super.initState();
    belongingBox = widget.belongingBox;
    if (belongingBox != null) {
      _nameController.text = belongingBox!.name;
      _selectedColor = belongingBox!.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget buildFormContent(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      CommonWidgets.buildTextFormField(
        controller: _nameController,
        labelText: 'Name',
        validator: FormValidators.name,
      ),
      CommonWidgets.buildSpacing(),
      const Text('Select Color:', style: TextStyle(fontSize: 16)),
      CommonWidgets.buildSpacing(height: 10),
      CommonWidgets.buildColorSelector(
        colors: AppColors.selectorColors,
        selectedColor: _selectedColor,
        onColorSelected: (color) {
          setState(() {
            _selectedColor = color;
          });
        },
      ),
    ],
  );

  @override
  Future<void> onConfirm() async {
    final provider = Provider.of<BelongingBoxProvider>(context, listen: false);

    if (belongingBox == null) {
      // Create new belonging box
      await provider.createBelongingBox(
        _nameController.text.trim(),
        _selectedColor,
      );
      showSuccess('归属盒子创建成功！');
    } else {
      // Update existing belonging box
      final updatedBox = belongingBox!;
      updatedBox.name = _nameController.text.trim();
      updatedBox.color = _selectedColor;
      await provider.updateBelongingBox(updatedBox);
      showSuccess('归属盒子更新成功！');
    }
  }
}
