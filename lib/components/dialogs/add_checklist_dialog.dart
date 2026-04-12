import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/colors_constants.dart';
import '../../core/validators/form_validators.dart';
import '../../model/vo/checklist_vo.dart';
import '../../provider/checklist_provider.dart';
import '../common/base_form_dialog.dart';
import '../common/common_widgets.dart';

class AddChecklistDialog extends BaseFormDialog {
  // null for create, not null for edit

  const AddChecklistDialog({super.key, this.belongingBox});

  final ChecklistVO? belongingBox;

  @override
  State<AddChecklistDialog> createState() => _AddChecklistDialogState();
}

class _AddChecklistDialogState
    extends BaseFormDialogState<AddChecklistDialog> {
  final _nameController = TextEditingController();
  late final ChecklistVO? belongingBox;
  Color _selectedColor = Colors.blue;

  @override
  String get dialogTitle =>
      belongingBox == null ? '创建清单' : '编辑清单';

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
    final provider = Provider.of<ChecklistProvider>(context, listen: false);

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
