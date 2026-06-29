import 'package:flutter/material.dart';
import 'package:my_dida/core/constants/app_constants.dart';
import 'package:my_dida/core/themes/theme_provider.dart';
import 'package:my_dida/features/checklist/models/checklist_vo.dart';
import 'package:my_dida/features/checklist/providers/checklist_provider.dart';
import 'package:my_dida/features/tasks/models/task.dart';
import 'package:my_dida/features/tasks/widgets/add_task/attribute_chips.dart';
import 'package:my_dida/features/tasks/widgets/add_task/checkpoint_list_view.dart';
import 'package:my_dida/features/tasks/widgets/add_task_bottom_sheet.dart';
import 'package:provider/provider.dart';

class AddTaskStandardContent extends StatelessWidget {
  const AddTaskStandardContent({super.key});

  void _ensureSelectedChecklist(BuildContext context, AddTaskBottomSheetState state, ChecklistProvider provider) {
    if (state.selectedChecklist != null) {
      final matchedChecklist = provider.allCheckLists
          .where((item) => item.id == state.selectedChecklist!.id)
          .firstOrNull;
      if (matchedChecklist != null) {
        state.setSelectedChecklist(matchedChecklist);
        return;
      }
    }
    state.setSelectedChecklist(_resolveInitialChecklist(provider));
  }

  ChecklistVO _resolveInitialChecklist(ChecklistProvider provider) {
    final preferredChecklist = provider.currentCheckList.isSmartList
        ? AppConstants.defaultCheckList
        : provider.currentCheckList;

    return provider.allCheckLists
            .where((item) => item.id == preferredChecklist.id)
            .firstOrNull ??
        preferredChecklist;
  }

  @override
  Widget build(BuildContext context) {
    final state = AddTaskStateScope.of(context);
    double totalDragY = 0;

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        totalDragY += details.primaryDelta ?? 0;
      },
      onVerticalDragEnd: (details) {
        if (totalDragY < -40 || (details.primaryVelocity ?? 0) < -300) {
          state.triggerExtendedDetail();
        }
        totalDragY = 0;
      },
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.48,
        ),
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16,
        ),
        decoration: BoxDecoration(
          color: context.theme.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PopupMenuButton<TaskPriority>(
                    initialValue: state.priority,
                    onSelected: state.setPriority,
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: TaskPriority.high,
                        child: Text('🔴 高优先级'),
                      ),
                      PopupMenuItem(
                        value: TaskPriority.medium,
                        child: Text('🟠 中优先级'),
                      ),
                      PopupMenuItem(
                        value: TaskPriority.low,
                        child: Text('🔵 低优先级'),
                      ),
                      PopupMenuItem(
                        value: TaskPriority.none,
                        child: Text('⚪ 无优先级'),
                      ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.flag,
                        size: 20,
                        color: state.priority == TaskPriority.none
                            ? context.theme.unselectedLabelColor
                            : state.priority.color,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.open_in_full,
                      size: 20,
                      color: context.theme.unselectedLabelColor,
                    ),
                    tooltip: '全屏编辑',
                    onPressed: state.triggerExtendedDetail,
                  ),
                ],
              ),
              TextField(
                controller: state.textController,
                autofocus: !state.hasInitPreset,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.theme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '准备做点什么？',
                  errorText: state.hasError ? '请输入任务名称！' : null,
                  errorStyle: TextStyle(color: context.theme.error),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onSubmitted: (value) => state.addTask(context),
                onChanged: (value) {
                  if (state.hasError && value.isNotEmpty) {
                    state.setHasError(false);
                  }
                },
              ),
              TextField(
                controller: state.descController,
                maxLines: null,
                style: TextStyle(fontSize: 14, color: context.theme.textSecondary),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                ),
              ),
              const SizedBox(height: 8),
              const AttributeChips(),
              if (state.checkpoints.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '检查点',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.theme.textPrimary,
                  ),
                ),
                const CheckpointListView(),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                            icon: Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: state.dateTimePickerValue.selectedDate != null
                                  ? context.theme.primary
                                  : context.theme.unselectedLabelColor,
                            ),
                            label: Text(
                              state.getDateDisplayText(),
                              style: TextStyle(
                                color: state.dateTimePickerValue.selectedDate != null
                                    ? context.theme.primary
                                    : context.theme.unselectedLabelColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onPressed: () => state.showDateTimePicker(context),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: Icon(
                              Icons.label_outline,
                              size: 20,
                              color: state.tags.isNotEmpty
                                  ? context.theme.primary
                                  : context.theme.unselectedLabelColor,
                            ),
                            onPressed: state.editTags,
                          ),
                          if (state.parentTask == null)
                            Consumer<ChecklistProvider>(
                              builder: (context, provider, child) {
                                _ensureSelectedChecklist(context, state, provider);
                                return PopupMenuButton<ChecklistVO>(
                                  initialValue: state.selectedChecklist,
                                  onSelected: state.setSelectedChecklist,
                                  itemBuilder: (context) => provider
                                      .allCheckLists
                                      .map(
                                        (checklist) =>
                                            PopupMenuItem<ChecklistVO>(
                                              value: checklist,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.folder,
                                                    color: checklist.color,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(checklist.name),
                                                ],
                                              ),
                                            ),
                                      )
                                      .toList(),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.folder_open,
                                          size: 20,
                                          color: state.selectedChecklist != null
                                              ? context.theme.primary
                                              : context.theme.unselectedLabelColor,
                                        ),
                                        if (state.selectedChecklist != null) ...[
                                          const SizedBox(width: 4),
                                          Text(
                                            state.selectedChecklist!.name,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: context.theme.primary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.send,
                          color: context.theme.primary,
                          size: 20,
                        ),
                        onPressed: () => state.addTask(context),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
