import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_dida/provider/calendar_page_provider.dart';
import 'package:my_dida/provider/checklist_provider.dart';

class CalendarVisibleRangeDialog extends StatefulWidget {
  const CalendarVisibleRangeDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const CalendarVisibleRangeDialog(),
    );
  }

  @override
  State<CalendarVisibleRangeDialog> createState() =>
      _CalendarVisibleRangeDialogState();
}

class _CalendarVisibleRangeDialogState
    extends State<CalendarVisibleRangeDialog> {
  late bool _isAllSelected;
  late List<int> _tempSelectedIds;

  @override
  void initState() {
    super.initState();
    final calendarProvider = Provider.of<CalendarPageProvider>(
      context,
      listen: false,
    );
    final checklistProvider = Provider.of<ChecklistProvider>(
      context,
      listen: false,
    );
    final allIds = checklistProvider.allCheckLists.map((c) => c.id).toList();

    if (calendarProvider.config.visibleMode == 'all') {
      _isAllSelected = true;
      _tempSelectedIds = List<int>.from(allIds);
    } else {
      _tempSelectedIds = List<int>.from(
        calendarProvider.config.visibleChecklistIds,
      );
      // 如果保存的 ID 刚好包含所有清单，则也视作全部选中
      _isAllSelected =
          allIds.isNotEmpty &&
          allIds.every((id) => _tempSelectedIds.contains(id));
    }
  }

  void _onAllChanged(bool? checked) {
    if (checked == null) return;
    final checklistProvider = Provider.of<ChecklistProvider>(
      context,
      listen: false,
    );
    setState(() {
      _isAllSelected = checked;
      if (checked) {
        _tempSelectedIds = checklistProvider.allCheckLists
            .map((c) => c.id)
            .toList();
      } else {
        _tempSelectedIds = [];
      }
    });
  }

  void _onChecklistChanged(int checklistId, bool? checked) {
    if (checked == null) return;
    final checklistProvider = Provider.of<ChecklistProvider>(
      context,
      listen: false,
    );
    final allIds = checklistProvider.allCheckLists.map((c) => c.id).toList();

    setState(() {
      if (checked) {
        if (!_tempSelectedIds.contains(checklistId)) {
          _tempSelectedIds.add(checklistId);
        }
        if (allIds.every((id) => _tempSelectedIds.contains(id))) {
          _isAllSelected = true;
        }
      } else {
        _tempSelectedIds.remove(checklistId);
        _isAllSelected = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final checklistProvider = Provider.of<ChecklistProvider>(context);
    final allChecklists = checklistProvider.allCheckLists;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                '显示范围',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: [
                CheckboxListTile(
                  title: const Text('全部'),
                  value: _isAllSelected,
                  onChanged: _onAllChanged,
                  activeColor: Colors.orange,
                  controlAffinity: ListTileControlAffinity.trailing,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ...allChecklists.map((checklist) {
                  final isSelected = _tempSelectedIds.contains(checklist.id);
                  return CheckboxListTile(
                    title: Text(checklist.name),
                    secondary: Icon(Icons.folder, color: checklist.color),
                    value: isSelected,
                    onChanged: (val) => _onChecklistChanged(checklist.id, val),
                    activeColor: Colors.orange,
                    controlAffinity: ListTileControlAffinity.trailing,
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '取消',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    final calendarProvider = Provider.of<CalendarPageProvider>(
                      context,
                      listen: false,
                    );
                    await calendarProvider.updateConfig(
                      visibleMode: _isAllSelected ? 'all' : 'custom',
                      visibleChecklistIds: _tempSelectedIds,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('确定', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
