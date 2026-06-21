import 'package:flutter/material.dart';
import 'package:my_dida/features/checklist/models/checklist_vo.dart';

class ChecklistSelector extends StatelessWidget {
  const ChecklistSelector({
    required this.items,
    required this.selectedValue,
    required this.hintText,
    required this.onChanged,
    this.underline = false,
    this.isDense = false,
    super.key,
  });

  final List<ChecklistVO> items;
  final ChecklistVO? selectedValue;
  final String hintText;
  final ValueChanged<ChecklistVO?> onChanged;
  final bool underline;
  final bool isDense;

  @override
  Widget build(BuildContext context) => DropdownButton<ChecklistVO>(
    value: selectedValue,
    hint: Text(hintText),
    isDense: isDense,
    underline: underline ? null : const SizedBox.shrink(),
    items: items
        .map(
          (value) => DropdownMenuItem<ChecklistVO>(
            value: value,
            child: Text(value.name),
          ),
        )
        .toList(),
    onChanged: onChanged,
  );
}
