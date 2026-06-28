import 'package:flutter/material.dart';
import 'package:my_dida/core/utils/color_utils.dart';
import 'package:my_dida/core/validators/form_validators.dart';
import 'package:my_dida/features/checklist/models/checklist_vo.dart';
import 'package:my_dida/features/checklist/providers/checklist_provider.dart';
import 'package:my_dida/shared/widgets/base_form_dialog.dart';
import 'package:my_dida/shared/widgets/common_widgets.dart';
import 'package:provider/provider.dart';

class AddChecklistDialog extends BaseFormDialog {
  // null for create, not null for edit

  const AddChecklistDialog({super.key, this.checklist});

  final ChecklistVO? checklist;

  @override
  State<AddChecklistDialog> createState() => _AddChecklistDialogState();
}

class _AddChecklistDialogState extends BaseFormDialogState<AddChecklistDialog> {
  final _nameController = TextEditingController();
  late final ChecklistVO? checklist;
  Color _selectedColor = Colors.blue;

  @override
  String get dialogTitle => checklist == null ? '创建清单' : '编辑清单';

  @override
  void initState() {
    super.initState();
    checklist = widget.checklist;
    if (checklist != null) {
      _nameController.text = checklist!.name;
      _selectedColor = checklist!.color;
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
        labelText: '清单名',
        validator: FormValidators.name,
      ),
      CommonWidgets.buildSpacing(),
      const Text('选择颜色:', style: TextStyle(fontSize: 16)),
      CommonWidgets.buildSpacing(height: 10),
      CommonWidgets.buildColorSelector(
        colors: ColorUtils.selectorColors,
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

    if (checklist == null) {
      // Create new belonging box
      await provider.createChecklist(
        _nameController.text.trim(),
        _selectedColor,
      );
    } else {
      // Update existing belonging box
      final updatedBox = checklist!.copyWith(
        name: _nameController.text.trim(),
        color: _selectedColor,
      );
      await provider.updateChecklist(updatedBox);
    }
  }
}
